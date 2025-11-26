//! src/configs/include/llama_wrapper.c - Implementation of LLaMA wrapper functions

#include "llama_wrapper.h"
#include "llama.h"
#include "ggml.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

// Internal structure implementations
struct llama_wrapper_model_t {
    struct llama_model* model;
    bool is_valid;
    char* model_path;
};

struct llama_wrapper_context_t {
    struct llama_context* ctx;
    bool is_valid;
    llama_wrapper_model_t* model;
    const struct llama_vocab* vocab;
};

struct llama_wrapper_tokens_t {
    llama_token* tokens;
    size_t count;
    size_t capacity;
};

// Helper function to convert our params to LLaMA params
static struct llama_model_params convert_model_params(const llama_wrapper_params_t* params) {
    struct llama_model_params model_params = llama_model_default_params();
    
    model_params.use_mmap = params->use_mmap;
    model_params.use_mlock = params->use_mlock;
    
    return model_params;
}

static struct llama_context_params convert_context_params(const llama_wrapper_params_t* params) {
    struct llama_context_params ctx_params = llama_context_default_params();
    
    ctx_params.n_ctx = params->n_ctx;
    ctx_params.n_batch = params->n_batch;
    ctx_params.n_threads = params->n_threads;
    ctx_params.n_threads_batch = params->n_threads;
    ctx_params.seed = params->seed;
    
    return ctx_params;
}

// Model management functions
llama_wrapper_error_t llama_wrapper_model_load(
    const char* model_path,
    const llama_wrapper_params_t* params,
    llama_wrapper_model_t** out_model
) {
    if (!model_path || !params || !out_model) {
        return LLAMA_WRAPPER_ERROR_NULL_POINTER;
    }
    
    // Initialize backend
    llama_backend_init();
    
    // Convert parameters
    struct llama_model_params model_params = convert_model_params(params);
    
    // Load model
    struct llama_model* model = llama_model_load_from_file(model_path, model_params);
    if (!model) {
        return LLAMA_WRAPPER_ERROR_FILE_NOT_FOUND;
    }
    
    // Create wrapper
    llama_wrapper_model_t* wrapper = malloc(sizeof(llama_wrapper_model_t));
    if (!wrapper) {
        llama_model_free(model);
        return LLAMA_WRAPPER_ERROR_OUT_OF_MEMORY;
    }
    
    wrapper->model = model;
    wrapper->is_valid = true;
    wrapper->model_path = malloc(strlen(model_path) + 1);
    if (wrapper->model_path) {
        strcpy(wrapper->model_path, model_path);
    }
    
    *out_model = wrapper;
    return LLAMA_WRAPPER_OK;
}

llama_wrapper_error_t llama_wrapper_model_free(llama_wrapper_model_t* model) {
    if (!model) {
        return LLAMA_WRAPPER_ERROR_NULL_POINTER;
    }
    
    if (model->is_valid && model->model) {
        llama_model_free(model->model);
    }
    
    if (model->model_path) {
        free(model->model_path);
    }
    
    model->is_valid = false;
    free(model);
    
    return LLAMA_WRAPPER_OK;
}

llama_wrapper_error_t llama_wrapper_context_new(
    llama_wrapper_model_t* model,
    const llama_wrapper_params_t* params,
    llama_wrapper_context_t** out_context
) {
    if (!model || !params || !out_context || !model->is_valid) {
        return LLAMA_WRAPPER_ERROR_INVALID_MODEL;
    }
    
    // Convert parameters
    struct llama_context_params ctx_params = convert_context_params(params);
    
    // Create context
    struct llama_context* ctx = llama_init_from_model(model->model, ctx_params);
    if (!ctx) {
        return LLAMA_WRAPPER_ERROR_INVALID_CONTEXT;
    }
    
    // Create wrapper
    llama_wrapper_context_t* wrapper = malloc(sizeof(llama_wrapper_context_t));
    if (!wrapper) {
        llama_free(ctx);
        return LLAMA_WRAPPER_ERROR_OUT_OF_MEMORY;
    }
    
    wrapper->ctx = ctx;
    wrapper->is_valid = true;
    wrapper->model = model;
    wrapper->vocab = llama_model_get_vocab(model->model);
    
    *out_context = wrapper;
    return LLAMA_WRAPPER_OK;
}

