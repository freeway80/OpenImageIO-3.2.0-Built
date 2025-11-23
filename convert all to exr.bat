@echo off
setlocal enabledelayedexpansion

:: === CONFIG ===
set "CACHE_FILE=%TEMP%\oiiotool_path.cache"
set "OUTPUT_FOLDER=Tiled_EXR_Converted"
set "INSTALL_SCRIPT=https://github.com/freeway80/OpenImageIO-3.2.0-Built/blob/main/OIIO_Install.bat?raw=true"

:: === 1. Scan for input files ===

set "HAS_EXR=0"
set "HAS_OTHER=0"

:: EXR
for %%F in (*.exr) do (
    set "HAS_EXR=1"
    goto :FOUND_EXR_SCAN
)
:FOUND_EXR_SCAN

:: Other formats: PNG, JPG/JPEG, TIFF/TIF
for %%F in (*.png *.jpg *.jpeg *.tif *.tiff) do (
    set "HAS_OTHER=1"
    goto :FOUND_OTHER_SCAN
)
:FOUND_OTHER_SCAN

:: Nothing found
if "%HAS_EXR%"=="0" if "%HAS_OTHER%"=="0" (
    echo No EXR or image files found in the current folder.
    pause
    exit /b
)

:: === 2. Find oiiotool.exe ===
set "OIIO_TOOL="

:: 2a. Check C:\OpenImageIO first (priority raised)
if exist "C:\OpenImageIO\oiiotool.exe" (
    set "OIIO_TOOL=C:\OpenImageIO\oiiotool.exe"
    goto :FOUND_TOOL
)

:: 2b. Search current folder and subfolders
for /d /r %%D in (*) do (
    if exist "%%D\oiiotool.exe" (
        set "OIIO_TOOL=%%D\oiiotool.exe"
        goto :FOUND_TOOL
    )
)

:: 2c. Last: read cache
if exist "%CACHE_FILE%" (
    set /p OIIO_TOOL=<"%CACHE_FILE%"
    if exist "!OIIO_TOOL!" goto :FOUND_TOOL
    set "OIIO_TOOL="
)

:: 2d. Not found — install
set /p INSTALL="oiiotool.exe not found. Download and install OpenImageIO now? (y/n) "
if /i "%INSTALL%"=="y" (
    echo Downloading...
    powershell -Command "Invoke-WebRequest -Uri '%INSTALL_SCRIPT%' -OutFile '%TEMP%\OIIO_Install.bat'"
    call "%TEMP%\OIIO_Install.bat" -y

    if exist "C:\OpenImageIO\oiiotool.exe" (
        set "OIIO_TOOL=C:\OpenImageIO\oiiotool.exe"
    ) else (
        echo Installation failed or oiiotool.exe not found.
        pause
        exit /b
    )
) else (
    echo oiiotool.exe is required for conversion. Aborting.
    pause
    exit /b
)

:FOUND_TOOL
echo Found oiiotool at: !OIIO_TOOL!

:: === 3. Create / verify output folder ===
if not exist "%OUTPUT_FOLDER%" mkdir "%OUTPUT_FOLDER%"

:: Ask overwrite only if EXRs OR converted files may be overwritten
dir /b "%OUTPUT_FOLDER%\*.exr" >nul 2>&1
if not errorlevel 1 (
    set /p OVERWRITE="EXRs already exist in %OUTPUT_FOLDER%. Overwrite? (y/n) "
    if /i not "!OVERWRITE!"=="y" (
        echo Aborting.
        exit /b
    )
)

:: === 4. If other formats exist, ask user ===
set "DO_OTHER=0"
if "%HAS_OTHER%"=="1" (
    set /p DO_OTHER="Convert PNG/JPG/TIFF files to tiled EXR? (y/n) "
    if /i "!DO_OTHER!"=="y" set "DO_OTHER=1"
)

echo.
echo ====================================
echo Beginning conversion...
echo ====================================

:: === 5. Convert EXRs (always if present) ===
if "%HAS_EXR%"=="1" (
    for %%F in (*.exr) do (
        echo Converting EXR: %%F
        "!OIIO_TOOL!" "%%F" --tile 256 256 --compression dwab -o "%OUTPUT_FOLDER%\%%F"
    )
)

:: === 6. Convert other formats (only if user agreed) ===
if "%DO_OTHER%"=="1" (
    for %%F in (*.png *.jpg *.jpeg *.tif *.tiff) do (
        echo Converting image: %%F
        set "NAME=%%~nF"
        "!OIIO_TOOL!" "%%F" --colorconvert sRGB linear --tile 256 256 --compression dwab -o "%OUTPUT_FOLDER%\!NAME!.exr"
    )
)

echo.
echo Conversion finished.
echo Saving cache...

:: Cache only AFTER successful run
echo !OIIO_TOOL! > "%CACHE_FILE%"

echo Done.
pause
