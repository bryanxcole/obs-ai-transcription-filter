#include "llm-corrector.h"
#include <obs-module.h>
#include <curl/curl.h>
#include <string>
#include <memory>
#include <json/json.h>

struct LLMContext {
    std::string api_endpoint;
    std::string api_key;
    CURL* curl_handle;
    bool initialized;
};

struct LLMResponse {
    std::string data;
    long response_code;
};

static size_t llm_write_callback(void* contents, size_t size, size_t nmemb, LLMResponse* response) {
    size_t total_size = size * nmemb;
    response->data.append(static_cast<char*>(contents), total_size);
    return total_size;
}

extern "C" {

void* llm_corrector_create(const char* api_endpoint, const char* api_key) {
    if (!api_endpoint || !api_key || strlen(api_endpoint) == 0 || strlen(api_key) == 0) {
        blog(LOG_ERROR, "LLM Corrector: Invalid API endpoint or key");
        return nullptr;
    }
    
    auto context = std::make_unique<LLMContext>();
    context->api_endpoint = std::string(api_endpoint);
    context->api_key = std::string(api_key);
    context->initialized = false;
    
    // Initialize libcurl
    context->curl_handle = curl_easy_init();
    if (!context->curl_handle) {
        blog(LOG_ERROR, "LLM Corrector: Failed to initialize CURL");
        return nullptr;
    }
    
    // Set basic CURL options
    curl_easy_setopt(context->curl_handle, CURLOPT_TIMEOUT, 30L);
    curl_easy_setopt(context->curl_handle, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(context->curl_handle, CURLOPT_WRITEFUNCTION, llm_write_callback);
    
    blog(LOG_INFO, "LLM Corrector: Created with endpoint: %s", api_endpoint);
    context->initialized = true;
    
    return context.release();
}

void llm_corrector_destroy(void* ctx) {
    if (!ctx) return;
    
    LLMContext* context = static_cast<LLMContext*>(ctx);
    
    if (context->curl_handle) {
        curl_easy_cleanup(context->curl_handle);
    }
    
    blog(LOG_INFO, "LLM Corrector: Destroyed");
    delete context;
}

char* llm_corrector_improve(void* ctx, const char* original_text, 
                           const char* context_prompt, float confidence) {
    if (!ctx || !original_text || strlen(original_text) == 0) {
        return nullptr;
    }
    
    LLMContext* context = static_cast<LLMContext*>(ctx);
    if (!context->initialized) {
        blog(LOG_ERROR, "LLM Corrector: Not initialized");
        return nullptr;
    }
    
    // Skip correction if confidence is already high
    if (confidence > 0.95f) {
        blog(LOG_DEBUG, "LLM Corrector: Skipping correction, confidence too high: %.2f", confidence);
        return strdup(original_text);
    }
    
    try {
        // Prepare JSON payload for LLM API
        Json::Value json_data;
        Json::Value messages(Json::arrayValue);
        
        // System message
        Json::Value system_msg;
        system_msg["role"] = "system";
        system_msg["content"] = context_prompt ? context_prompt : 
            "You are a helpful assistant that corrects transcription errors. "
            "Return only the corrected text without explanations.";
        messages.append(system_msg);
        
        // User message with transcription
        Json::Value user_msg;
        user_msg["role"] = "user";
        user_msg["content"] = std::string("Please correct any errors in this transcription: \"") + 
                             original_text + "\"";
        messages.append(user_msg);
        
        json_data["model"] = "gpt-3.5-turbo"; // Default model
        json_data["messages"] = messages;
        json_data["max_tokens"] = 150;
        json_data["temperature"] = 0.3;
        
        Json::StreamWriterBuilder builder;
        std::string json_string = Json::writeString(builder, json_data);
        
        // Set up CURL request
        struct curl_slist* headers = nullptr;
        std::string auth_header = "Authorization: Bearer " + context->api_key;
        headers = curl_slist_append(headers, "Content-Type: application/json");
        headers = curl_slist_append(headers, auth_header.c_str());
        
        LLMResponse response;
        
        curl_easy_setopt(context->curl_handle, CURLOPT_URL, context->api_endpoint.c_str());
        curl_easy_setopt(context->curl_handle, CURLOPT_POSTFIELDS, json_string.c_str());
        curl_easy_setopt(context->curl_handle, CURLOPT_HTTPHEADER, headers);
        curl_easy_setopt(context->curl_handle, CURLOPT_WRITEDATA, &response);
        
        // Perform the request
        CURLcode curl_result = curl_easy_perform(context->curl_handle);
        curl_slist_free_all(headers);
        
        if (curl_result != CURLE_OK) {
            blog(LOG_ERROR, "LLM Corrector: CURL request failed: %s", 
                 curl_easy_strerror(curl_result));
            return strdup(original_text); // Return original on error
        }
        
        curl_easy_getinfo(context->curl_handle, CURLINFO_RESPONSE_CODE, &response.response_code);
        
        if (response.response_code != 200) {
            blog(LOG_ERROR, "LLM Corrector: API request failed with code: %ld", 
                 response.response_code);
            return strdup(original_text);
        }
        
        // Parse JSON response
        Json::Value json_response;
        Json::CharReaderBuilder reader_builder;
        std::string errors;
        
        std::istringstream response_stream(response.data);
        if (!Json::parseFromStream(reader_builder, response_stream, &json_response, &errors)) {
            blog(LOG_ERROR, "LLM Corrector: Failed to parse JSON response: %s", errors.c_str());
            return strdup(original_text);
        }
        
        // Extract corrected text
        if (json_response.isMember("choices") && json_response["choices"].isArray() &&
            json_response["choices"].size() > 0) {
            
            const Json::Value& choice = json_response["choices"][0];
            if (choice.isMember("message") && choice["message"].isMember("content")) {
                std::string corrected_text = choice["message"]["content"].asString();
                
                // Clean up the response (remove quotes, trim whitespace)
                if (corrected_text.front() == '"' && corrected_text.back() == '"') {
                    corrected_text = corrected_text.substr(1, corrected_text.length() - 2);
                }
                
                // Trim whitespace
                corrected_text.erase(0, corrected_text.find_first_not_of(" \t\n\r"));
                corrected_text.erase(corrected_text.find_last_not_of(" \t\n\r") + 1);
                
                if (!corrected_text.empty() && corrected_text != original_text) {
                    blog(LOG_INFO, "LLM Corrector: '%s' -> '%s'", original_text, corrected_text.c_str());
                    return strdup(corrected_text.c_str());
                }
            }
        }
        
        blog(LOG_DEBUG, "LLM Corrector: No correction needed or invalid response");
        return strdup(original_text);
        
    } catch (const std::exception& e) {
        blog(LOG_ERROR, "LLM Corrector: Exception occurred: %s", e.what());
        return strdup(original_text);
    }
}

} // extern "C"