llama_wrapper_error_t llama_wrapper_context_free(llama_wrapper_context_t* ctx) {
    if (!ctx) {
        return LLAMA_WRAPPER_ERROR_NULL_POINTER;
    }
    
    if (ctx->is_valid && ctx->ctx) {
        llama_free(ctx->ctx);
    }
    
    ctx->is_valid = false;
    free(ctx);
    
    return LLAMA_WRAPPER_OK;
}

// Tokenization functions
llama_wrapper_error_t llama_wrapper_tokenize(
    llama_wrapper_context_t* ctx,
    const char* text,
    bool add_bos,
    llama_wrapper_tokens_t** out_tokens
) {
    if (!ctx || !text || !out_tokens || !ctx->is_valid || !ctx->vocab) {
        return LLAMA_WRAPPER_ERROR_NULL_POINTER;
    }
    
    // Estimate token count (conservative)
    size_t text_len = strlen(text);
    size_t max_tokens = text_len + 10; // rough estimate
    
    // Allocate token buffer
    llama_token* tokens = malloc(max_tokens * sizeof(llama_token));
    if (!tokens) {
        return LLAMA_WRAPPER_ERROR_OUT_OF_MEMORY;
    }
    
    // Tokenize
    int32_t n_tokens = llama_tokenize(ctx->vocab, text, text_len, tokens, max_tokens, add_bos, false);
    
    if (n_tokens < 0) {
        free(tokens);
        return LLAMA_WRAPPER_ERROR_TOKENIZATION_FAILED;
    }
    
    // Create wrapper
    llama_wrapper_tokens_t* wrapper = malloc(sizeof(llama_wrapper_tokens_t));
    if (!wrapper) {
        free(tokens);
        return LLAMA_WRAPPER_ERROR_OUT_OF_MEMORY;
    }
    
    // Reallocate to exact size
    wrapper->tokens = realloc(tokens, n_tokens * sizeof(llama_token));
    if (!wrapper->tokens && n_tokens > 0) {
        free(tokens);
        free(wrapper);
        return LLAMA_WRAPPER_ERROR_OUT_OF_MEMORY;
    }
    
    wrapper->count = n_tokens;
    wrapper->capacity = n_tokens;
    
    *out_tokens = wrapper;
    return LLAMA_WRAPPER_OK;
}

llama_wrapper_error_t llama_wrapper_detokenize(
    llama_wrapper_context_t* ctx,
    const llama_wrapper_tokens_t* tokens,
    char** out_text
) {
    if (!ctx || !tokens || !out_text || !ctx->is_valid || !ctx->vocab) {
        return LLAMA_WRAPPER_ERROR_NULL_POINTER;
    }
    
    if (tokens->count == 0) {
        *out_text = malloc(1);
        if (*out_text) {
            (*out_text)[0] = '\0';
            return LLAMA_WRAPPER_OK;
        } else {
            return LLAMA_WRAPPER_ERROR_OUT_OF_MEMORY;
        }
    }
    
    // Estimate text length
    size_t max_text_len = tokens->count * 10; // rough estimate
    char* text_buffer = malloc(max_text_len);
    if (!text_buffer) {
        return LLAMA_WRAPPER_ERROR_OUT_OF_MEMORY;
    }
    
    // Detokenize
    int32_t text_len = llama_detokenize(ctx->vocab, tokens->tokens, tokens->count, text_buffer, max_text_len, false, true);
    
    if (text_len < 0) {
        free(text_buffer);
        return LLAMA_WRAPPER_ERROR_TOKENIZATION_FAILED;
    }
    
    // Reallocate to exact size
    char* final_text = realloc(text_buffer, text_len + 1);
    if (!final_text && text_len > 0) {
        free(text_buffer);
        return LLAMA_WRAPPER_ERROR_OUT_OF_MEMORY;
    }
    
    final_text[text_len] = '\0';
    *out_text = final_text;
    
    return LLAMA_WRAPPER_OK;
}

