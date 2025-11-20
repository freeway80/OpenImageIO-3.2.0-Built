@echo off
setlocal

REM ---------------------------
REM Variables
REM ---------------------------
set INSTALL_DIR=C:\OpenImageIO
set ZIP_URL=https://github.com/freeway80/OpenImageIO-3.2.0-Built/blob/main/OpenImageIO.zip?raw=true
set TEMP_ZIP=%TEMP%\OpenImageIO.zip

REM ---------------------------
REM Parse arguments
REM ---------------------------
set SILENT_INSTALL=0
if /I "%1"=="-y" set SILENT_INSTALL=1

REM ---------------------------
REM Check if oiiotool.exe already exists
REM ---------------------------
if exist "%INSTALL_DIR%\bin\oiiotool.exe" (
    echo oiiotool.exe already installed in %INSTALL_DIR%
    goto :EOF
)

REM ---------------------------
REM Prompt user if not silent
REM ---------------------------
if "%SILENT_INSTALL%"=="0" (
    set /p USER_CHOICE=oiiotool not found. Install OpenImageIO in %INSTALL_DIR%? [y/N]: 
    if /I not "%USER_CHOICE%"=="y" (
        echo Installation canceled.
        goto :EOF
    )
)

REM ---------------------------
REM Create install folder
REM ---------------------------
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

REM ---------------------------
REM Download zip
REM ---------------------------
echo Downloading OpenImageIO package...
powershell -Command "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%TEMP_ZIP%'"

REM ---------------------------
REM Extract zip
REM ---------------------------
echo Extracting package...
powershell -Command "Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%INSTALL_DIR%' -Force"

REM ---------------------------
REM Cleanup
REM ---------------------------
del "%TEMP_ZIP%"

echo Installation complete. oiiotool.exe should now be in %INSTALL_DIR%\bin
pause
