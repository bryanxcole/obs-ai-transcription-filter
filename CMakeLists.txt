cmake_minimum_required(VERSION 3.16)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

project(obs-ai-transcription-filter)

# Detection for out-of-tree builds
if(CMAKE_PROJECT_NAME STREQUAL "obs-studio")
    set(BUILD_OUT_OF_TREE OFF)
else()
    set(BUILD_OUT_OF_TREE ON)
    cmake_minimum_required(VERSION 3.18)
endif()

# Find required packages
find_package(libobs REQUIRED)
find_package(obs-frontend-api REQUIRED)

# Find required libraries for AI integration
find_package(PkgConfig REQUIRED)
find_package(CURL REQUIRED)

# Add your source files
add_library(obs-ai-transcription-filter MODULE
    src/obs-ai-transcription-filter.c
    src/ai-transcription-filter.c
    src/whisper-engine.cpp
    src/llm-corrector.cpp
    src/audio-buffer.c
)

# Include directories
target_include_directories(obs-ai-transcription-filter PRIVATE
    src/
    ${CMAKE_SOURCE_DIR}/deps/whisper.cpp
)

# Link libraries
target_link_libraries(obs-ai-transcription-filter
    OBS::libobs
    CURL::libcurl
)

# Set plugin properties
set_target_properties(obs-ai-transcription-filter PROPERTIES
    FOLDER "plugins"
    PREFIX ""
)

# Install data files
if(BUILD_OUT_OF_TREE)
    install(TARGETS obs-ai-transcription-filter
        LIBRARY DESTINATION obs-plugins/64bit)
    install(DIRECTORY data/
        DESTINATION data/obs-plugins/obs-ai-transcription-filter)
endif()

# CPack configuration for MSI installer
include(InstallRequiredSystemLibraries)
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/installer/License.rtf")
set(CPACK_PACKAGE_NAME "OBS AI Transcription Filter")
set(CPACK_PACKAGE_VENDOR "Bryan Cole")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "AI-Enhanced Voice Transcription Filter for OBS Studio")
set(CPACK_PACKAGE_VERSION "1.0.0")
set(CPACK_PACKAGE_VERSION_MAJOR "1")
set(CPACK_PACKAGE_VERSION_MINOR "0")
set(CPACK_PACKAGE_VERSION_PATCH "0")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "OBS AI Transcription Filter")

# Windows-specific settings
if(WIN32)
    set(CPACK_GENERATOR "WIX")
    set(CPACK_WIX_UPGRADE_GUID "12345678-1234-1234-1234-123456789012")
    set(CPACK_WIX_PRODUCT_GUID "*")
    set(CPACK_WIX_PRODUCT_ICON "${CMAKE_CURRENT_SOURCE_DIR}/installer/icon.ico")
    set(CPACK_WIX_UI_BANNER "${CMAKE_CURRENT_SOURCE_DIR}/installer/banner.bmp")
    set(CPACK_WIX_UI_DIALOG "${CMAKE_CURRENT_SOURCE_DIR}/installer/dialog.bmp")
    
    # Custom WiX template
    set(CPACK_WIX_TEMPLATE "${CMAKE_CURRENT_SOURCE_DIR}/installer/Product.wxs")
    
    # Registry detection for OBS Studio
    set(CPACK_WIX_PROPERTY_OBSINSTALLDIR "HKEY_LOCAL_MACHINE\\SOFTWARE\\OBS Studio\\InstallPath")
endif()

include(CPack)