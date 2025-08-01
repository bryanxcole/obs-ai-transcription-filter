# OBS AI Transcription Filter

An advanced OBS Studio audio filter plugin that provides real-time voice transcription enhanced by Large Language Models (LLMs) for improved accuracy.

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

## Requirements

### Dependencies
- OBS Studio 28.0+ (for plugin development)
- CMake 3.16+
- libcurl (for LLM API communication)
- JsonCpp (for JSON parsing)
- Whisper.cpp (for speech recognition) - *Not yet integrated*

### System Requirements
- Windows 10/11 (64-bit)
- Minimum 4GB RAM (8GB+ recommended for LLM processing)
- Internet connection (for LLM API calls)

## Installation

### From Source

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd obs-ai-transcription-filter
   ```

2. **Install dependencies**:
   - Install OBS Studio development libraries
   - Install libcurl development package
   - Install JsonCpp development package

3. **Build the plugin**:
   ```bash
   mkdir build
   cd build
   cmake ..
   cmake --build . --config Release
   ```

4. **Install the plugin**:
   - Copy the built plugin to your OBS plugins directory
   - Copy the data folder to the appropriate location

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

## Troubleshooting

### Common Issues

**Plugin doesn't load**:
- Verify OBS Studio version compatibility
- Check that all dependencies are installed
- Review OBS log files for error messages

**Poor transcription quality**:
- Try a larger Whisper model
- Adjust silence threshold settings
- Improve audio input quality
- Enable LLM correction for better results

**High CPU usage**:
- Use smaller Whisper models
- Increase transcription interval
- Disable real-time mode if not needed

### Support

For issues and support, please:
1. Check the troubleshooting section above
2. Review existing GitHub issues
3. Create a new issue with detailed information

## Roadmap

- **v1.0**: Core transcription functionality with Whisper integration
- **v1.1**: Enhanced LLM correction and multiple API support
- **v1.2**: Performance optimizations and additional language support
- **v2.0**: Advanced features like speaker identification and custom models