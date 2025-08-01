# OBS AI Transcription Filter - Build and Package Script (Fixed)
# Requires: Visual Studio, CMake, WiX Toolset

param(
    [string]$Configuration = "Release",
    [string]$OBSPath = "C:\Program Files\obs-studio"
)

$ErrorActionPreference = "Continue"

Write-Host "=== OBS AI Transcription Filter - Build & Package ===" -ForegroundColor Green

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check CMake
Write-Host "Checking for CMake..." -ForegroundColor Gray
try {
    $cmakeVersion = & cmake --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ CMake found: $($cmakeVersion[0])" -ForegroundColor Green
    } else {
        throw "CMake not found"
    }
} catch {
    Write-Host "❌ CMake not found. Please install CMake and add it to PATH." -ForegroundColor Red
    Write-Host "Download from: https://cmake.org/download/" -ForegroundColor Cyan
    Read-Host "Press Enter to exit"
    exit 1
}

# Check Visual Studio
Write-Host "Checking for Visual Studio..." -ForegroundColor Gray
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsWhere) {
    try {
        $vsPath = & $vsWhere -latest -property installationPath
        if ($vsPath) {
            Write-Host "✓ Visual Studio found at: $vsPath" -ForegroundColor Green
        } else {
            Write-Host "❌ Visual Studio not found. Please install Visual Studio with C++ support." -ForegroundColor Red
            Read-Host "Press Enter to exit"
            exit 1
        }
    } catch {
        Write-Host "⚠️ Could not query Visual Studio installation" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ Could not detect Visual Studio installation" -ForegroundColor Yellow
    Write-Host "Make sure Visual Studio 2019 or 2022 is installed with C++ support" -ForegroundColor Cyan
}

# Check WiX Toolset
Write-Host "Checking for WiX Toolset..." -ForegroundColor Gray
try {
    $null = & candle.exe -? 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ WiX Toolset found" -ForegroundColor Green
    } else {
        throw "WiX not found"
    }
} catch {
    Write-Host "⚠️ WiX Toolset not found in PATH. You can still build the plugin, but MSI creation will fail." -ForegroundColor Yellow
    Write-Host "Download WiX from: https://github.com/wixtoolset/wix3/releases" -ForegroundColor Cyan
}

# Check OBS Studio installation
Write-Host "Checking for OBS Studio..." -ForegroundColor Gray
if (Test-Path "$OBSPath\bin\64bit\obs64.exe") {
    Write-Host "✓ OBS Studio found at: $OBSPath" -ForegroundColor Green
} else {
    Write-Host "⚠️ OBS Studio not found at $OBSPath" -ForegroundColor Yellow
    Write-Host "You can specify a different path with -OBSPath parameter" -ForegroundColor Cyan
}

# Create build directory
Write-Host "`nSetting up build environment..." -ForegroundColor Yellow
$buildDir = "build"
if (Test-Path $buildDir) {
    Write-Host "Cleaning existing build directory..." -ForegroundColor Gray
    Remove-Item $buildDir -Recurse -Force
}
New-Item -ItemType Directory -Path $buildDir | Out-Null
Write-Host "✓ Build directory created" -ForegroundColor Green

# Configure with CMake
Write-Host "`nConfiguring with CMake..." -ForegroundColor Yellow
Push-Location $buildDir

