# Installation Guide - OBS AI Transcription Filter

This guide covers how to build and install the OBS AI Transcription Filter plugin.

## Prerequisites

### Required Software
1. **OBS Studio 28.0+** - Download from [obsproject.com](https://obsproject.com/)
2. **Visual Studio 2019/2022** - Community edition is sufficient
   - Install with "Desktop development with C++" workload
3. **CMake 3.16+** - Download from [cmake.org](https://cmake.org/download/)
4. **WiX Toolset v3.11+** - Download from [GitHub](https://github.com/wixtoolset/wix3/releases)
   - Required only for MSI installer creation

### Optional Dependencies (for full functionality)
- **Whisper.cpp** - For actual speech recognition
- **libcurl** - For LLM API communication  
- **JsonCpp** - For JSON parsing

## Building the Plugin

### Method 1: Automated Build (Recommended)

1. **Clone the repository**:
   ```powershell
   git clone https://github.com/bryanxcole/obs-ai-transcription-filter.git
   cd obs-ai-transcription-filter
   ```

2. **Run the build script**:
   ```powershell
   .\build-msi.ps1
   ```

   Or with custom OBS path:
   ```powershell
   .\build-msi.ps1 -OBSPath "D:\OBS Studio"
   ```

3. **Install the MSI package**:
   - Run the generated `.msi` file as Administrator
   - The installer will automatically detect OBS and install the plugin

### Method 2: Manual Build

1. **Create build directory**:
   ```cmd
   mkdir build
   cd build
   ```

2. **Configure with CMake**:
   ```cmd
   cmake .. -G "Visual Studio 17 2022" -A x64
   ```

3. **Build the project**:
   ```cmd
   cmake --build . --config Release
   ```

4. **Create MSI (optional)**:
   ```cmd
   cpack -G WIX -C Release
   ```

## Manual Installation

If you prefer to install without the MSI installer:

1. **Copy the plugin DLL**:
   ```
   build\Release\obs-ai-transcription-filter.dll
   → C:\Program Files\obs-studio\obs-plugins\64bit\
   ```

2. **Copy the locale file**:
   ```
   data\locale\en-US.ini
   → C:\Program Files\obs-studio\data\obs-plugins\obs-ai-transcription-filter\locale\
   ```

3. **Restart OBS Studio**

## Verifying Installation

1. Open OBS Studio
2. Right-click on any audio source
3. Select "Filters"
4. Click the "+" button
5. Look for "AI Transcription Filter" in the list

If the filter appears, installation was successful!

## Configuration

### Basic Setup
1. Add the filter to your microphone or audio source
2. Enable "Enable AI Transcription"
3. Configure basic settings:
   - **Real-time Mode**: For live streaming
   - **Silence Threshold**: Adjust based on your environment
   - **Transcription Interval**: How often to process audio

### AI Engine Setup
1. **Whisper Model Path**: Download a Whisper model (.bin file)
2. **LLM Correction**: Configure API endpoint and key for enhanced accuracy
3. **Language**: Select your primary language
4. **Context Prompt**: Customize for your content type

### Output Configuration
1. **Text Source Output**: Create a text source for live captions
2. **File Output**: Save transcriptions to a log file
3. **Confidence Display**: Show transcription accuracy

## Troubleshooting

### Plugin Not Loading
- Check OBS log files for error messages
- Ensure all dependencies are installed
- Verify plugin DLL is in correct location
- Run OBS as Administrator if needed

### Build Errors
- Ensure Visual Studio has C++ support installed
- Check that CMake is in your PATH
- Verify OBS development headers are available

### MSI Creation Fails
- Install WiX Toolset and ensure it's in PATH
- Run build script as Administrator
- Check Windows Event Viewer for detailed errors

### Poor Transcription Quality
- Try a larger Whisper model
- Adjust silence threshold
- Enable LLM correction
- Improve microphone setup and audio quality

## Development Dependencies

For developers wanting to extend the plugin:

### Whisper.cpp Integration
```bash
git clone https://github.com/ggerganov/whisper.cpp.git
cd whisper.cpp
mkdir build && cd build
cmake .. -DBUILD_SHARED_LIBS=ON
cmake --build . --config Release
```

### libcurl
```bash
# Install vcpkg first
vcpkg install curl[core,ssl]:x64-windows
```

### JsonCpp
```bash
vcpkg install jsoncpp:x64-windows
```

## Uninstallation

### Via MSI
- Use "Add or Remove Programs" in Windows Settings
- Find "OBS AI Transcription Filter" and uninstall

### Manual Removal
1. Delete plugin DLL from OBS plugins folder
2. Delete data folder from OBS data directory
3. Restart OBS Studio

## Support

For issues and support:
1. Check this installation guide
2. Review the [README.md](README.md) file
3. Check existing GitHub issues
4. Create a new issue with detailed information

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.