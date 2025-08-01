#include <obs-module.h>
#include <media-io/audio-math.h>
#include <util/threading.h>
#include <util/circlebuf.h>
#include <pthread.h>
#include "whisper-engine.h"
#include "llm-corrector.h"
#include "audio-buffer.h"

#define TRANSCRIPTION_BUFFER_SIZE (48000 * 4) // 4 seconds at 48kHz
#define MIN_TRANSCRIPTION_LENGTH (48000 * 1)  // 1 second minimum

struct ai_transcription_data {
    obs_source_t *context;
    
    // Audio processing
    struct circlebuf audio_buffer;
    struct audio_buffer_info buffer_info;
    pthread_mutex_t buffer_mutex;
    
    // Transcription settings
    bool enabled;
    bool real_time_mode;
    float silence_threshold;
    int transcription_interval_ms;
    
    // AI settings  
    bool use_llm_correction;
    char *whisper_model_path;
    char *llm_api_endpoint;
    char *llm_api_key;
    char *language_hint;
    char *context_prompt;
    
    // Output settings
    bool output_to_text_source;
    char *text_source_name;
    bool save_to_file;
    char *output_file_path;
    bool show_confidence;
    
    // Processing thread
    pthread_t transcription_thread;
    bool thread_running;
    bool stop_thread;
    
    // Transcription engines
    void *whisper_context;
    void *llm_context;
    
    // Statistics
    uint64_t total_transcribed_frames;
    uint64_t last_transcription_time;
    float last_confidence;
};

static const char *ai_transcription_get_name(void *unused)
{
    UNUSED_PARAMETER(unused);
    return obs_module_text("AI Transcription Filter");
}

static void ai_transcription_destroy(void *data)
{
    struct ai_transcription_data *filter = data;
    
    if (filter->thread_running) {
        filter->stop_thread = true;
        pthread_join(filter->transcription_thread, NULL);
    }
    
    pthread_mutex_destroy(&filter->buffer_mutex);
    circlebuf_free(&filter->audio_buffer);
    
    // Cleanup AI contexts
    if (filter->whisper_context) {
        whisper_engine_destroy(filter->whisper_context);
    }
    if (filter->llm_context) {
        llm_corrector_destroy(filter->llm_context);
    }
    
    // Free strings
    bfree(filter->whisper_model_path);
    bfree(filter->llm_api_endpoint);
    bfree(filter->llm_api_key);
    bfree(filter->language_hint);
    bfree(filter->context_prompt);
    bfree(filter->text_source_name);
    bfree(filter->output_file_path);
    
    bfree(filter);
}