try {
    & cmake .. -G "Visual Studio 17 2022" -A x64 -DCMAKE_BUILD_TYPE=$Configuration
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ CMake configuration failed with VS 2022. Trying VS 2019..." -ForegroundColor Yellow
        & cmake .. -G "Visual Studio 16 2019" -A x64 -DCMAKE_BUILD_TYPE=$Configuration
        if ($LASTEXITCODE -ne 0) {
            throw "CMake configuration failed with both VS 2022 and VS 2019"
        }
    }
    Write-Host "✓ CMake configuration completed" -ForegroundColor Green

    # Build the project
    Write-Host "`nBuilding project ($Configuration)..." -ForegroundColor Yellow
    & cmake --build . --config $Configuration
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }
    Write-Host "✓ Build completed successfully" -ForegroundColor Green

    # Check if plugin DLL was created
    $pluginDll = "$Configuration\obs-ai-transcription-filter.dll"
    if (Test-Path $pluginDll) {
        $dllInfo = Get-Item $pluginDll
        Write-Host "✓ Plugin DLL created: $pluginDll" -ForegroundColor Green
        Write-Host "  Size: $([math]::Round($dllInfo.Length / 1KB, 2)) KB" -ForegroundColor Gray
        Write-Host "  Modified: $($dllInfo.LastWriteTime)" -ForegroundColor Gray
    } else {
        Write-Host "⚠️ Plugin DLL not found at expected location: $pluginDll" -ForegroundColor Yellow
        Write-Host "Searching for DLL files..." -ForegroundColor Gray
        Get-ChildItem -Recurse -Filter "*.dll" | ForEach-Object {
            Write-Host "  Found: $($_.Name) in $($_.Directory)" -ForegroundColor Cyan
        }
    }

    # Create MSI package
    Write-Host "`nCreating MSI package..." -ForegroundColor Yellow
    try {
        & cpack -G WIX -C $Configuration
        if ($LASTEXITCODE -eq 0) {
            $msiFiles = Get-ChildItem -Filter "*.msi"
            if ($msiFiles) {
                Write-Host "✓ MSI package created successfully:" -ForegroundColor Green
                foreach ($msi in $msiFiles) {
                    Write-Host "  $($msi.Name) ($([math]::Round($msi.Length / 1MB, 2)) MB)" -ForegroundColor Cyan
                }
            } else {
                Write-Host "⚠️ MSI files not found after cpack execution" -ForegroundColor Yellow
            }
        } else {
            Write-Host "⚠️ MSI package creation failed (cpack returned $LASTEXITCODE)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️ MSI package creation failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "You can still manually install the plugin DLL to OBS" -ForegroundColor Cyan
    }

} catch {
    Write-Host "❌ Build process failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Check the error messages above for details" -ForegroundColor Yellow
} finally {
    Pop-Location
}

# Installation instructions
Write-Host "`n=== Installation Instructions ===" -ForegroundColor Green

if (Test-Path "build\$Configuration\obs-ai-transcription-filter.dll") {
    Write-Host "✓ Build completed successfully!" -ForegroundColor Green
    
    Write-Host "`nIf MSI creation succeeded:" -ForegroundColor Yellow
    Write-Host "  1. Run the generated .msi file as Administrator" -ForegroundColor Cyan
    Write-Host "  2. The installer will automatically detect OBS and install the plugin" -ForegroundColor Cyan

    Write-Host "`nFor manual installation:" -ForegroundColor Yellow
    Write-Host "  1. Copy build\$Configuration\obs-ai-transcription-filter.dll to:" -ForegroundColor Cyan
    Write-Host "     $OBSPath\obs-plugins\64bit\" -ForegroundColor Gray
    Write-Host "  2. Copy data\locale\en-US.ini to:" -ForegroundColor Cyan  
    Write-Host "     $OBSPath\data\obs-plugins\obs-ai-transcription-filter\locale\" -ForegroundColor Gray
    Write-Host "  3. Restart OBS Studio" -ForegroundColor Cyan
    Write-Host "  4. Add 'AI Transcription Filter' to any audio source" -ForegroundColor Cyan
} else {
    Write-Host "❌ Build did not complete successfully" -ForegroundColor Red
    Write-Host "Please check the error messages above and ensure all prerequisites are installed" -ForegroundColor Yellow
}

Write-Host "`nNote: This plugin requires additional dependencies for full functionality:" -ForegroundColor Yellow
Write-Host "  - Whisper.cpp for speech recognition" -ForegroundColor Gray
Write-Host "  - libcurl for LLM API communication" -ForegroundColor Gray
Write-Host "  - JsonCpp for JSON parsing" -ForegroundColor Gray
Write-Host "  - Run .\auto-build.ps1 -SetupDependencies for full setup" -ForegroundColor Cyan

Read-Host "`nPress Enter to exit"