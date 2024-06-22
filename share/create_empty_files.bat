@echo off
setlocal enabledelayedexpansion

:: Source directory
set "sourceDir=\\RECALBOX\share\rom\Redump/Arcade - Sega - Naomi 2"

:: Destination directory
set "destDir=\\RECALBOX\share\roms\naomi2"

:: Ensure the destination directory exists
if not exist "%destDir%" (
    mkdir "%destDir%"
)

:: Loop through each file in the source directory
for %%F in ("%sourceDir%\*") do (
    set "fileName=%%~nxF"
    echo Creating empty file: "%destDir%\!fileName!"
    type nul > "%destDir%\!fileName!"
)

echo All files created successfully.
pause
