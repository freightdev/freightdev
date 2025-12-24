#ifndef LLAMA_WRAPPER_H
#define LLAMA_WRAPPER_H

// Core llama.cpp headers
#include "llama.h"
#include "ggml.h"

// Standard C headers for types used by llama.cpp
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

// Optional: Custom wrapper functions for safer Rust integration
#ifdef __cplusplus
extern "C" {
#endif

// Memory safety wrappers
typedef struct {
    struct llama_context* ctx;
    struct llama_model* model;
    bool is_valid;
} llama_safe_context_t;

// Safe context creation with error checking
llama_safe_context_t* llama_safe_new_context_with_model(
    struct llama_model* model,
    struct llama_context_params params
);

// Safe context cleanup
void llama_safe_free_context(llama_safe_context_t* safe_ctx);

// Safe tokenization with bounds checking
int32_t llama_safe_tokenize(
    const struct llama_model* model,
    const char* text,
    int32_t text_len,
    llama_token* tokens,
    int32_t n_max_tokens,
    bool add_bos,
    bool special
);

// Safe detokenization with bounds checking
int32_t llama_safe_token_to_piece(
    const struct llama_model* model,
    llama_token token,
    char* buf,
    int32_t length,
    bool special
);

// Batch processing helper
typedef struct {
    llama_batch batch;
    bool is_allocated;
} llama_safe_batch_t;

llama_safe_batch_t* llama_safe_batch_init(int32_t n_tokens, int32_t embd, int32_t n_seq_max);
void llama_safe_batch_free(llama_safe_batch_t* safe_batch);

// String helpers for Rust integration
typedef struct {
    char* data;
    size_t len;
    size_t capacity;
} llama_string_t;

llama_string_t* llama_string_new(size_t capacity);
void llama_string_free(llama_string_t* str);
bool llama_string_append(llama_string_t* str, const char* text, size_t len);

// Model info extraction
typedef struct {
    char name[256];
    char architecture[64];
    uint64_t param_count;
    uint32_t vocab_size;
    uint32_t context_length;
    uint32_t embedding_length;
    bool has_encoder;
    bool has_decoder;
} llama_model_info_t;

bool llama_get_model_info(const struct llama_model* model, llama_model_info_t* info);

// Inference state management
typedef struct {
    float* logits;
    size_t logits_size;
    int32_t n_past;
    int32_t n_tokens;
    bool is_ready;
} llama_inference_state_t;

llama_inference_state_t* llama_inference_state_new(struct llama_context* ctx);
void llama_inference_state_free(llama_inference_state_t* state);
bool llama_inference_state_update(llama_inference_state_t* state, struct llama_context* ctx);

// Threading helpers for async Rust integration
typedef struct {
    struct llama_context* ctx;
    llama_token* tokens;
    int32_t n_tokens;
    int32_t n_past;
    int32_t n_threads;
    volatile bool should_stop;
    volatile bool is_running;
} llama_async_job_t;

llama_async_job_t* llama_async_job_new(
    struct llama_context* ctx,
    int32_t n_threads
);

void llama_async_job_free(llama_async_job_t* job);
bool llama_async_job_start(llama_async_job_t* job, llama_token* tokens, int32_t n_tokens);
void llama_async_job_stop(llama_async_job_t* job);

// Error handling
typedef enum {
    LLAMA_ERROR_NONE = 0,
    LLAMA_ERROR_INVALID_MODEL,
    LLAMA_ERROR_INVALID_CONTEXT,
    LLAMA_ERROR_OUT_OF_MEMORY,
    LLAMA_ERROR_TOKENIZATION_FAILED,
    LLAMA_ERROR_INFERENCE_FAILED,
    LLAMA_ERROR_INVALID_PARAMS,
    LLAMA_ERROR_FILE_NOT_FOUND,
    LLAMA_ERROR_UNKNOWN
} llama_error_code_t;

const char* llama_error_string(llama_error_code_t error);

// GPU detection and management
typedef struct {
    bool cuda_available;
    bool metal_available;
    bool opencl_available;
    bool vulkan_available;
    int32_t cuda_device_count;
    char cuda_devices[8][256]; // Up to 8 CUDA devices
    size_t total_vram_mb;
    size_t free_vram_mb;
} llama_gpu_info_t;

bool llama_get_gpu_info(llama_gpu_info_t* info);

// Performance monitoring
typedef struct {
    double tokens_per_second;
    double time_to_first_token_ms;
    double time_per_token_ms;
    uint64_t total_tokens_processed;
    uint64_t total_time_ms;
    size_t memory_usage_mb;
    size_t peak_memory_mb;
} llama_perf_stats_t;

void llama_perf_stats_init(llama_perf_stats_t* stats);
void llama_perf_stats_update(llama_perf_stats_t* stats, struct llama_context* ctx);
void llama_perf_stats_reset(llama_perf_stats_t* stats);

// Streaming helpers for real-time inference
typedef void (*llama_token_callback_t)(llama_token token, const char* piece, void* user_data);

typedef struct {
    struct llama_context* ctx;
    llama_token_callback_t callback;
    void* user_data;
    bool is_streaming;
    volatile bool should_stop;
} llama_stream_t;

llama_stream_t* llama_stream_new(
    struct llama_context* ctx,
    llama_token_callback_t callback,
    void* user_data
);

void llama_stream_free(llama_stream_t* stream);
bool llama_stream_start(llama_stream_t* stream, const char* prompt);
void llama_stream_stop(llama_stream_t* stream);

// Utility macros for Rust integration
#define LLAMA_SAFE_CALL(func, ...) \
    do { \
        if (!(func(__VA_ARGS__))) { \
            return false; \
        } \
    } while(0)

#define LLAMA_CHECK_NULL(ptr) \
    do { \
        if ((ptr) == NULL) { \
            return false; \
        } \
    } while(0)

// Version information
#define LLAMA_WRAPPER_VERSION_MAJOR 0
#define LLAMA_WRAPPER_VERSION_MINOR 1
#define LLAMA_WRAPPER_VERSION_PATCH 0

const char* llama_wrapper_version(void);
bool llama_wrapper_is_compatible(int major, int minor, int patch);

#ifdef __cplusplus
}
#endif

#endif // LLAMA_WRAPPER_H