static void *transcription_thread_worker(void *data)
{
    struct ai_transcription_data *filter = data;
    
    blog(LOG_INFO, "AI Transcription thread started");
    
    while (!filter->stop_thread) {
        if (!filter->enabled) {
            os_sleep_ms(100);
            continue;
        }
        
        pthread_mutex_lock(&filter->buffer_mutex);
        
        // Check if we have enough audio data to transcribe
        size_t buffer_size = filter->audio_buffer.size;
        if (buffer_size < MIN_TRANSCRIPTION_LENGTH * sizeof(float)) {
            pthread_mutex_unlock(&filter->buffer_mutex);
            os_sleep_ms(filter->transcription_interval_ms);
            continue;
        }
        
        // Extract audio data for transcription
        float *audio_data = bmalloc(buffer_size);
        circlebuf_peek_front(&filter->audio_buffer, audio_data, buffer_size);
        size_t sample_count = buffer_size / sizeof(float);
        
        pthread_mutex_unlock(&filter->buffer_mutex);
        
        // Perform transcription with Whisper
        char *transcription = NULL;
        float confidence = 0.0f;
        
        if (filter->whisper_context) {
            transcription = whisper_engine_transcribe(
                filter->whisper_context,
                audio_data,
                sample_count,
                filter->language_hint,
                &confidence
            );
        }
        
        // Apply LLM correction if enabled and transcription exists
        if (transcription && filter->use_llm_correction && filter->llm_context) {
            char *corrected_text = llm_corrector_improve(
                filter->llm_context,
                transcription,
                filter->context_prompt,
                confidence
            );
            
            if (corrected_text) {
                bfree(transcription);
                transcription = corrected_text;
            }
        }
        
        // Output transcription
        if (transcription && strlen(transcription) > 0) {
            filter->last_confidence = confidence;
            filter->last_transcription_time = os_gettime_ns();
            
            // Update text source if specified
            if (filter->output_to_text_source && filter->text_source_name) {
                obs_source_t *text_source = obs_get_source_by_name(filter->text_source_name);
                if (text_source) {
                    obs_data_t *settings = obs_data_create();
                    
                    if (filter->show_confidence) {
                        char *text_with_confidence = bmalloc(strlen(transcription) + 50);
                        snprintf(text_with_confidence, strlen(transcription) + 50, 
                                "%s (%.1f%%)", transcription, confidence * 100.0f);
                        obs_data_set_string(settings, "text", text_with_confidence);
                        bfree(text_with_confidence);
                    } else {
                        obs_data_set_string(settings, "text", transcription);
                    }
                    
                    obs_source_update(text_source, settings);
                    obs_data_release(settings);
                    obs_source_release(text_source);
                }
            }
            
            // Save to file if enabled
            if (filter->save_to_file && filter->output_file_path) {
                FILE *file = fopen(filter->output_file_path, "a");
                if (file) {
                    fprintf(file, "[%llu] %s\n", 
                           (unsigned long long)filter->last_transcription_time, 
                           transcription);
                    fclose(file);
                }
            }
            
            blog(LOG_INFO, "Transcription (%.1f%%): %s", confidence * 100.0f, transcription);
        }
        
        bfree(audio_data);
        bfree(transcription);
        
        // Clear processed audio from buffer in real-time mode
        if (filter->real_time_mode) {
            pthread_mutex_lock(&filter->buffer_mutex);
            circlebuf_pop_front(&filter->audio_buffer, NULL, 
                               MIN_TRANSCRIPTION_LENGTH * sizeof(float));
            pthread_mutex_unlock(&filter->buffer_mutex);
        }
        
        os_sleep_ms(filter->transcription_interval_ms);
    }
    
    blog(LOG_INFO, "AI Transcription thread stopped");
    return NULL;
}

static void *ai_transcription_create(obs_data_t *settings, obs_source_t *source)
{
    struct ai_transcription_data *filter = bzalloc(sizeof(struct ai_transcription_data));
    filter->context = source;
    
    // Initialize audio buffer
    circlebuf_init(&filter->audio_buffer);
    circlebuf_reserve(&filter->audio_buffer, TRANSCRIPTION_BUFFER_SIZE * sizeof(float));
    pthread_mutex_init(&filter->buffer_mutex, NULL);
    
    // Initialize buffer info
    filter->buffer_info.sample_rate = 48000;
    filter->buffer_info.channels = 1; // Mono for transcription
    filter->buffer_info.format = AUDIO_FORMAT_FLOAT;
    
    // Apply initial settings
    ai_transcription_update(filter, settings);
    
    // Start transcription thread
    filter->thread_running = true;
    filter->stop_thread = false;
    pthread_create(&filter->transcription_thread, NULL, transcription_thread_worker, filter);
    
    blog(LOG_INFO, "AI Transcription Filter created");
    return filter;
}

