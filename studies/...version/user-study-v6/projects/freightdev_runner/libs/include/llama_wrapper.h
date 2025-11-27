// include/llama_wrapper.h
// Universal wrapper for LLaMA.cpp FFI bindings
#ifndef LLAMA_WRAPPER_H
#define LLAMA_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

// Core LLaMA includes
#include "llama.h"
#include "ggml.h"

// Common utilities (if available)
#ifdef LLAMA_COMMON_H
#include "common.h"
#endif

// Version information
#define LLAMA_WRAPPER_VERSION_MAJOR 1
#define LLAMA_WRAPPER_VERSION_MINOR 0
#define LLAMA_WRAPPER_VERSION_PATCH 0

// Error codes for wrapper functions
typedef enum {
    LLAMA_WRAPPER_OK = 0,
    LLAMA_WRAPPER_ERROR_NULL_POINTER = -1,
    LLAMA_WRAPPER_ERROR_INVALID_MODEL = -2,
    LLAMA_WRAPPER_ERROR_INVALID_CONTEXT = -3,
    LLAMA_WRAPPER_ERROR_TOKENIZATION_FAILED = -4,
    LLAMA_WRAPPER_ERROR_GENERATION_FAILED = -5,
    LLAMA_WRAPPER_ERROR_OUT_OF_MEMORY = -6,
    LLAMA_WRAPPER_ERROR_FILE_NOT_FOUND = -7,
    LLAMA_WRAPPER_ERROR_UNSUPPORTED_OPERATION = -8
} llama_wrapper_error_t;

// Wrapper structures for safer FFI
typedef struct {
    struct llama_model* model;
    bool is_valid;
    char* model_path;
} llama_wrapper_model_t;

typedef struct {
    struct llama_context* ctx;
    bool is_valid;
    llama_wrapper_model_t* model;
} llama_wrapper_context_t;

typedef struct {
    llama_token* tokens;
    size_t count;
    size_t capacity;
} llama_wrapper_tokens_t;

typedef struct {
    float temperature;
    float top_p;
    float top_k;
    float repeat_penalty;
    int32_t max_tokens;
    bool use_mmap;
    bool use_mlock;
    int32_t n_threads;
    int32_t n_batch;
    int32_t n_ctx;
    int32_t seed;
} llama_wrapper_params_t;

// Model management functions
llama_wrapper_error_t llama_wrapper_model_load(
    const char* model_path,
    const llama_wrapper_params_t* params,
    llama_wrapper_model_t** out_model
);

llama_wrapper_error_t llama_wrapper_model_free(llama_wrapper_model_t* model);

llama_wrapper_error_t llama_wrapper_context_new(
    llama_wrapper_model_t* model,
    const llama_wrapper_params_t* params,
    llama_wrapper_context_t** out_context
);

llama_wrapper_error_t llama_wrapper_context_free(llama_wrapper_context_t* ctx);

// Tokenization functions
llama_wrapper_error_t llama_wrapper_tokenize(
    llama_wrapper_context_t* ctx,
    const char* text,
    bool add_bos,
    llama_wrapper_tokens_t** out_tokens
);

llama_wrapper_error_t llama_wrapper_detokenize(
    llama_wrapper_context_t* ctx,
    const llama_wrapper_tokens_t* tokens,
    char** out_text
);

llama_wrapper_error_t llama_wrapper_tokens_free(llama_wrapper_tokens_t* tokens);

// Generation functions
llama_wrapper_error_t llama_wrapper_generate(
    llama_wrapper_context_t* ctx,
    const llama_wrapper_tokens_t* input_tokens,
    const llama_wrapper_params_t* params,
    char** out_text
);

llama_wrapper_error_t llama_wrapper_generate_stream(
    llama_wrapper_context_t* ctx,
    const llama_wrapper_tokens_t* input_tokens,
    const llama_wrapper_params_t* params,
    void (*callback)(const char* token, void* user_data),
    void* user_data
);

// Utility functions
llama_wrapper_error_t llama_wrapper_get_vocab_size(
    llama_wrapper_context_t* ctx,
    int32_t* out_vocab_size
);

llama_wrapper_error_t llama_wrapper_get_context_size(
    llama_wrapper_context_t* ctx,
    int32_t* out_context_size
);

llama_wrapper_error_t llama_wrapper_get_model_info(
    llama_wrapper_model_t* model,
    char** out_info_json
);

// Error handling
const char* llama_wrapper_error_string(llama_wrapper_error_t error);

// Memory management helpers
void llama_wrapper_free_string(char* str);

// Default parameter initialization
llama_wrapper_params_t llama_wrapper_default_params(void);

// Batch processing functions
typedef struct {
    llama_wrapper_tokens_t** input_batches;
    size_t batch_count;
    char** outputs;
    llama_wrapper_error_t* errors;
} llama_wrapper_batch_t;

llama_wrapper_error_t llama_wrapper_batch_create(
    size_t batch_size,
    llama_wrapper_batch_t** out_batch
);

llama_wrapper_error_t llama_wrapper_batch_process(
    llama_wrapper_context_t* ctx,
    llama_wrapper_batch_t* batch,
    const llama_wrapper_params_t* params
);

llama_wrapper_error_t llama_wrapper_batch_free(llama_wrapper_batch_t* batch);

// System information
typedef struct {
    bool has_cuda;
    bool has_metal;
    bool has_opencl;
    bool has_blas;
    int32_t cuda_device_count;
    size_t system_memory_mb;
    size_t vram_mb;
} llama_wrapper_system_info_t;

llama_wrapper_error_t llama_wrapper_get_system_info(
    llama_wrapper_system_info_t* out_info
);

// Performance monitoring
typedef struct {
    double tokens_per_second;
    double time_to_first_token_ms;
    size_t memory_used_mb;
    size_t peak_memory_mb;
    uint64_t total_tokens_generated;
} llama_wrapper_perf_t;

llama_wrapper_error_t llama_wrapper_get_performance_stats(
    llama_wrapper_context_t* ctx,
    llama_wrapper_perf_t* out_perf
);

llama_wrapper_error_t llama_wrapper_reset_performance_stats(
    llama_wrapper_context_t* ctx
);

// Logging configuration
typedef enum {
    LLAMA_WRAPPER_LOG_LEVEL_ERROR = 0,
    LLAMA_WRAPPER_LOG_LEVEL_WARN = 1,
    LLAMA_WRAPPER_LOG_LEVEL_INFO = 2,
    LLAMA_WRAPPER_LOG_LEVEL_DEBUG = 3
} llama_wrapper_log_level_t;

typedef void (*llama_wrapper_log_callback_t)(
    llama_wrapper_log_level_t level,
    const char* message,
    void* user_data
);

llama_wrapper_error_t llama_wrapper_set_log_callback(
    llama_wrapper_log_callback_t callback,
    void* user_data
);

llama_wrapper_error_t llama_wrapper_set_log_level(
    llama_wrapper_log_level_t level
);

#ifdef __cplusplus
}
#endif

#endif // LLAMA_WRAPPER_H