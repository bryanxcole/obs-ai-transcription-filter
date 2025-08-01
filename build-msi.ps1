# OBS AI Transcription Filter - Build and Package Script
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
try {
    $cmakeVersion = & cmake --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ CMake found: $($cmakeVersion[0])" -ForegroundColor Green
    } else {
        throw "CMake not found"
    }
} catch {
    Write-Host "❌ CMake not found. Please install CMake and add it to PATH." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check Visual Studio
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsWhere) {
    $vsPath = & $vsWhere -latest -property installationPath
    if ($vsPath) {
        Write-Host "✓ Visual Studio found at: $vsPath" -ForegroundColor Green
    } else {
        Write-Host "❌ Visual Studio not found. Please install Visual Studio with C++ support." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
} else {
    Write-Host "⚠️ Could not detect Visual Studio installation." -ForegroundColor Yellow
}

# Check WiX Toolset
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
if (Test-Path "$OBSPath\bin\64bit\obs64.exe") {
    Write-Host "✓ OBS Studio found at: $OBSPath" -ForegroundColor Green
} else {
    Write-Warning "OBS Studio not found at $OBSPath"
    Write-Host "You can specify a different path with -OBSPath parameter" -ForegroundColor Cyan
}

# Create build directory
$buildDir = "build"
if (Test-Path $buildDir) {
    Write-Host "Cleaning existing build directory..." -ForegroundColor Yellow
    Remove-Item $buildDir -Recurse -Force
}
New-Item -ItemType Directory -Path $buildDir | Out-Null

# Configure with CMake
Write-Host "Configuring with CMake..." -ForegroundColor Yellow
Push-Location $buildDir

try {
    & cmake .. -G "Visual Studio 17 2022" -A x64 -DCMAKE_BUILD_TYPE=$Configuration
    if ($LASTEXITCODE -ne 0) {
        throw "CMake configuration failed"
    }
    Write-Host "✓ CMake configuration completed" -ForegroundColor Green

    # Build the project
    Write-Host "Building project ($Configuration)..." -ForegroundColor Yellow
    & cmake --build . --config $Configuration
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }
    Write-Host "✓ Build completed successfully" -ForegroundColor Green

    # Check if plugin DLL was created
    $pluginDll = "$Configuration\obs-ai-transcription-filter.dll"
    if (Test-Path $pluginDll) {
        Write-Host "✓ Plugin DLL created: $pluginDll" -ForegroundColor Green
        
        # Get file info
        $dllInfo = Get-Item $pluginDll
        Write-Host "  Size: $([math]::Round($dllInfo.Length / 1KB, 2)) KB" -ForegroundColor Gray
        Write-Host "  Modified: $($dllInfo.LastWriteTime)" -ForegroundColor Gray
    } else {
        Write-Warning "Plugin DLL not found at expected location: $pluginDll"
    }

    # Create MSI package
    Write-Host "Creating MSI package..." -ForegroundColor Yellow
    try {
        & cpack -G WIX -C $Configuration
        if ($LASTEXITCODE -eq 0) {
            $msiFiles = Get-ChildItem -Filter "*.msi"
            if ($msiFiles) {
                Write-Host "✓ MSI package created successfully:" -ForegroundColor Green
                foreach ($msi in $msiFiles) {
                    Write-Host "  $($msi.Name) ($([math]::Round($msi.Length / 1MB, 2)) MB)" -ForegroundColor Cyan
                }
            }
        } else {
            Write-Warning "MSI package creation failed (cpack returned $LASTEXITCODE)"
        }
    } catch {
        Write-Warning "MSI package creation failed: $($_.Exception.Message)"
        Write-Host "You can still manually install the plugin DLL to OBS" -ForegroundColor Cyan
    }

} catch {
    Write-Error "Build process failed: $($_.Exception.Message)"
} finally {
    Pop-Location
}

# Installation instructions
Write-Host "`n=== Installation Instructions ===" -ForegroundColor Green
Write-Host "If MSI creation succeeded:"
Write-Host "  1. Run the generated .msi file as Administrator" -ForegroundColor Cyan
Write-Host "  2. The installer will automatically detect OBS and install the plugin" -ForegroundColor Cyan

Write-Host "`nIf you want to install manually:"
Write-Host "  1. Copy build\$Configuration\obs-ai-transcription-filter.dll to:" -ForegroundColor Cyan
Write-Host "     $OBSPath\obs-plugins\64bit\" -ForegroundColor Gray
Write-Host "  2. Copy data\locale\en-US.ini to:" -ForegroundColor Cyan  
Write-Host "     $OBSPath\data\obs-plugins\obs-ai-transcription-filter\locale\" -ForegroundColor Gray
Write-Host "  3. Restart OBS Studio" -ForegroundColor Cyan
Write-Host "  4. Add 'AI Transcription Filter' to any audio source" -ForegroundColor Cyan

Write-Host "`nNote: This plugin requires additional dependencies for full functionality:" -ForegroundColor Yellow
Write-Host "  - Whisper.cpp for speech recognition" -ForegroundColor Gray
Write-Host "  - libcurl for LLM API communication" -ForegroundColor Gray
Write-Host "  - JsonCpp for JSON parsing" -ForegroundColor Gray

Write-Host "`nBuild completed!" -ForegroundColor Green