static void ai_transcription_update(void *data, obs_data_t *settings)
{
    struct ai_transcription_data *filter = data;
    
    // Update settings
    filter->enabled = obs_data_get_bool(settings, "enabled");
    filter->real_time_mode = obs_data_get_bool(settings, "real_time_mode");
    filter->silence_threshold = (float)obs_data_get_double(settings, "silence_threshold");
    filter->transcription_interval_ms = (int)obs_data_get_int(settings, "transcription_interval_ms");
    
    // AI settings
    filter->use_llm_correction = obs_data_get_bool(settings, "use_llm_correction");
    
    const char *whisper_model = obs_data_get_string(settings, "whisper_model_path");
    if (whisper_model && strlen(whisper_model) > 0) {
        bfree(filter->whisper_model_path);
        filter->whisper_model_path = bstrdup(whisper_model);
        
        // Reinitialize Whisper if model changed
        if (filter->whisper_context) {
            whisper_engine_destroy(filter->whisper_context);
        }
        filter->whisper_context = whisper_engine_create(filter->whisper_model_path);
    }
    
    const char *llm_endpoint = obs_data_get_string(settings, "llm_api_endpoint");
    if (llm_endpoint) {
        bfree(filter->llm_api_endpoint);
        filter->llm_api_endpoint = bstrdup(llm_endpoint);
    }
    
    const char *llm_key = obs_data_get_string(settings, "llm_api_key");
    if (llm_key) {
        bfree(filter->llm_api_key);
        filter->llm_api_key = bstrdup(llm_key);
    }
    
    const char *language = obs_data_get_string(settings, "language_hint");
    if (language) {
        bfree(filter->language_hint);
        filter->language_hint = bstrdup(language);
    }
    
    const char *context = obs_data_get_string(settings, "context_prompt");
    if (context) {
        bfree(filter->context_prompt);
        filter->context_prompt = bstrdup(context);
    }
    
    // Update LLM context if needed
    if (filter->use_llm_correction && filter->llm_api_endpoint && filter->llm_api_key) {
        if (filter->llm_context) {
            llm_corrector_destroy(filter->llm_context);
        }
        filter->llm_context = llm_corrector_create(filter->llm_api_endpoint, filter->llm_api_key);
    }
    
    // Output settings
    filter->output_to_text_source = obs_data_get_bool(settings, "output_to_text_source");
    
    const char *text_source = obs_data_get_string(settings, "text_source_name");
    if (text_source) {
        bfree(filter->text_source_name);
        filter->text_source_name = bstrdup(text_source);
    }
    
    filter->save_to_file = obs_data_get_bool(settings, "save_to_file");
    
    const char *output_file = obs_data_get_string(settings, "output_file_path");
    if (output_file) {
        bfree(filter->output_file_path);
        filter->output_file_path = bstrdup(output_file);
    }
    
    filter->show_confidence = obs_data_get_bool(settings, "show_confidence");
}

static struct obs_audio_data *ai_transcription_filter_audio(void *data, struct obs_audio_data *audio)
{
    struct ai_transcription_data *filter = data;
    
    if (!filter->enabled || !audio || !audio->data[0]) {
        return audio;
    }
    
    // Convert audio to mono float format for transcription
    float *mono_data = audio_buffer_convert_to_mono_float(audio, &filter->buffer_info);
    if (!mono_data) {
        return audio;
    }
    
    // Add to circular buffer for transcription processing
    pthread_mutex_lock(&filter->buffer_mutex);
    
    size_t data_size = audio->frames * sizeof(float);
    
    // Ensure buffer doesn't overflow
    while (filter->audio_buffer.size + data_size > TRANSCRIPTION_BUFFER_SIZE * sizeof(float)) {
        // Remove oldest data to make room
        circlebuf_pop_front(&filter->audio_buffer, NULL, data_size);
    }
    
    circlebuf_push_back(&filter->audio_buffer, mono_data, data_size);
    filter->total_transcribed_frames += audio->frames;
    
    pthread_mutex_unlock(&filter->buffer_mutex);
    
    bfree(mono_data);
    
    // Pass through original audio unchanged
    return audio;
}

