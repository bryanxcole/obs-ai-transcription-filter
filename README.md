# OBS AI Transcription Filter

An advanced OBS Studio audio filter plugin that provides real-time voice transcription enhanced by Large Language Models (LLMs) for improved accuracy.

🎉 **NEW**: Zero-configuration automated build system with professional MSI installer support!

## Features

- **Real-time Audio Transcription**: Uses Whisper for speech-to-text conversion
- **AI-Enhanced Accuracy**: Leverages LLMs to correct transcription errors and improve context understanding
- **Flexible Output Options**: 
  - Direct output to OBS text sources
  - Save transcriptions to file
  - Display confidence scores
- **Customizable Settings**:
  - Adjustable silence threshold
  - Configurable transcription intervals
  - Language hints for improved accuracy
  - Custom context prompts for LLM correction

## 🚀 Quick Start

### Automated Installation (Recommended)
**One-command setup** - downloads and installs everything automatically:

```powershell
# Run as Administrator
git clone https://github.com/bryanxcole/obs-ai-transcription-filter.git
cd obs-ai-transcription-filter
.\auto-build.ps1 -SetupDependencies
```

This single command will:
- ✅ Install CMake and Visual Studio Build Tools
- ✅ Set up vcpkg package manager  
- ✅ Install all required libraries (libcurl, JsonCpp)
- ✅ Download OBS development headers
- ✅ Build the plugin with full AI functionality
- ✅ Create professional MSI installer

### Manual Installation
If you prefer manual control:

```powershell
# 1. Setup dependencies
.\setup-dependencies.ps1

# 2. Build with dependencies  
.\auto-build.ps1 -UseVcpkg

# 3. Or just build basic version
.\auto-build.ps1
```

## Requirements

### System Requirements
- **Windows 10/11 (64-bit)** - Primary platform
- **4GB+ RAM** (8GB+ recommended for LLM processing)
- **Internet connection** (for LLM API calls)
- **OBS Studio 28.0+** (runtime requirement)

### Build Dependencies (Auto-Installed)
- **CMake 3.16+** - Build system generator
- **Visual Studio 2019/2022** - C++ compiler and build tools
- **vcpkg** - C++ package manager
- **libcurl** - HTTP client for LLM APIs
- **JsonCpp** - JSON parsing library
- **Git** - For repository operations

*All dependencies are automatically downloaded and installed by the build scripts.*

## 📦 Build Options

### Available Build Scripts

| Script | Purpose | Dependencies | Output |
|--------|---------|--------------|---------|
| `auto-build.ps1 -SetupDependencies` | **Full auto-setup** | Downloads everything | Plugin DLL + MSI |
| `auto-build.ps1 -UseVcpkg` | Build with vcpkg deps | Requires setup first | Plugin DLL + MSI |
| `auto-build.ps1` | Basic build | System tools only | Plugin DLL |
| `build-msi.ps1` | MSI-focused build | Manual deps | MSI installer |
| `setup-dependencies.ps1` | Dependencies only | None | Setup environment |

### Build Outputs

**After successful build:**
```
build/
├── Release/
│   └── obs-ai-transcription-filter.dll  # Plugin for OBS
└── *.msi                                # Professional installer
```

### MSI Installer Features
- 🔧 **Automatic OBS detection** via registry
- 📁 **Proper file placement** in OBS directories  
- 🔄 **Upgrade/uninstall support** 
- 👤 **Professional UI** with license agreement
- 🛡️ **Administrator privileges** handling

## Configuration

### Basic Setup

1. Add the "AI Transcription Filter" to any audio source in OBS
2. Configure the basic settings:
   - **Enable AI Transcription**: Toggle the filter on/off
   - **Real-time Mode**: Process audio continuously vs. in batches
   - **Silence Threshold**: Minimum audio level to trigger transcription
   - **Transcription Interval**: How often to process audio (in milliseconds)

### AI Engine Configuration

1. **Whisper Model Path**: Point to your Whisper model file (.bin format)
   - Download models from the official Whisper repository
   - Larger models provide better accuracy but require more resources

2. **LLM Correction Settings**:
   - **Use LLM Correction**: Enable/disable AI-enhanced correction
   - **LLM API Endpoint**: URL for your LLM API (e.g., OpenAI GPT API)
   - **LLM API Key**: Your API authentication key
   - **Language**: Select or auto-detect the primary language
   - **Context Prompt**: Custom prompt to guide the LLM correction process

### Output Configuration

