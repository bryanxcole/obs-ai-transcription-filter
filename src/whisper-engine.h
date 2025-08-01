#pragma once

#ifdef __cplusplus
extern "C" {
#endif

void* whisper_engine_create(const char* model_path);
void whisper_engine_destroy(void* context);
char* whisper_engine_transcribe(void* context, const float* audio_data, 
                               size_t sample_count, const char* language_hint, 
                               float* confidence_out);

#ifdef __cplusplus
}
#endif