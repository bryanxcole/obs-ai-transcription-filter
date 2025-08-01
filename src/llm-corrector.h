#pragma once

#ifdef __cplusplus
extern "C" {
#endif

void* llm_corrector_create(const char* api_endpoint, const char* api_key);
void llm_corrector_destroy(void* context);
char* llm_corrector_improve(void* context, const char* original_text, 
                           const char* context_prompt, float confidence);

#ifdef __cplusplus
}
#endif