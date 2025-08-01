#pragma once

#include <obs-module.h>

struct audio_buffer_info {
    uint32_t sample_rate;
    uint32_t channels;
    enum audio_format format;
};

float* audio_buffer_convert_to_mono_float(struct obs_audio_data* audio, 
                                         struct audio_buffer_info* info);
void audio_buffer_apply_silence_detection(float* audio_data, size_t sample_count, 
                                         float threshold_db, bool* is_silence_out);