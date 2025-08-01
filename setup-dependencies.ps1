# OBS AI Transcription Filter - Dependency Setup Script
# This script installs all required dependencies using vcpkg

param(
    [string]$VcpkgPath = "",
    [switch]$SkipOBS = $false
)

$ErrorActionPreference = "Continue"

Write-Host "=== OBS AI Transcription Filter - Dependency Setup ===" -ForegroundColor Green

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to download file
function Download-File {
    param([string]$Url, [string]$OutputPath)
    
    Write-Host "Downloading: $Url" -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UseBasicParsing
        Write-Host "✓ Downloaded: $OutputPath" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Download failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to extract zip file
function Extract-Archive {
    param([string]$ZipFile, [string]$Destination)
    
    try {
        Expand-Archive -Path $ZipFile -DestinationPath $Destination -Force
        Write-Host "✓ Extracted: $ZipFile" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Extraction failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Check for administrator privileges
if (-not (Test-Administrator)) {
    Write-Host "⚠️ Some operations may require Administrator privileges" -ForegroundColor Yellow
}

# Set up directories
$depsDir = "dependencies"
$vcpkgDir = Join-Path $depsDir "vcpkg"
$obsDir = Join-Path $depsDir "obs-studio"

if (-not (Test-Path $depsDir)) {
    New-Item -ItemType Directory -Path $depsDir | Out-Null
}

# Install or use existing vcpkg
if ($VcpkgPath -and (Test-Path $VcpkgPath)) {
    Write-Host "Using existing vcpkg at: $VcpkgPath" -ForegroundColor Green
    $vcpkgExe = Join-Path $VcpkgPath "vcpkg.exe"
} else {
    Write-Host "Setting up vcpkg package manager..." -ForegroundColor Yellow
    
    if (-not (Test-Path $vcpkgDir)) {
        # Clone vcpkg
        Write-Host "Cloning vcpkg..." -ForegroundColor Yellow
        try {
            & git clone https://github.com/Microsoft/vcpkg.git $vcpkgDir
            if ($LASTEXITCODE -ne 0) { throw "Git clone failed" }
        } catch {
            Write-Host "❌ Failed to clone vcpkg. Please install git or download vcpkg manually." -ForegroundColor Red
            exit 1
        }
    }
    
    # Bootstrap vcpkg
    $vcpkgExe = Join-Path $vcpkgDir "vcpkg.exe"
    if (-not (Test-Path $vcpkgExe)) {
        Write-Host "Bootstrapping vcpkg..." -ForegroundColor Yellow
        Push-Location $vcpkgDir
        try {
            & .\bootstrap-vcpkg.bat
            if ($LASTEXITCODE -ne 0) { throw "Bootstrap failed" }
        } catch {
            Write-Host "❌ Failed to bootstrap vcpkg" -ForegroundColor Red
            Pop-Location
            exit 1
        }
        Pop-Location
    }
    
    Write-Host "✓ vcpkg ready" -ForegroundColor Green
}

# Install required packages via vcpkg
$packages = @(
    "curl[core,ssl]:x64-windows",
    "jsoncpp:x64-windows"
)

Write-Host "Installing dependencies via vcpkg..." -ForegroundColor Yellow
foreach ($package in $packages) {
    Write-Host "Installing $package..." -ForegroundColor Cyan
    & $vcpkgExe install $package
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Installed: $package" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Failed to install: $package" -ForegroundColor Yellow
    }
}

# Download OBS Studio development files
if (-not $SkipOBS) {
    Write-Host "Setting up OBS Studio development files..." -ForegroundColor Yellow
    
    if (-not (Test-Path $obsDir)) {
        $obsUrl = "https://github.com/obsproject/obs-studio/releases/download/30.0.2/OBS-Studio-30.0.2-Windows.zip"
        $obsZip = Join-Path $depsDir "obs-studio.zip"
        
        if (Download-File -Url $obsUrl -OutputPath $obsZip) {
            if (Extract-Archive -ZipFile $obsZip -Destination $obsDir) {
                Remove-Item $obsZip -Force -ErrorAction SilentlyContinue
                Write-Host "✓ OBS Studio files ready" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "✓ OBS Studio files already present" -ForegroundColor Green
    }
    
    # Download OBS development headers separately
    $obsHeadersUrl = "https://github.com/obsproject/obs-studio/archive/refs/tags/30.0.2.zip"
    $obsHeadersZip = Join-Path $depsDir "obs-headers.zip"
    $obsHeadersDir = Join-Path $depsDir "obs-headers"
    
    if (-not (Test-Path $obsHeadersDir)) {
        Write-Host "Downloading OBS development headers..." -ForegroundColor Yellow
        if (Download-File -Url $obsHeadersUrl -OutputPath $obsHeadersZip) {
            if (Extract-Archive -ZipFile $obsHeadersZip -Destination $obsHeadersDir) {
                Remove-Item $obsHeadersZip -Force -ErrorAction SilentlyContinue
                Write-Host "✓ OBS headers ready" -ForegroundColor Green
            }
        }
    }
}

# Download Whisper.cpp (optional)
Write-Host "Setting up Whisper.cpp (optional)..." -ForegroundColor Yellow
$whisperDir = Join-Path $depsDir "whisper.cpp"
if (-not (Test-Path $whisperDir)) {
    try {
        & git clone https://github.com/ggerganov/whisper.cpp.git $whisperDir
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Whisper.cpp cloned" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠️ Could not clone Whisper.cpp (optional dependency)" -ForegroundColor Yellow
    }
}

# Create CMake toolchain file
$toolchainFile = "vcpkg-toolchain.cmake"
$vcpkgRoot = if ($VcpkgPath) { $VcpkgPath } else { $vcpkgDir }
$toolchainPath = Join-Path $vcpkgRoot "scripts\buildsystems\vcpkg.cmake"

Write-Host "Creating CMake configuration..." -ForegroundColor Yellow
$cmakeConfig = @"
# CMake configuration for OBS AI Transcription Filter
set(CMAKE_TOOLCHAIN_FILE "$($toolchainPath.Replace('\', '/'))")
set(VCPKG_ROOT "$($vcpkgRoot.Replace('\', '/'))")
set(OBS_HEADERS_DIR "$((Join-Path $depsDir "obs-headers").Replace('\', '/'))")

# Set up include and library paths
list(APPEND CMAKE_PREFIX_PATH "`${VCPKG_ROOT}/installed/x64-windows")
"@

Set-Content -Path $toolchainFile -Value $cmakeConfig
Write-Host "✓ CMake toolchain file created: $toolchainFile" -ForegroundColor Green

# Summary
Write-Host "`n=== Dependency Setup Complete ===" -ForegroundColor Green
Write-Host "Installed dependencies:" -ForegroundColor Yellow
Write-Host "  ✓ vcpkg package manager" -ForegroundColor Cyan
Write-Host "  ✓ libcurl (for LLM API communication)" -ForegroundColor Cyan
Write-Host "  ✓ JsonCpp (for JSON parsing)" -ForegroundColor Cyan
if (-not $SkipOBS) {
    Write-Host "  ✓ OBS Studio headers" -ForegroundColor Cyan
}
if (Test-Path $whisperDir) {
    Write-Host "  ✓ Whisper.cpp (for speech recognition)" -ForegroundColor Cyan
}

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Run: .\auto-build.ps1 -UseVcpkg" -ForegroundColor Cyan
Write-Host "2. Or manually configure with: cmake .. -DCMAKE_TOOLCHAIN_FILE=vcpkg-toolchain.cmake" -ForegroundColor Cyan

Write-Host "`nDependency locations:" -ForegroundColor Gray
Write-Host "  vcpkg: $vcpkgRoot" -ForegroundColor Gray
Write-Host "  Dependencies: $depsDir" -ForegroundColor Gray
Write-Host "  Toolchain: $toolchainFile" -ForegroundColor Gray

Read-Host "`nPress Enter to continue"