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