#include "audio-buffer.h"
#include <media-io/audio-math.h>
#include <util/bmem.h>
#include <math.h>

float* audio_buffer_convert_to_mono_float(struct obs_audio_data* audio, 
                                         struct audio_buffer_info* info) {
    if (!audio || !audio->data[0] || !info) {
        return NULL;
    }
    
    uint32_t channels = audio_output_get_channels(obs_get_audio());
    uint32_t frames = audio->frames;
    
    // Allocate buffer for mono float data
    float* mono_buffer = bmalloc(frames * sizeof(float));
    if (!mono_buffer) {
        return NULL;
    }
    
    // Convert based on input format
    if (info->format == AUDIO_FORMAT_FLOAT) {
        float** input_data = (float**)audio->data;
        
        if (channels == 1) {
            // Already mono, just copy
            memcpy(mono_buffer, input_data[0], frames * sizeof(float));
        } else {
            // Mix down to mono by averaging channels
            for (uint32_t i = 0; i < frames; i++) {
                float sample_sum = 0.0f;
                for (uint32_t c = 0; c < channels; c++) {
                    sample_sum += input_data[c][i];
                }
                mono_buffer[i] = sample_sum / (float)channels;
            }
        }
    } else if (info->format == AUDIO_FORMAT_16BIT) {
        int16_t** input_data = (int16_t**)audio->data;
        
        if (channels == 1) {
            // Convert 16-bit to float
            for (uint32_t i = 0; i < frames; i++) {
                mono_buffer[i] = (float)input_data[0][i] / 32768.0f;
            }
        } else {
            // Mix down and convert
            for (uint32_t i = 0; i < frames; i++) {
                float sample_sum = 0.0f;
                for (uint32_t c = 0; c < channels; c++) {
                    sample_sum += (float)input_data[c][i] / 32768.0f;
                }
                mono_buffer[i] = sample_sum / (float)channels;
            }
        }
    } else if (info->format == AUDIO_FORMAT_32BIT) {
        int32_t** input_data = (int32_t**)audio->data;
        
        if (channels == 1) {
            // Convert 32-bit to float
            for (uint32_t i = 0; i < frames; i++) {
                mono_buffer[i] = (float)input_data[0][i] / 2147483648.0f;
            }
        } else {
            // Mix down and convert
            for (uint32_t i = 0; i < frames; i++) {
                float sample_sum = 0.0f;
                for (uint32_t c = 0; c < channels; c++) {
                    sample_sum += (float)input_data[c][i] / 2147483648.0f;
                }
                mono_buffer[i] = sample_sum / (float)channels;
            }
        }
    } else {
        // Unsupported format
        bfree(mono_buffer);
        return NULL;
    }
    
    return mono_buffer;
}

void audio_buffer_apply_silence_detection(float* audio_data, size_t sample_count, 
                                         float threshold_db, bool* is_silence_out) {
    if (!audio_data || sample_count == 0 || !is_silence_out) {
        if (is_silence_out) *is_silence_out = true;
        return;
    }
    
    // Calculate RMS (Root Mean Square) of the audio
    float rms_sum = 0.0f;
    for (size_t i = 0; i < sample_count; i++) {
        float sample = audio_data[i];
        rms_sum += sample * sample;
    }
    
    float rms = sqrtf(rms_sum / (float)sample_count);
    
    // Convert RMS to dB
    float rms_db = -INFINITY;
    if (rms > 0.0f) {
        rms_db = 20.0f * log10f(rms);
    }
    
    // Check if below silence threshold
    *is_silence_out = (rms_db < threshold_db);
}