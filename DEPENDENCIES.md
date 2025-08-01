# Dependencies Guide - OBS AI Transcription Filter

This document outlines all dependencies required for building and using the OBS AI Transcription Filter.

## 🔧 Build Dependencies

### Required for Building
1. **CMake 3.16+** - Build system generator
2. **Visual Studio 2019/2022** - C++ compiler and build tools
3. **Git** - For cloning repositories

### Package Manager
- **vcpkg** - C++ library manager (automatically installed by setup script)

## 📚 Runtime Dependencies

### Core Plugin Dependencies
1. **OBS Studio 28.0+** - Target platform
   - Plugin requires OBS development headers
   - Runtime requires OBS installation

### AI/ML Dependencies
1. **libcurl** - HTTP client for LLM API communication
   - **Purpose**: Sends transcription text to LLM APIs for correction
   - **Status**: ✅ Auto-installed via vcpkg
   - **Fallback**: Plugin builds without it but LLM features disabled

2. **JsonCpp** - JSON parsing library
   - **Purpose**: Parse LLM API responses
   - **Status**: ✅ Auto-installed via vcpkg  
   - **Fallback**: Plugin builds without it but JSON parsing limited

3. **Whisper.cpp** - Speech recognition engine
   - **Purpose**: Convert audio to text
   - **Status**: ⚠️ Optional (placeholder implementation included)
   - **Integration**: Requires manual setup for full functionality

### Optional Dependencies
1. **WiX Toolset v3.11+** - MSI installer creation
   - **Purpose**: Create professional Windows installers
   - **Status**: ⚠️ Optional for development

## 🚀 Automated Setup

### Option 1: Full Auto-Setup (Recommended)
```powershell
# Run as Administrator
.\auto-build.ps1 -SetupDependencies
```
This will:
- Install CMake and Visual Studio Build Tools
- Set up vcpkg package manager
- Install libcurl and JsonCpp
- Download OBS development headers
- Build the plugin with all dependencies

### Option 2: Dependencies Only
```powershell
.\setup-dependencies.ps1
.\auto-build.ps1 -UseVcpkg
```

### Option 3: Manual Build
```powershell
.\auto-build.ps1
```
Builds with basic dependencies only.

## 📦 Dependency Details

### libcurl
- **Version**: Latest stable via vcpkg
- **Features**: SSL support enabled
- **Size**: ~2-3 MB
- **Usage**: LLM API communication (OpenAI, Claude, etc.)

### JsonCpp
- **Version**: Latest stable via vcpkg  
- **Size**: ~500 KB
- **Usage**: Parse JSON responses from LLM APIs

### OBS Studio Headers
- **Version**: 30.0.2 (matches latest OBS)
- **Size**: ~50 MB download
- **Usage**: Plugin development and compilation

### vcpkg Packages
Automatically installs:
```
curl[core,ssl]:x64-windows
jsoncpp:x64-windows
```

## 🔄 Whisper.cpp Integration

### Current Status
- **Included**: Placeholder implementation
- **Functional**: No (requires integration work)
- **Location**: `src/whisper-engine.cpp`

### Full Integration Steps
1. Build whisper.cpp library:
   ```bash
   git clone https://github.com/ggerganov/whisper.cpp.git
   cd whisper.cpp
   mkdir build && cd build
   cmake .. -DBUILD_SHARED_LIBS=ON
   cmake --build . --config Release
   ```

2. Update CMakeLists.txt to link whisper library

3. Replace placeholder implementation in `whisper-engine.cpp`

## 🎯 Dependency Installation Paths

### vcpkg (Auto-managed)
```
dependencies/vcpkg/
├── installed/x64-windows/
│   ├── include/         # Headers
│   ├── lib/            # Libraries  
│   └── bin/            # DLLs
```

### OBS Headers
```
dependencies/obs-headers/
└── obs-studio-30.0.2/
    ├── libobs/         # Core headers
    └── UI/             # UI headers
```

## ⚡ Build Variants

### Minimal Build (No external deps)
- **Command**: `.\auto-build.ps1`
- **Features**: Basic plugin structure
- **Size**: ~100 KB
- **Limitations**: No LLM or JSON features

### Standard Build (With vcpkg)
- **Command**: `.\auto-build.ps1 -UseVcpkg`  
- **Features**: Full LLM integration
- **Size**: ~2-3 MB
- **Dependencies**: libcurl, JsonCpp

### Full Build (All dependencies)
- **Command**: `.\auto-build.ps1 -SetupDependencies`
- **Features**: Everything + development headers
- **Size**: ~5 MB
- **Dependencies**: All of the above

## 🔍 Troubleshooting Dependencies

### Common Issues

**CMake not found:**
```
❌ cmake: command not found
✅ Solution: Install CMake or run auto-build script
```

**OBS headers missing:**
```
❌ obs-module.h not found  
✅ Solution: Run setup-dependencies.ps1
```

**vcpkg packages not found:**
```
❌ Could not find libcurl
✅ Solution: Run with -UseVcpkg flag
```

**Visual Studio not detected:**
```
❌ No suitable generator found
✅ Solution: Install VS Community with C++ workload
```

### Verification Commands
```powershell
# Check CMake
cmake --version

# Check Visual Studio
where msbuild

# Check vcpkg packages  
.\dependencies\vcpkg\vcpkg.exe list

# Check git
git --version
```

## 📈 Dependency Sizes

| Component | Download | Installed |
|-----------|----------|-----------|
| CMake | 45 MB | 100 MB |
| VS Build Tools | 1 GB | 3 GB |
| vcpkg | 50 MB | 200 MB |
| libcurl | 5 MB | 15 MB |
| JsonCpp | 1 MB | 3 MB |
| OBS Headers | 50 MB | 150 MB |
| **Total** | **~1.2 GB** | **~3.5 GB** |

## 🎯 Production Deployment

### Runtime Requirements (End Users)
- **OBS Studio 28.0+** (only requirement)
- **Windows 10/11 64-bit**
- **Internet connection** (for LLM APIs)

### Distribution Package
- **Plugin DLL**: ~2-3 MB
- **MSI Installer**: ~5 MB  
- **Dependencies**: Bundled or auto-installed

Users only need OBS Studio installed - all other dependencies are handled by the installer or bundled with the plugin.