llama_wrapper_error_t llama_wrapper_tokens_free(llama_wrapper_tokens_t* tokens) {
    if (!tokens) {
        return LLAMA_WRAPPER_ERROR_NULL_POINTER;
    }
    
    if (tokens->tokens) {
        free(tokens->tokens);
    }
    free(tokens);
    
    return LLAMA_WRAPPER_OK;
}

// Generation functions
llama_wrapper_error_t llama_wrapper_generate(
    llama_wrapper_context_t* ctx,
    const llama_wrapper_tokens_t* input_tokens,
    const llama_wrapper_params_t* params,
    char** out_text
) {
    if (!ctx || !input_tokens || !params || !out_text || !ctx->is_valid) {
        return LLAMA_WRAPPER_ERROR_NULL_POINTER;
    }
    
    // Create batch for input tokens
    struct llama_batch batch = llama_batch_get_one(input_tokens->tokens, input_tokens->count);
    
    // Process input tokens
    if (llama_decode(ctx->ctx, batch) != 0) {
        return LLAMA_WRAPPER_ERROR_GENERATION_FAILED;
    }
    
    // Generate tokens
    size_t max_output_len = params->max_tokens * 10; // rough estimate for text length
    char* output_buffer = malloc(max_output_len);
    if (!output_buffer) {
        return LLAMA_WRAPPER_ERROR_OUT_OF_MEMORY;
    }
    
    size_t output_pos = 0;
    
    for (int32_t i = 0; i < params->max_tokens; i++) {
        // Get logits
        float* logits = llama_get_logits_ith(ctx->ctx, -1);
        if (!logits) {
            free(output_buffer);
            return LLAMA_WRAPPER_ERROR_GENERATION_FAILED;
        }
        
        // Simple greedy sampling for now
        int32_t vocab_size = llama_vocab_n_tokens(ctx->vocab);
        llama_token next_token = 0;
        float max_logit = logits[0];
        
        for (int32_t j = 1; j < vocab_size; j++) {
            if (logits[j] > max_logit) {
                max_logit = logits[j];
                next_token = j;
            }
        }
        
        // Check for end token
        if (llama_vocab_is_eog(ctx->vocab, next_token)) {
            break;
        }
        
        // Convert token to text
        char token_text[256];
        int32_t token_len = llama_token_to_piece(ctx->vocab, next_token, token_text, sizeof(token_text), false, true);
        
        if (token_len > 0 && output_pos + token_len < max_output_len - 1) {
            memcpy(output_buffer + output_pos, token_text, token_len);
            output_pos += token_len;
        }
        
        // Prepare next batch
        batch = llama_batch_get_one(&next_token, 1);
        if (llama_decode(ctx->ctx, batch) != 0) {
            break;
        }
    }
    
    output_buffer[output_pos] = '\0';
    
    // Reallocate to exact size
    char* final_output = realloc(output_buffer, output_pos + 1);
    if (!final_output && output_pos > 0) {
        free(output_buffer);
        return LLAMA_WRAPPER_ERROR_OUT_OF_MEMORY;
    }
    
    *out_text = final_output;
    return LLAMA_WRAPPER_OK;
}

// Utility functions
llama_wrapper_error_t llama_wrapper_get_vocab_size(
    llama_wrapper_context_t* ctx,
    int32_t* out_vocab_size
) {
    if (!ctx || !out_vocab_size || !ctx->is_valid || !ctx->vocab) {
        return LLAMA_WRAPPER_ERROR_NULL_POINTER;
    }
    
    *out_vocab_size = llama_vocab_n_tokens(ctx->vocab);
    return LLAMA_WRAPPER_OK;
}

