@ECHO OFF
DEICE
IF ERRORLEVEL == 1 GOTO fin
doom1_2r.EXE
if errorlevel == 1 goto error
DEL doom1_2r.EXE
goto end
:ERROR
echo  !!! Error decompressing DOOM v1.2!
goto fin
:END
setup
:FIN
