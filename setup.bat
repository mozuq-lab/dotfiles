@echo off
for /d %%i in (.*) do (
	if not %%i == .git if not %%i == .DS_Store (
		mklink /d %USERPROFILE%\%%i %USERPROFILE%\dotfiles\%%i
	)
)
for %%i in (.*) do (
	if not %%i == .desktop (
		mklink %USERPROFILE%\%%i %USERPROFILE%\dotfiles\%%i
	)
)

mkdir %USERPROFILE%\.vim\backup
mkdir %USERPROFILE%\.vim\swap
mkdir %USERPROFILE%\.vim\undo