llama_wrapper_error_t llama_wrapper_get_context_size(
    llama_wrapper_context_t* ctx,
    int32_t* out_context_size
) {
    if (!ctx || !out_context_size || !ctx->is_valid) {
        return LLAMA_WRAPPER_ERROR_NULL_POINTER;
    }
    
    *out_context_size = llama_n_ctx(ctx->ctx);
    return LLAMA_WRAPPER_OK;
}

// Error handling
const char* llama_wrapper_error_string(llama_wrapper_error_t error) {
    switch (error) {
        case LLAMA_WRAPPER_OK:
            return "Success";
        case LLAMA_WRAPPER_ERROR_NULL_POINTER:
            return "Null pointer error";
        case LLAMA_WRAPPER_ERROR_INVALID_MODEL:
            return "Invalid model";
        case LLAMA_WRAPPER_ERROR_INVALID_CONTEXT:
            return "Invalid context";
        case LLAMA_WRAPPER_ERROR_TOKENIZATION_FAILED:
            return "Tokenization failed";
        case LLAMA_WRAPPER_ERROR_GENERATION_FAILED:
            return "Generation failed";
        case LLAMA_WRAPPER_ERROR_OUT_OF_MEMORY:
            return "Out of memory";
        case LLAMA_WRAPPER_ERROR_FILE_NOT_FOUND:
            return "File not found";
        case LLAMA_WRAPPER_ERROR_UNSUPPORTED_OPERATION:
            return "Unsupported operation";
        default:
            return "Unknown error";
    }
}

// Memory management
void llama_wrapper_free_string(char* str) {
    if (str) {
        free(str);
    }
}

// Default parameters
llama_wrapper_params_t llama_wrapper_default_params(void) {
    llama_wrapper_params_t params = {
        .temperature = 0.7f,
        .top_p = 0.9f,
        .top_k = 40.0f,
        .repeat_penalty = 1.1f,
        .max_tokens = 256,
        .use_mmap = true,
        .use_mlock = false,
        .n_threads = 8,
        .n_batch = 8,
        .n_ctx = 2048,
        .seed = -1
    };
    return params;
}

// Placeholder implementations for advanced features
llama_wrapper_error_t llama_wrapper_generate_stream(
    llama_wrapper_context_t* ctx,
    const llama_wrapper_tokens_t* input_tokens,
    const llama_wrapper_params_t* params,
    void (*callback)(const char* token, void* user_data),
    void* user_data
) {
    // This would implement streaming generation
    return LLAMA_WRAPPER_ERROR_UNSUPPORTED_OPERATION;
}

llama_wrapper_error_t llama_wrapper_get_model_info(
    llama_wrapper_model_t* model,
    char** out_info_json
) {
    if (!model || !out_info_json || !model->is_valid) {
        return LLAMA_WRAPPER_ERROR_NULL_POINTER;
    }
    
    // Create a simple JSON info string
    const char* info_template = "{\"path\":\"%s\",\"size\":%llu,\"n_params\":%llu}";
    uint64_t model_size = llama_model_size(model->model);
    uint64_t n_params = llama_model_n_params(model->model);
    
    size_t info_len = strlen(info_template) + strlen(model->model_path) + 64;
    char* info = malloc(info_len);
    if (!info) {
        return LLAMA_WRAPPER_ERROR_OUT_OF_MEMORY;
    }
    
    snprintf(info, info_len, info_template, model->model_path, model_size, n_params);
    *out_info_json = info;
    
    return LLAMA_WRAPPER_OK;
}

// Batch processing (simplified implementation)
llama_wrapper_error_t llama_wrapper_batch_create(
    size_t batch_size,
    llama_wrapper_batch_t** out_batch
) {
    return LLAMA_WRAPPER_ERROR_UNSUPPORTED_OPERATION;
}

llama_wrapper_error_t llama_wrapper_batch_process(
    llama_wrapper_context_t* ctx,
    llama_wrapper_batch_t* batch,
    const llama_wrapper_params_t* params
) {
    return LLAMA_WRAPPER_ERROR_UNSUPPORTED_OPERATION;
}

