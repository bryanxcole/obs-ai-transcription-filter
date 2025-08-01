# OBS AI Transcription Filter - Auto-Installing Build Script
# This script will automatically download and install dependencies if needed

param(
    [string]$Configuration = "Release",
    [string]$OBSPath = "C:\Program Files\obs-studio",
    [switch]$UseVcpkg = $false,
    [switch]$SetupDependencies = $false
)

$ErrorActionPreference = "Continue"

Write-Host "=== OBS AI Transcription Filter - Auto Build ===" -ForegroundColor Green
Write-Host "This script will automatically install required tools if needed." -ForegroundColor Yellow

# Setup dependencies if requested
if ($SetupDependencies) {
    Write-Host "Setting up dependencies first..." -ForegroundColor Yellow
    & .\setup-dependencies.ps1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Dependency setup failed" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    $UseVcpkg = $true
}

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to download file with progress
function Download-File {
    param([string]$Url, [string]$OutputPath)
    
    Write-Host "Downloading: $Url" -ForegroundColor Yellow
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($Url, $OutputPath)
        Write-Host "✓ Downloaded: $OutputPath" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Download failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to install CMake
function Install-CMake {
    Write-Host "CMake not found. Installing CMake..." -ForegroundColor Yellow
    
    # Create temp directory
    $tempDir = Join-Path $env:TEMP "cmake-install"
    if (-not (Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir | Out-Null
    }
    
    # Download CMake installer
    $cmakeUrl = "https://github.com/Kitware/CMake/releases/download/v3.28.1/cmake-3.28.1-windows-x86_64.msi"
    $cmakeInstaller = Join-Path $tempDir "cmake-installer.msi"
    
    if (Download-File -Url $cmakeUrl -OutputPath $cmakeInstaller) {
        Write-Host "Installing CMake (this may take a few minutes)..." -ForegroundColor Yellow
        
        # Install silently with PATH option
        $installArgs = @(
            "/i", $cmakeInstaller,
            "/quiet",
            "ADD_CMAKE_TO_PATH=System"
        )
        
        try {
            $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $installArgs -Wait -PassThru
            
            if ($process.ExitCode -eq 0) {
                Write-Host "✓ CMake installed successfully" -ForegroundColor Green
                
                # Refresh environment variables
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                
                # Clean up
                Remove-Item $cmakeInstaller -Force -ErrorAction SilentlyContinue
                
                return $true
            } else {
                Write-Host "❌ CMake installation failed (Exit code: $($process.ExitCode))" -ForegroundColor Red
                return $false
            }
        } catch {
            Write-Host "❌ CMake installation failed: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
    return $false
}

# Function to check and install Visual Studio Build Tools
function Install-VSBuildTools {
    Write-Host "Visual Studio Build Tools not found. Installing..." -ForegroundColor Yellow
    
    $tempDir = Join-Path $env:TEMP "vs-install"
    if (-not (Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir | Out-Null
    }
    
    # Download VS Build Tools installer
    $vsUrl = "https://aka.ms/vs/17/release/vs_buildtools.exe"
    $vsInstaller = Join-Path $tempDir "vs_buildtools.exe"
    
    if (Download-File -Url $vsUrl -OutputPath $vsInstaller) {
        Write-Host "Installing Visual Studio Build Tools (this will take several minutes)..." -ForegroundColor Yellow
        Write-Host "The installer window may appear - please wait for it to complete." -ForegroundColor Cyan
        
        # Install with C++ workload
        $installArgs = @(
            "--quiet",
            "--wait",
            "--add", "Microsoft.VisualStudio.Workload.VCTools",
            "--add", "Microsoft.VisualStudio.Component.Windows10SDK.19041"
        )
        
        try {
            $process = Start-Process -FilePath $vsInstaller -ArgumentList $installArgs -Wait -PassThru
            
            if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
                Write-Host "✓ Visual Studio Build Tools installed successfully" -ForegroundColor Green
                Remove-Item $vsInstaller -Force -ErrorAction SilentlyContinue
                return $true
            } else {
                Write-Host "⚠️ Visual Studio Build Tools installation may have issues (Exit code: $($process.ExitCode))" -ForegroundColor Yellow
                Write-Host "You may need to install Visual Studio manually" -ForegroundColor Yellow
                return $false
            }
        } catch {
            Write-Host "❌ Visual Studio Build Tools installation failed: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
    return $false
}

# Check if running as administrator
if (-not (Test-Administrator)) {
    Write-Host "⚠️ This script should be run as Administrator for automatic installations" -ForegroundColor Yellow
    Write-Host "Trying to restart as Administrator..." -ForegroundColor Yellow
    
    try {
        $arguments = "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
        Start-Process PowerShell -Verb RunAs -ArgumentList $arguments
        exit
    } catch {
        Write-Host "❌ Could not restart as Administrator. Please run PowerShell as Administrator manually." -ForegroundColor Red
        Read-Host "Press Enter to continue anyway (some features may not work)"
    }
}

# Check for CMake
Write-Host "Checking for CMake..." -ForegroundColor Yellow
$cmakeFound = $false

try {
    $cmakeVersion = & cmake --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ CMake found: $($cmakeVersion[0])" -ForegroundColor Green
        $cmakeFound = $true
    }
} catch {
    # CMake not found
}

if (-not $cmakeFound) {
    if (Install-CMake) {
        $cmakeFound = $true
    } else {
        Write-Host "❌ Could not install CMake automatically" -ForegroundColor Red
        Write-Host "Please install CMake manually from: https://cmake.org/download/" -ForegroundColor Cyan
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Check for Visual Studio or Build Tools
Write-Host "Checking for Visual Studio..." -ForegroundColor Yellow
$vsFound = $false

# Check for Visual Studio 2022
$vsPaths = @(
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe",
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe"
)

foreach ($path in $vsPaths) {
    if (Test-Path $path) {
        Write-Host "✓ Visual Studio found at: $(Split-Path (Split-Path $path))" -ForegroundColor Green
        $vsFound = $true
        break
    }
}

if (-not $vsFound) {
    Write-Host "Visual Studio not found. You have two options:" -ForegroundColor Yellow
    Write-Host "1. Install Visual Studio Build Tools automatically (recommended)" -ForegroundColor Cyan
    Write-Host "2. Install Visual Studio Community manually (full IDE)" -ForegroundColor Cyan
    
    $choice = Read-Host "Choose option (1 or 2, or 'skip' to continue without)"
    
    if ($choice -eq "1") {
        Install-VSBuildTools | Out-Null
    } elseif ($choice -eq "2") {
        Write-Host "Please download Visual Studio Community from:" -ForegroundColor Cyan
        Write-Host "https://visualstudio.microsoft.com/vs/community/" -ForegroundColor Cyan
        Read-Host "Install it with 'Desktop development with C++' workload, then press Enter to continue"
    }
}

# Create build directory
Write-Host "Setting up build directory..." -ForegroundColor Yellow
$buildDir = "build"
if (Test-Path $buildDir) {
    Write-Host "Cleaning existing build directory..." -ForegroundColor Yellow
    Remove-Item $buildDir -Recurse -Force
}
New-Item -ItemType Directory -Path $buildDir | Out-Null

# Change to build directory
Push-Location $buildDir

try {
    # Configure with CMake
    Write-Host "Configuring project with CMake..." -ForegroundColor Yellow
    
    $cmakeArgs = @("..", "-G", "Visual Studio 17 2022", "-A", "x64")
    
    # Add vcpkg toolchain if requested
    if ($UseVcpkg -and (Test-Path "vcpkg-toolchain.cmake")) {
        Write-Host "Using vcpkg dependencies..." -ForegroundColor Cyan
        $cmakeArgs += "-DCMAKE_TOOLCHAIN_FILE=vcpkg-toolchain.cmake"
    }
    
    & cmake @cmakeArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ CMake configuration failed" -ForegroundColor Red
        Write-Host "Trying with Visual Studio 16 2019..." -ForegroundColor Yellow
        & cmake .. -G "Visual Studio 16 2019" -A x64
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ CMake configuration failed with both VS 2022 and 2019" -ForegroundColor Red
            throw "CMake configuration failed"
        }
    }
    Write-Host "✓ CMake configuration successful" -ForegroundColor Green

    # Build the project
    Write-Host "Building project ($Configuration)..." -ForegroundColor Yellow
    & cmake --build . --config $Configuration
    
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }
    Write-Host "✓ Build completed successfully" -ForegroundColor Green

    # Check for output files
    $pluginDll = "$Configuration\obs-ai-transcription-filter.dll"
    if (Test-Path $pluginDll) {
        $dllInfo = Get-Item $pluginDll
        Write-Host "✓ Plugin DLL created successfully!" -ForegroundColor Green
        Write-Host "  Location: $pluginDll" -ForegroundColor Cyan
        Write-Host "  Size: $([math]::Round($dllInfo.Length / 1KB, 2)) KB" -ForegroundColor Cyan
        Write-Host "  Modified: $($dllInfo.LastWriteTime)" -ForegroundColor Cyan
        
        # Try to create MSI if possible
        Write-Host "Attempting to create MSI installer..." -ForegroundColor Yellow
        try {
            & cpack -G WIX -C $Configuration 2>$null
            if ($LASTEXITCODE -eq 0) {
                $msiFiles = Get-ChildItem -Filter "*.msi"
                if ($msiFiles) {
                    Write-Host "✓ MSI installer created:" -ForegroundColor Green
                    foreach ($msi in $msiFiles) {
                        Write-Host "  $($msi.Name)" -ForegroundColor Cyan
                    }
                }
            }
        } catch {
            Write-Host "⚠️ MSI creation skipped (WiX not available)" -ForegroundColor Yellow
        }
        
    } else {
        Write-Host "⚠️ Plugin DLL not found at expected location" -ForegroundColor Yellow
        Write-Host "Searching for DLL files..." -ForegroundColor Yellow
        Get-ChildItem -Recurse -Filter "*.dll" | ForEach-Object {
            Write-Host "  Found: $($_.FullName)" -ForegroundColor Cyan
        }
    }

} catch {
    Write-Host "❌ Build process failed: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Pop-Location
}

# Final instructions
Write-Host "`n=== Build Complete ===" -ForegroundColor Green
if (Test-Path "build\$Configuration\obs-ai-transcription-filter.dll") {
    Write-Host "✓ SUCCESS: Plugin ready for installation!" -ForegroundColor Green
    Write-Host "`nInstallation options:" -ForegroundColor Yellow
    Write-Host "1. Manual installation:" -ForegroundColor Cyan
    Write-Host "   - Copy build\$Configuration\obs-ai-transcription-filter.dll to:" -ForegroundColor Gray
    Write-Host "     $OBSPath\obs-plugins\64bit\" -ForegroundColor Gray
    Write-Host "   - Copy data\locale\en-US.ini to:" -ForegroundColor Gray
    Write-Host "     $OBSPath\data\obs-plugins\obs-ai-transcription-filter\locale\" -ForegroundColor Gray
    Write-Host "   - Restart OBS Studio" -ForegroundColor Gray
    
    if (Test-Path "build\*.msi") {
        Write-Host "`n2. MSI installer:" -ForegroundColor Cyan
        Write-Host "   - Run the .msi file in the build directory as Administrator" -ForegroundColor Gray
    }
} else {
    Write-Host "❌ Build did not complete successfully" -ForegroundColor Red
    Write-Host "Check the error messages above for details" -ForegroundColor Yellow
}

Read-Host "`nPress Enter to exit"