1. **Text Source Output**:
   - **Output to Text Source**: Enable to send transcriptions to an OBS text source
   - **Text Source Name**: Name of the target text source in your scene
   - **Show Confidence Score**: Display transcription confidence percentage

2. **File Output**:
   - **Save to File**: Enable to log transcriptions to a text file
   - **Output File Path**: Location for the transcription log file

## Usage Examples

### Streaming Setup
1. Add the filter to your microphone audio source
2. Create a text source for live captions
3. Configure the filter to output to your text source
4. Enable real-time mode for continuous transcription

### Recording Setup
1. Add the filter to dialogue audio tracks
2. Enable file output to create transcription logs
3. Use context prompts specific to your content type
4. Review and edit transcriptions post-recording

## API Integration

### Supported LLM APIs
- OpenAI GPT-3.5/GPT-4
- Anthropic Claude
- Local LLM servers (Ollama, etc.)
- Custom API endpoints

### Example Context Prompts

**General Purpose**:
```
Please correct any transcription errors in the following text, considering the context and improving accuracy:
```

**Gaming Stream**:
```
Correct this gaming stream transcription, focusing on game-specific terminology and slang:
```

**Educational Content**:
```
Improve this educational transcription, ensuring technical terms and concepts are accurately represented:
```

## Development Status

### ✅ Completed
- Basic OBS plugin structure
- Audio processing pipeline
- Settings UI framework
- Plugin registration and lifecycle management

### 🚧 In Progress
- Whisper.cpp integration
- LLM API communication
- Real-time transcription processing

### 📋 Planned
- Advanced silence detection
- Multiple language support
- Performance optimizations
- Pre-built binary releases

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [OBS Studio](https://obsproject.com/) for the excellent streaming platform
- [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) for efficient speech recognition
- The open-source community for various dependencies and tools

## 📚 Documentation

### Comprehensive Guides
- 📖 **[INSTALL.md](INSTALL.md)** - Detailed installation guide with troubleshooting
- 🔧 **[DEPENDENCIES.md](DEPENDENCIES.md)** - Complete dependency documentation  
- 📋 **[README.md](README.md)** - This overview document

### Build Scripts Documentation
- `auto-build.ps1` - Main automated build system
- `setup-dependencies.ps1` - Dependency management  
- `build-msi.ps1` - MSI installer creation
- `build-simple.ps1` - Simplified build for debugging

## Troubleshooting

### Quick Fixes

**Build fails with "CMake not found":**
```powershell
# Use the auto-installer
.\auto-build.ps1 -SetupDependencies
```

**PowerShell script errors:**
```powershell
# Run as Administrator and set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Plugin doesn't appear in OBS:**
- Ensure OBS Studio 28.0+ is installed
- Check that the DLL is in `obs-plugins\64bit\` folder
- Restart OBS completely
- Check OBS log files for errors

**MSI installer issues:**
- Run installer as Administrator
- Ensure OBS is closed during installation  
- Check Windows Event Viewer for detailed errors

**Poor transcription quality:**
- Try a larger Whisper model (when integrated)
- Adjust silence threshold settings
- Enable LLM correction for better results
- Improve microphone setup and audio quality

### Getting Help
1. Check the [INSTALL.md](INSTALL.md) troubleshooting section
2. Review [DEPENDENCIES.md](DEPENDENCIES.md) for dependency issues
3. Check existing GitHub issues
4. Create a new issue with:
   - Your Windows version
   - OBS Studio version  
   - Full error messages
   - Build script output

## 🗺️ Development Status & Roadmap

### ✅ Completed (Current Release)
- **Complete OBS plugin architecture** with audio filter framework
- **Professional build system** with automated dependency management
- **LLM API integration** support (OpenAI, Claude, custom endpoints)
- **MSI installer system** with OBS auto-detection
- **Comprehensive documentation** and troubleshooting guides
- **vcpkg integration** for C++ dependency management
- **Multi-platform build support** (Windows focus)

### 🚧 In Progress
- **Whisper.cpp integration** - Speech-to-text engine (placeholder implemented)
- **Real-time transcription pipeline** - Audio buffering and processing
- **UI polish** - Enhanced settings and user experience

### 📋 Planned Features
- **v1.0**: Complete Whisper integration with real-time transcription
- **v1.1**: Advanced LLM correction with multiple provider support  
- **v1.2**: Performance optimizations and memory management
- **v1.3**: Multi-language support and custom model loading
- **v2.0**: Advanced features (speaker identification, custom training)