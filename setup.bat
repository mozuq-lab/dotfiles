@echo off
rem 要管理者権限または開発者モード（mklink のため）
setlocal
SET DOTFILES=%USERPROFILE%\dotfiles

rem ドットファイルのリンク（ディレクトリ）
for /d %%i in (.*) do (
    if not %%i == .git (
        mklink /d %USERPROFILE%\%%i %DOTFILES%\%%i
    )
)
rem ドットファイルのリンク（ファイル）
for %%i in (.*) do (
    mklink %USERPROFILE%\%%i %DOTFILES%\%%i
)

rem OS別 gitconfig（.gitconfig の include から参照される）
if exist %USERPROFILE%\.gitconfig.os del %USERPROFILE%\.gitconfig.os
mklink %USERPROFILE%\.gitconfig.os %DOTFILES%\gitconfig.win

rem NeoVim
SET NVIM_DIR=%USERPROFILE%\AppData\Local\nvim
if not exist %NVIM_DIR% mkdir %NVIM_DIR%
if exist %NVIM_DIR%\init.vim del %NVIM_DIR%\init.vim
mklink %NVIM_DIR%\init.vim %DOTFILES%\.vimrc
if exist %NVIM_DIR%\ginit.vim del %NVIM_DIR%\ginit.vim
mklink %NVIM_DIR%\ginit.vim %DOTFILES%\.gvimrc

rem Claude Code（状態ファイルが同居するためディレクトリ丸ごとではなくファイル単位でリンク）
rem 注意: claude\settings.json 内の dart-lsp マーケットプレイスのパスは
rem       Mac の絶対パスなので、Windowsで使う場合は手動で調整すること
if not exist %USERPROFILE%\.claude\local-plugins mkdir %USERPROFILE%\.claude\local-plugins
if exist %USERPROFILE%\.claude\settings.json del %USERPROFILE%\.claude\settings.json
mklink %USERPROFILE%\.claude\settings.json %DOTFILES%\claude\settings.json
if exist %USERPROFILE%\.claude\statusline-command.sh del %USERPROFILE%\.claude\statusline-command.sh
mklink %USERPROFILE%\.claude\statusline-command.sh %DOTFILES%\claude\statusline-command.sh
if exist %USERPROFILE%\.claude\local-plugins\dart-lsp rmdir %USERPROFILE%\.claude\local-plugins\dart-lsp
mklink /d %USERPROFILE%\.claude\local-plugins\dart-lsp %DOTFILES%\claude\local-plugins\dart-lsp

rem Codex
if not exist %USERPROFILE%\.codex\rules mkdir %USERPROFILE%\.codex\rules
if exist %USERPROFILE%\.codex\hooks.json del %USERPROFILE%\.codex\hooks.json
mklink %USERPROFILE%\.codex\hooks.json %DOTFILES%\codex\hooks.json
if exist %USERPROFILE%\.codex\rules\default.rules del %USERPROFILE%\.codex\rules\default.rules
mklink %USERPROFILE%\.codex\rules\default.rules %DOTFILES%\codex\rules\default.rules

endlocal
