@echo off
for /d %%i in (.*) do (
    if not %%i == .git (
        mklink /d %USERPROFILE%\%%i %USERPROFILE%\dotfiles\%%i
    )
)
for %%i in (.*) do (
    mklink %USERPROFILE%\%%i %USERPROFILE%\dotfiles\%%i
)
