@echo off
for /d %%i in (.*) do (
    if not %%i == .git (
        mklink /d %USERPROFILE%\%%i %USERPROFILE%\dotfiles\%%i
    )
)
for %%i in (.*) do (
    mklink %USERPROFILE%\%%i %USERPROFILE%\dotfiles\%%i
)

rem NeoVim
SET COPY_FROM=%USERPROFILE%\dotfiles
SET COPY_TO=%USERPROFILE%\AppData\Local\nvim
if not exist %COPY_TO% (
    mkdir %COPY_TO%
)
mklink %COPY_TO%\init.vim %COPY_FROM%\.vimrc
mklink %COPY_TO%\ginit.vim %COPY_FROM%\.gvimrc