static obs_properties_t *ai_transcription_properties(void *data)
{
    UNUSED_PARAMETER(data);
    
    obs_properties_t *props = obs_properties_create();
    
    // Basic settings
    obs_properties_add_bool(props, "enabled", "Enable AI Transcription");
    obs_properties_add_bool(props, "real_time_mode", "Real-time Mode");
    
    obs_property_t *silence_prop = obs_properties_add_float_slider(props,
        "silence_threshold", "Silence Threshold", -60.0, 0.0, 0.1);
    obs_property_float_set_suffix(silence_prop, " dB");
    
    obs_properties_add_int(props, "transcription_interval_ms", "Transcription Interval (ms)", 
                          500, 5000, 100);
    
    // AI Engine settings
    obs_properties_t *ai_group = obs_properties_create();
    obs_properties_add_group(props, "ai_settings", "AI Settings", OBS_GROUP_NORMAL, ai_group);
    
    obs_properties_add_path(ai_group, "whisper_model_path", "Whisper Model Path", 
                           OBS_PATH_FILE, "Model files (*.bin)", NULL);
    
    obs_properties_add_bool(ai_group, "use_llm_correction", "Use LLM Correction");
    obs_properties_add_text(ai_group, "llm_api_endpoint", "LLM API Endpoint", OBS_TEXT_DEFAULT);
    obs_properties_add_text(ai_group, "llm_api_key", "LLM API Key", OBS_TEXT_PASSWORD);
    
    obs_property_t *lang_prop = obs_properties_add_list(ai_group, "language_hint", "Language",
        OBS_COMBO_TYPE_LIST, OBS_COMBO_FORMAT_STRING);
    obs_property_list_add_string(lang_prop, "Auto Detect", "auto");
    obs_property_list_add_string(lang_prop, "English", "en");
    obs_property_list_add_string(lang_prop, "Spanish", "es");
    obs_property_list_add_string(lang_prop, "French", "fr");
    obs_property_list_add_string(lang_prop, "German", "de");
    obs_property_list_add_string(lang_prop, "Chinese", "zh");
    
    obs_properties_add_text(ai_group, "context_prompt", "Context Prompt", OBS_TEXT_MULTILINE);
    
    // Output settings
    obs_properties_t *output_group = obs_properties_create();
    obs_properties_add_group(props, "output_settings", "Output Settings", OBS_GROUP_NORMAL, output_group);
    
    obs_properties_add_bool(output_group, "output_to_text_source", "Output to Text Source");
    obs_properties_add_text(output_group, "text_source_name", "Text Source Name", OBS_TEXT_DEFAULT);
    obs_properties_add_bool(output_group, "show_confidence", "Show Confidence Score");
    
    obs_properties_add_bool(output_group, "save_to_file", "Save to File");
    obs_properties_add_path(output_group, "output_file_path", "Output File Path", 
                           OBS_PATH_FILE_SAVE, "Text files (*.txt)", NULL);
    
    return props;
}

static void ai_transcription_defaults(obs_data_t *settings)
{
    obs_data_set_default_bool(settings, "enabled", false);
    obs_data_set_default_bool(settings, "real_time_mode", true);
    obs_data_set_default_double(settings, "silence_threshold", -40.0);
    obs_data_set_default_int(settings, "transcription_interval_ms", 1000);
    
    obs_data_set_default_bool(settings, "use_llm_correction", false);
    obs_data_set_default_string(settings, "language_hint", "auto");
    obs_data_set_default_string(settings, "context_prompt", 
        "Please correct any transcription errors in the following text, "
        "considering the context and improving accuracy:");
    
    obs_data_set_default_bool(settings, "output_to_text_source", false);
    obs_data_set_default_bool(settings, "show_confidence", true);
    obs_data_set_default_bool(settings, "save_to_file", false);
}

struct obs_source_info ai_transcription_filter_info = {
    .id = "ai_transcription_filter",
    .type = OBS_SOURCE_TYPE_FILTER,
    .output_flags = OBS_SOURCE_AUDIO,
    .get_name = ai_transcription_get_name,
    .create = ai_transcription_create,
    .destroy = ai_transcription_destroy,
    .update = ai_transcription_update,
    .get_properties = ai_transcription_properties,
    .get_defaults = ai_transcription_defaults,
    .filter_audio = ai_transcription_filter_audio,
};