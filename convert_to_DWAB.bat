@echo off
setlocal enabledelayedexpansion

:: === CONFIG ===
set "CACHE_FILE=%TEMP%\oiiotool_path.cache"
set "OUTPUT_FOLDER=DWAB_Converted"
set "INSTALL_SCRIPT=https://github.com/freeway80/OpenImageIO-3.2.0-Built/blob/main/OIIO_Install.bat?raw=true"

:: === 1. Check for EXR files in current folder ===
set "EXR_FOUND=0"
for %%F in (*.exr) do (
    set "EXR_FOUND=1"
    goto :FOUND_EXR
)
:FOUND_EXR
if "%EXR_FOUND%"=="0" (
    echo No EXR files found in the current folder.
    pause
    exit /b
)

:: === 2. Find oiiotool.exe ===
set "OIIO_TOOL="

:: 2a. Check C:\OpenImageIO 
if exist "C:\OpenImageIO\oiiotool.exe" (
    set "OIIO_TOOL=C:\OpenImageIO\oiiotool.exe"
    goto :FOUND_TOOL
)

:: 2b. Search current folder + subfolders
for /d /r %%D in (*) do (
    if exist "%%D\oiiotool.exe" (
        set "OIIO_TOOL=%%D\oiiotool.exe"
        goto :FOUND_TOOL
    )
)

:: 2c. Check cached path
if exist "%CACHE_FILE%" (
    set /p OIIO_TOOL=<"%CACHE_FILE%"
    if exist "!OIIO_TOOL!" goto :FOUND_TOOL
    set "OIIO_TOOL="
)

:: 2d. Not found → offer installation
set /p INSTALL="oiiotool.exe not found. Install OpenImageIO now? (y/n) "
if /i "%INSTALL%"=="y" (
    echo Downloading and running installer...
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
    echo oiiotool.exe is required for EXR conversion. Aborting.
    pause
    exit /b
)

:FOUND_TOOL
echo Found oiiotool at: !OIIO_TOOL!

:: === 3. Prepare output folder ===
if not exist "%OUTPUT_FOLDER%" mkdir "%OUTPUT_FOLDER%"

:: Check if output folder has EXR files
set "EXR_EXIST=0"
for %%F in ("%OUTPUT_FOLDER%\*.exr") do (
    set "EXR_EXIST=1"
    goto :EXR_CHECK_DONE
)
:EXR_CHECK_DONE
if "%EXR_EXIST%"=="1" (
    set /p OVERWRITE="EXR files exist in %OUTPUT_FOLDER%. Overwrite? (y/n) "
    if /i not "!OVERWRITE!"=="y" (
        echo Aborting.
        exit /b
    )
)


:: === 4. Convert EXRs ===
for %%F in (*.exr) do (
    echo Converting %%F ...
    "!OIIO_TOOL!" "%%F" --compression dwab --tile 256 256 -o "%OUTPUT_FOLDER%\%%F"
)

:: === 5. Cache path AFTER successful conversion ===
echo !OIIO_TOOL! > "%CACHE_FILE%"
echo Cached oiiotool path: !OIIO_TOOL!

echo Finished converting EXR images to Tiled with DWAB compression. Files are in %OUTPUT_FOLDER%.
pause
