@echo off
setlocal enabledelayedexpansion

:: Set the directory where the .zip files are located
set "dir=\\RECALBOX\share\roms\pcenginecd"

:: Set the new extension
set "newext=.cue"

:: Change to the specified directory
pushd "%dir%"

:: Loop through all .zip files in the directory
for %%f in (*.zip) do (
    :: Get the base name of the file
    set "basename=%%~nf"
    :: Rename the file with the new extension
    ren "%%f" "!basename!%newext%"
)

:: Return to the original directory
popd

echo All .zip files have been converted to %newext% extension.
pause