llama_wrapper_error_t llama_wrapper_batch_free(llama_wrapper_batch_t* batch) {
    return LLAMA_WRAPPER_ERROR_UNSUPPORTED_OPERATION;
}

// System info (simplified)
llama_wrapper_error_t llama_wrapper_get_system_info(
    llama_wrapper_system_info_t* out_info
) {
    if (!out_info) {
        return LLAMA_WRAPPER_ERROR_NULL_POINTER;
    }
    
    memset(out_info, 0, sizeof(llama_wrapper_system_info_t));
    
    out_info->has_cuda = llama_supports_gpu_offload();
    out_info->has_blas = false; // Would need to detect this
    out_info->has_metal = llama_supports_gpu_offload(); // On macOS
    out_info->has_opencl = false;
    out_info->cuda_device_count = 0;
    out_info->system_memory_mb = 0;
    out_info->vram_mb = 0;
    
    return LLAMA_WRAPPER_OK;
}

// Performance monitoring (simplified)
llama_wrapper_error_t llama_wrapper_get_performance_stats(
    llama_wrapper_context_t* ctx,
    llama_wrapper_perf_t* out_perf
) {
    if (!ctx || !out_perf || !ctx->is_valid) {
        return LLAMA_WRAPPER_ERROR_NULL_POINTER;
    }
    
    // Get LLaMA's performance data
    struct llama_perf_context_data perf_data = llama_perf_context(ctx->ctx);
    
    out_perf->tokens_per_second = perf_data.n_eval / (perf_data.t_eval_ms / 1000.0);
    out_perf->time_to_first_token_ms = perf_data.t_prompt_ms;
    out_perf->memory_used_mb = 0; // Would need to implement
    out_perf->peak_memory_mb = 0; // Would need to implement
    out_perf->total_tokens_generated = perf_data.n_eval;
    
    return LLAMA_WRAPPER_OK;
}

llama_wrapper_error_t llama_wrapper_reset_performance_stats(
    llama_wrapper_context_t* ctx
) {
    if (!ctx || !ctx->is_valid) {
        return LLAMA_WRAPPER_ERROR_NULL_POINTER;
    }
    
    llama_perf_context_reset(ctx->ctx);
    return LLAMA_WRAPPER_OK;
}

// Logging (simplified)
static llama_wrapper_log_callback_t g_log_callback = NULL;
static void* g_log_user_data = NULL;

static void internal_log_callback(enum ggml_log_level level, const char* text, void* user_data) {
    if (g_log_callback) {
        llama_wrapper_log_level_t wrapper_level;
        switch (level) {
            case GGML_LOG_LEVEL_ERROR: wrapper_level = LLAMA_WRAPPER_LOG_LEVEL_ERROR; break;
            case GGML_LOG_LEVEL_WARN:  wrapper_level = LLAMA_WRAPPER_LOG_LEVEL_WARN; break;
            case GGML_LOG_LEVEL_INFO:  wrapper_level = LLAMA_WRAPPER_LOG_LEVEL_INFO; break;
            default:                   wrapper_level = LLAMA_WRAPPER_LOG_LEVEL_DEBUG; break;
        }
        g_log_callback(wrapper_level, text, g_log_user_data);
    }
}

llama_wrapper_error_t llama_wrapper_set_log_callback(
    llama_wrapper_log_callback_t callback,
    void* user_data
) {
    g_log_callback = callback;
    g_log_user_data = user_data;
    
    if (callback) {
        llama_log_set(internal_log_callback, NULL);
    } else {
        llama_log_set(NULL, NULL);
    }
    
    return LLAMA_WRAPPER_OK;
}

llama_wrapper_error_t llama_wrapper_set_log_level(
    llama_wrapper_log_level_t level
) {
    // LLaMA.cpp doesn't have direct log level control
    return LLAMA_WRAPPER_OK;
}