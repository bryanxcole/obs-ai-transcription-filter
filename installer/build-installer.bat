@echo off
setlocal

echo Building OBS AI Transcription Filter Installer...

REM Check if WiX is installed
where candle.exe >nul 2>nul
if errorlevel 1 (
    echo ERROR: WiX Toolset not found in PATH
    echo Please install WiX Toolset v3.11 or later from:
    echo https://github.com/wixtoolset/wix3/releases
    pause
    exit /b 1
)

REM Set variables
set "PROJECT_DIR=%~dp0\.."
set "INSTALLER_DIR=%~dp0"
set "BUILD_DIR=%PROJECT_DIR%\build"
set "OUTPUT_DIR=%INSTALLER_DIR%\output"

REM Create output directory
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Check if plugin DLL exists
if not exist "%BUILD_DIR%\Release\obs-ai-transcription-filter.dll" (
    echo ERROR: Plugin DLL not found at %BUILD_DIR%\Release\obs-ai-transcription-filter.dll
    echo Please build the plugin first using CMake
    pause
    exit /b 1
)

echo Compiling WiX source...
candle.exe -dSolutionDir="%PROJECT_DIR%\\" -out "%OUTPUT_DIR%\Product.wixobj" "%INSTALLER_DIR%\Product.wxs"
if errorlevel 1 (
    echo ERROR: WiX compilation failed
    pause
    exit /b 1
)

echo Linking installer...
light.exe -ext WixUIExtension -out "%OUTPUT_DIR%\OBS-AI-Transcription-Filter-Setup.msi" "%OUTPUT_DIR%\Product.wixobj"
if errorlevel 1 (
    echo ERROR: WiX linking failed
    pause
    exit /b 1
)

echo SUCCESS: Installer created at %OUTPUT_DIR%\OBS-AI-Transcription-Filter-Setup.msi
echo.
echo You can now distribute this MSI file to install the plugin on other systems.
pause