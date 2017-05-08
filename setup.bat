@echo off
for /d %%i in (.*) do (
    if not %%i == .git (
        mklink /d %USERPROFILE%\%%i %USERPROFILE%\dotfiles\%%i
    )
)
for %%i in (.*) do (
    if not %%i == .bashrc (
        mklink %USERPROFILE%\%%i %USERPROFILE%\dotfiles\%%i
    )
)

mkdir %USERPROFILE%\.vim\backup
mkdir %USERPROFILE%\.vim\swap
mkdir %USERPROFILE%\.vim\undo
