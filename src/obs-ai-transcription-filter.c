#include <obs-module.h>

OBS_DECLARE_MODULE()
OBS_MODULE_USE_DEFAULT_LOCALE("obs-ai-transcription-filter", "en-US")

extern struct obs_source_info ai_transcription_filter_info;

bool obs_module_load(void)
{
    obs_register_source(&ai_transcription_filter_info);
    
    blog(LOG_INFO, "AI Transcription Filter plugin loaded successfully");
    return true;
}

void obs_module_unload(void)
{
    blog(LOG_INFO, "AI Transcription Filter plugin unloaded");
}

MODULE_EXPORT const char *obs_module_description(void)
{
    return "AI-Enhanced Voice Transcription Filter for OBS Studio";
}

MODULE_EXPORT const char *obs_module_name(void)
{
    return "AI Transcription Filter";
}