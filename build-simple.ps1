# Simple build script for OBS AI Transcription Filter

param(
    [string]$Configuration = "Release"
)

Write-Host "=== OBS AI Transcription Filter - Simple Build ===" -ForegroundColor Green

# Check if CMake is available
Write-Host "Checking for CMake..." -ForegroundColor Yellow
try {
    $null = & cmake --version
    Write-Host "✓ CMake found" -ForegroundColor Green
} catch {
    Write-Host "❌ CMake not found. Please install CMake and add it to PATH." -ForegroundColor Red
    Write-Host "Download from: https://cmake.org/download/" -ForegroundColor Cyan
    exit 1
}

# Create/clean build directory
Write-Host "Setting up build directory..." -ForegroundColor Yellow
$buildDir = "build"
if (Test-Path $buildDir) {
    Write-Host "Cleaning existing build directory..." -ForegroundColor Yellow
    Remove-Item $buildDir -Recurse -Force
}
New-Item -ItemType Directory -Path $buildDir | Out-Null
Write-Host "✓ Build directory created" -ForegroundColor Green

# Change to build directory  
Set-Location $buildDir

try {
    # Configure with CMake
    Write-Host "Configuring project with CMake..." -ForegroundColor Yellow
    & cmake .. -G "Visual Studio 17 2022" -A x64
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ CMake configuration failed" -ForegroundColor Red
        Write-Host "Make sure you have Visual Studio 2022 installed with C++ support" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "✓ CMake configuration successful" -ForegroundColor Green

    # Build the project
    Write-Host "Building project ($Configuration)..." -ForegroundColor Yellow
    & cmake --build . --config $Configuration
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Build failed" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Build completed successfully" -ForegroundColor Green

    # Check for output files
    $pluginDll = "$Configuration\obs-ai-transcription-filter.dll"
    if (Test-Path $pluginDll) {
        $dllInfo = Get-Item $pluginDll
        Write-Host "✓ Plugin DLL created:" -ForegroundColor Green
        Write-Host "  Location: $pluginDll" -ForegroundColor Cyan
        Write-Host "  Size: $([math]::Round($dllInfo.Length / 1KB, 2)) KB" -ForegroundColor Cyan
        Write-Host "  Modified: $($dllInfo.LastWriteTime)" -ForegroundColor Cyan
    } else {
        Write-Host "⚠️ Plugin DLL not found at: $pluginDll" -ForegroundColor Yellow
        Write-Host "Build may have succeeded but output location is different" -ForegroundColor Yellow
    }
    
    # List all files in build directory
    Write-Host "`nBuild directory contents:" -ForegroundColor Yellow
    Get-ChildItem -Recurse | Format-Table Name, Length, LastWriteTime

} catch {
    Write-Host "❌ Build process failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    # Return to original directory
    Set-Location ..
}

Write-Host "`n=== Build Summary ===" -ForegroundColor Green
Write-Host "Build directory: $(Get-Location)\build" -ForegroundColor Cyan
Write-Host "If successful, the plugin DLL should be in: build\$Configuration\" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Check the build directory for obs-ai-transcription-filter.dll" -ForegroundColor Cyan
Write-Host "2. If found, you can manually install it to OBS" -ForegroundColor Cyan
Write-Host "3. Or try the full build-msi.ps1 script for MSI creation" -ForegroundColor Cyan