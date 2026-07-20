param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigPath,

    [Parameter(Mandatory = $true)]
    [string]$FragmentPath
)

$ErrorActionPreference = "Stop"
$profileName = "dotfiles-workspace"
$beginMarker = "# >>> dotfiles managed Codex permissions >>>"
$endMarker = "# <<< dotfiles managed Codex permissions <<<"

if (-not (Test-Path -LiteralPath $FragmentPath -PathType Leaf)) {
    throw "Codex permissions fragment not found: $FragmentPath"
}

$configDirectory = Split-Path -Parent $ConfigPath
if (-not (Test-Path -LiteralPath $configDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $configDirectory -Force | Out-Null
}

function Resolve-ConfigWritePath {
    param([string]$Path)

    $currentPath = [System.IO.Path]::GetFullPath($Path)
    for ($linkCount = 0; $linkCount -lt 40; $linkCount++) {
        $item = Get-Item -LiteralPath $currentPath -Force -ErrorAction SilentlyContinue
        if ($null -eq $item) {
            return $currentPath
        }

        $linkType = [string]$item.LinkType
        if ($linkType -notin @("SymbolicLink", "Junction")) {
            return $currentPath
        }

        $linkTarget = @($item.Target)[0]
        if ([string]::IsNullOrWhiteSpace($linkTarget)) {
            throw "Could not resolve Codex config symbolic link: $currentPath"
        }

        if ([System.IO.Path]::IsPathRooted($linkTarget)) {
            $currentPath = [System.IO.Path]::GetFullPath($linkTarget)
        }
        else {
            $currentPath = [System.IO.Path]::GetFullPath(
                (Join-Path (Split-Path -Parent $currentPath) $linkTarget)
            )
        }
    }

    throw "Too many symbolic links while resolving: $Path"
}

function Get-ConfigFingerprint {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return "missing"
    }

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $stream = $null
    try {
        $shareMode = [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete
        $stream = [System.IO.File]::Open(
            $Path,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            $shareMode
        )
        $hash = $sha256.ComputeHash($stream)
        return [System.BitConverter]::ToString($hash).Replace("-", "")
    }
    finally {
        if ($null -ne $stream) {
            $stream.Dispose()
        }
        $sha256.Dispose()
    }
}

function Test-GeneratedToml {
    param(
        [string]$Path,
        [string]$TomlContent
    )

    $tomlConverter = Get-Command ConvertFrom-Toml -ErrorAction SilentlyContinue
    if ($null -ne $tomlConverter) {
        $TomlContent | ConvertFrom-Toml | Out-Null
        return
    }

    foreach ($pythonName in @("python3.14", "python3.13", "python3.12", "python3.11", "python3", "python")) {
        $pythonCommand = Get-Command $pythonName -ErrorAction SilentlyContinue
        if ($null -eq $pythonCommand) {
            continue
        }
        $pythonPath = $pythonCommand.Source

        & $pythonPath -c "import tomllib" 2>$null
        if ($LASTEXITCODE -eq 0) {
            & $pythonPath -c 'import pathlib, sys, tomllib; tomllib.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))' $Path
            if ($LASTEXITCODE -ne 0) {
                throw "Generated Codex config is not valid TOML."
            }
            return
        }

        & $pythonPath -c "import tomli" 2>$null
        if ($LASTEXITCODE -eq 0) {
            & $pythonPath -c 'import pathlib, sys, tomli; tomli.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))' $Path
            if ($LASTEXITCODE -ne 0) {
                throw "Generated Codex config is not valid TOML."
            }
            return
        }
    }

    Write-Warning "No TOML parser was available; syntax validation was skipped."
}

$writePath = Resolve-ConfigWritePath $ConfigPath
$writeDirectory = Split-Path -Parent $writePath
if (-not (Test-Path -LiteralPath $writeDirectory -PathType Container)) {
    throw "Codex config target directory does not exist: $writeDirectory"
}

$lockPath = Join-Path $configDirectory ".config.toml.dotfiles.lock"
$lockPidPath = Join-Path $lockPath "pid"

function New-ConfigLock {
    try {
        New-Item -ItemType Directory -Path $lockPath -ErrorAction Stop | Out-Null
        [System.IO.File]::WriteAllText($lockPidPath, [string]$PID)
        return
    }
    catch {
        $lockPid = $null
        if (Test-Path -LiteralPath $lockPidPath -PathType Leaf) {
            $lockPidText = [System.IO.File]::ReadAllText($lockPidPath).Trim()
            $parsedPid = 0
            if ([int]::TryParse($lockPidText, [ref]$parsedPid)) {
                $lockPid = $parsedPid
            }
        }

        $lockProcess = $null
        if ($null -ne $lockPid) {
            $lockProcess = Get-Process -Id $lockPid -ErrorAction SilentlyContinue
        }

        if ($null -ne $lockPid -and $null -eq $lockProcess) {
            Remove-Item -LiteralPath $lockPidPath -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue
            try {
                New-Item -ItemType Directory -Path $lockPath -ErrorAction Stop | Out-Null
                [System.IO.File]::WriteAllText($lockPidPath, [string]$PID)
                return
            }
            catch {
                # Another setup process may have acquired the lock first.
            }
        }

        throw "Another Codex config update may be running: $lockPath. If no setup process is running, remove this stale lock directory."
    }
}

New-ConfigLock

$tempPath = $null
$backupTempPath = $null
try {
    $originalFingerprint = Get-ConfigFingerprint $ConfigPath
    $content = ""
    if (Test-Path -LiteralPath $ConfigPath -PathType Leaf) {
        $content = [System.IO.File]::ReadAllText($ConfigPath)
    }

    $keptLines = [System.Collections.Generic.List[string]]::new()
    $inManagedBlock = $false
    $seenTable = $false
    $tableHeaderPattern = '^\s*\[\[?[^,]+\]\]?\s*(?:#.*)?$'

    foreach ($line in [System.Text.RegularExpressions.Regex]::Split($content, "\r?\n")) {
        if ($line -eq $beginMarker) {
            if ($inManagedBlock) {
                throw "Nested Codex permissions marker in config.toml"
            }
            $inManagedBlock = $true
            continue
        }

        if ($line -eq $endMarker) {
            if (-not $inManagedBlock) {
                throw "Unexpected Codex permissions end marker in config.toml"
            }
            $inManagedBlock = $false
            continue
        }

        if ($inManagedBlock) {
            continue
        }

        $trimmedLine = $line.TrimStart()
        if ($trimmedLine.StartsWith("#")) {
            $keptLines.Add($line)
            continue
        }

        $assignmentIndex = $trimmedLine.IndexOf("=")
        if ($assignmentIndex -ge 0) {
            $keyPart = $trimmedLine.Substring(0, $assignmentIndex)
            $valuePart = $trimmedLine.Substring($assignmentIndex + 1)
            $normalizedKey = $keyPart.Replace(" ", "").Replace("`t", "").Replace('"', "").Replace("'", "")

            if (-not $seenTable -and $normalizedKey -eq "default_permissions") {
                continue
            }
            if ($normalizedKey -match '(^|\.)(sandbox_mode|sandbox_workspace_write)($|\.)') {
                throw "Cannot install Codex permission profile while legacy sandbox settings are present. Remove sandbox_mode and sandbox_workspace_write from config.toml first."
            }
            if ($normalizedKey.Contains($profileName) -or
                ($normalizedKey -eq "permissions" -and $valuePart.Contains($profileName))) {
                throw "A non-managed permissions.$profileName profile already exists in config.toml."
            }
        }
        elseif ($trimmedLine.StartsWith("[")) {
            if ($trimmedLine -match '(?:sandbox_mode|sandbox_workspace_write)') {
                throw "Cannot install Codex permission profile while legacy sandbox settings are present. Remove sandbox_mode and sandbox_workspace_write from config.toml first."
            }
            if ($trimmedLine.Contains($profileName)) {
                throw "A non-managed permissions.$profileName profile already exists in config.toml."
            }
            if ($line -match $tableHeaderPattern) {
                $seenTable = $true
            }
        }

        $keptLines.Add($line)
    }

    if ($inManagedBlock) {
        throw "Unclosed Codex permissions marker in config.toml"
    }

    $lineEndings = [char[]]"`r`n"
    $existingConfig = ($keptLines -join "`n").Trim($lineEndings)
    $fragment = [System.IO.File]::ReadAllText($FragmentPath).Trim($lineEndings)

    $result = "default_permissions = `"$profileName`"`n"
    if ($existingConfig.Length -gt 0) {
        $result += "`n$existingConfig`n"
    }
    $result += "`n$beginMarker`n$fragment`n$endMarker`n"

    $tempPath = Join-Path $writeDirectory (".config.toml.{0}.tmp" -f [System.Guid]::NewGuid().ToString("N"))
    $utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($tempPath, $result, $utf8WithoutBom)
    Test-GeneratedToml -Path $tempPath -TomlContent $result

    $currentFingerprint = Get-ConfigFingerprint $ConfigPath
    if ($currentFingerprint -ne $originalFingerprint) {
        throw "Codex config changed during setup; leaving the newer file untouched."
    }

    if ($originalFingerprint -ne "missing") {
        $backupPath = "$ConfigPath.dotfiles-backup"
        $backupTempPath = Join-Path $configDirectory (".config.toml.{0}.backup" -f [System.Guid]::NewGuid().ToString("N"))
        [System.IO.File]::WriteAllBytes($backupTempPath, [System.IO.File]::ReadAllBytes($ConfigPath))
    }

    $currentFingerprint = Get-ConfigFingerprint $ConfigPath
    if ($currentFingerprint -ne $originalFingerprint) {
        throw "Codex config changed while its backup was being created; leaving the newer file untouched."
    }

    if ($null -ne $backupTempPath) {
        if (Test-Path -LiteralPath $backupPath -PathType Leaf) {
            [System.IO.File]::Replace($backupTempPath, $backupPath, $null)
        }
        else {
            [System.IO.File]::Move($backupTempPath, $backupPath)
        }
        $backupTempPath = $null
    }

    $currentFingerprint = Get-ConfigFingerprint $ConfigPath
    if ($currentFingerprint -ne $originalFingerprint) {
        throw "Codex config changed immediately before replacement; leaving the newer file untouched."
    }

    if (Test-Path -LiteralPath $writePath -PathType Leaf) {
        [System.IO.File]::Replace($tempPath, $writePath, $null)
    }
    else {
        [System.IO.File]::Move($tempPath, $writePath)
    }
    $tempPath = $null

    Write-Host "Installed Codex permission profile: $profileName"
}
finally {
    if ($null -ne $tempPath -and (Test-Path -LiteralPath $tempPath)) {
        Remove-Item -LiteralPath $tempPath -Force
    }
    if ($null -ne $backupTempPath -and (Test-Path -LiteralPath $backupTempPath)) {
        Remove-Item -LiteralPath $backupTempPath -Force
    }
    if (Test-Path -LiteralPath $lockPidPath -PathType Leaf) {
        Remove-Item -LiteralPath $lockPidPath -Force
    }
    if (Test-Path -LiteralPath $lockPath -PathType Container) {
        Remove-Item -LiteralPath $lockPath -Force
    }
}
