@echo off
echo === Testing OBS Plugin Build ===

echo Creating build directory...
if exist build rmdir /s /q build
mkdir build
cd build

echo Configuring with CMake...
cmake .. -G "Visual Studio 17 2022" -A x64
if errorlevel 1 (
    echo CMake configuration failed
    pause
    exit /b 1
)

echo Building project...
cmake --build . --config Release
if errorlevel 1 (
    echo Build failed
    pause
    exit /b 1
)

echo Checking output...
if exist Release\obs-ai-transcription-filter.dll (
    echo SUCCESS: Plugin DLL created
    dir Release\obs-ai-transcription-filter.dll
) else (
    echo WARNING: Plugin DLL not found in expected location
    echo Contents of Release folder:
    dir Release\
)

pause