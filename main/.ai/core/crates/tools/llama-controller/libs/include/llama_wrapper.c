#ifndef LLAMA_WRAPPER_H
#define LLAMA_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

// ============================================================================
// FORWARD DECLARATIONS & TYPES
// ============================================================================

// Opaque handles
typedef struct llama_wrapper_model llama_wrapper_model;
typedef struct llama_wrapper_context llama_wrapper_context;
typedef struct llama_wrapper_batch llama_wrapper_batch;
typedef struct llama_wrapper_sampling llama_wrapper_sampling;

// Token type
typedef int32_t llama_wrapper_token;

// Sequence ID type
typedef int32_t llama_wrapper_seq_id;

// Position type
typedef int32_t llama_wrapper_pos;

// ============================================================================
// ENUMS & CONSTANTS
// ============================================================================

// Model architecture types
typedef enum {
    LLAMA_WRAPPER_ARCH_UNKNOWN = 0,
    LLAMA_WRAPPER_ARCH_LLAMA,
    LLAMA_WRAPPER_ARCH_FALCON,
    LLAMA_WRAPPER_ARCH_BAICHUAN,
    LLAMA_WRAPPER_ARCH_STARCODER,
    LLAMA_WRAPPER_ARCH_PERSIMMON,
    LLAMA_WRAPPER_ARCH_REFACT,
    LLAMA_WRAPPER_ARCH_BERT,
    LLAMA_WRAPPER_ARCH_NOMIC_BERT,
    LLAMA_WRAPPER_ARCH_BLOOM,
    LLAMA_WRAPPER_ARCH_STABLELM,
    LLAMA_WRAPPER_ARCH_QWEN,
    LLAMA_WRAPPER_ARCH_GPT2,
    LLAMA_WRAPPER_ARCH_PHI2,
    LLAMA_WRAPPER_ARCH_PLAMO,
    LLAMA_WRAPPER_ARCH_CODESHELL,
    LLAMA_WRAPPER_ARCH_ORION,
    LLAMA_WRAPPER_ARCH_INTERNLM2,
    LLAMA_WRAPPER_ARCH_MINICPM,
    LLAMA_WRAPPER_ARCH_GEMMA,
    LLAMA_WRAPPER_ARCH_STARCODER2,
    LLAMA_WRAPPER_ARCH_MAMBA,
    LLAMA_WRAPPER_ARCH_XVERSE,
    LLAMA_WRAPPER_ARCH_COMMAND_R,
    LLAMA_WRAPPER_ARCH_DBRX,
    LLAMA_WRAPPER_ARCH_OLMO,
} llama_wrapper_arch;

// Vocabulary types
typedef enum {
    LLAMA_WRAPPER_VOCAB_TYPE_NONE = 0,
    LLAMA_WRAPPER_VOCAB_TYPE_SPM,
    LLAMA_WRAPPER_VOCAB_TYPE_BPE,
    LLAMA_WRAPPER_VOCAB_TYPE_WPM,
} llama_wrapper_vocab_type;

// Token types
typedef enum {
    LLAMA_WRAPPER_TOKEN_TYPE_UNDEFINED    = 0,
    LLAMA_WRAPPER_TOKEN_TYPE_NORMAL       = 1,
    LLAMA_WRAPPER_TOKEN_TYPE_UNKNOWN      = 2,
    LLAMA_WRAPPER_TOKEN_TYPE_CONTROL      = 3,
    LLAMA_WRAPPER_TOKEN_TYPE_USER_DEFINED = 4,
    LLAMA_WRAPPER_TOKEN_TYPE_UNUSED       = 5,
    LLAMA_WRAPPER_TOKEN_TYPE_BYTE         = 6,
} llama_wrapper_token_type;

// Rope scaling types
typedef enum {
    LLAMA_WRAPPER_ROPE_SCALING_TYPE_UNSPECIFIED = -1,
    LLAMA_WRAPPER_ROPE_SCALING_TYPE_NONE = 0,
    LLAMA_WRAPPER_ROPE_SCALING_TYPE_LINEAR = 1,
    LLAMA_WRAPPER_ROPE_SCALING_TYPE_YARN = 2,
    LLAMA_WRAPPER_ROPE_SCALING_TYPE_MAX_VALUE = LLAMA_WRAPPER_ROPE_SCALING_TYPE_YARN,
} llama_wrapper_rope_scaling_type;

// Pooling types
typedef enum {
    LLAMA_WRAPPER_POOLING_TYPE_UNSPECIFIED = -1,
    LLAMA_WRAPPER_POOLING_TYPE_NONE = 0,
    LLAMA_WRAPPER_POOLING_TYPE_MEAN = 1,
    LLAMA_WRAPPER_POOLING_TYPE_CLS = 2,
} llama_wrapper_pooling_type;

// Split mode
typedef enum {
    LLAMA_WRAPPER_SPLIT_MODE_NONE = 0,
    LLAMA_WRAPPER_SPLIT_MODE_LAYER = 1,
    LLAMA_WRAPPER_SPLIT_MODE_ROW = 2,
} llama_wrapper_split_mode;

// Attention types
typedef enum {
    LLAMA_WRAPPER_ATTENTION_TYPE_UNSPECIFIED = -1,
    LLAMA_WRAPPER_ATTENTION_TYPE_CAUSAL = 0,
    LLAMA_WRAPPER_ATTENTION_TYPE_NON_CAUSAL = 1,
} llama_wrapper_attention_type;

// Log levels
typedef enum {
    LLAMA_WRAPPER_LOG_LEVEL_ERROR = 2,
    LLAMA_WRAPPER_LOG_LEVEL_WARN  = 3,
    LLAMA_WRAPPER_LOG_LEVEL_INFO  = 4,
} llama_wrapper_log_level;

// Special tokens
#define LLAMA_WRAPPER_TOKEN_NULL    -1
#define LLAMA_WRAPPER_TOKEN_BOS      1
#define LLAMA_WRAPPER_TOKEN_EOS      2
#define LLAMA_WRAPPER_TOKEN_UNK      0
#define LLAMA_WRAPPER_TOKEN_CLS    101
#define LLAMA_WRAPPER_TOKEN_SEP    102
#define LLAMA_WRAPPER_TOKEN_NL  13966
#define LLAMA_WRAPPER_TOKEN_PREFIX 29871
#define LLAMA_WRAPPER_TOKEN_MIDDLE 32000
#define LLAMA_WRAPPER_TOKEN_SUFFIX 32001
#define LLAMA_WRAPPER_TOKEN_EOT    32002

// ============================================================================
// PARAMETER STRUCTS
// ============================================================================

// Model parameters
typedef struct {
    int32_t n_gpu_layers;
    llama_wrapper_split_mode split_mode;
    int32_t main_gpu;
    const float* tensor_split;
    const char* rpc_servers;
    bool vocab_only;
    bool use_mmap;
    bool use_mlock;
    bool check_tensors;
} llama_wrapper_model_params;

// Context parameters
typedef struct {
    uint32_t seed;
    uint32_t n_ctx;
    uint32_t n_batch;
    uint32_t n_ubatch;
    uint32_t n_seq_max;
    uint32_t n_threads;
    uint32_t n_threads_batch;
    llama_wrapper_rope_scaling_type rope_scaling_type;
    llama_wrapper_pooling_type pooling_type;
    llama_wrapper_attention_type attention_type;
    float rope_freq_base;
    float rope_freq_scale;
    float yarn_ext_factor;
    float yarn_attn_factor;
    float yarn_beta_fast;
    float yarn_beta_slow;
    uint32_t yarn_orig_ctx;
    float defrag_thold;
    void (*cb_eval)(void* data, bool *cancel);
    void* cb_eval_user_data;
    bool embeddings;
    bool offload_kqv;
    bool flash_attn;
    bool no_perf;
    void* abort_callback;
    void* abort_callback_data;
} llama_wrapper_context_params;

// Batch parameters
typedef struct {
    int32_t n_tokens;
    llama_wrapper_token* token;
    float* embd;
    llama_wrapper_pos* pos;
    int32_t* n_seq_id;
    llama_wrapper_seq_id** seq_id;
    int8_t* logits;
} llama_wrapper_batch_params;

// Model quantize parameters
typedef struct {
    int32_t nthread;
    int32_t ftype;
    bool allow_requantize;
    bool quantize_output_tensor;
    bool only_copy;
    bool pure;
    void* imatrix;
} llama_wrapper_model_quantize_params;

// Sampling parameters
typedef struct {
    int32_t n_prev;
    int32_t n_probs;
    int32_t top_k;
    float top_p;
    float min_p;
    float tfs_z;
    float typical_p;
    float temp;
    int32_t penalty_last_n;
    float penalty_repeat;
    float penalty_freq;
    float penalty_present;
    int32_t mirostat;
    float mirostat_tau;
    float mirostat_eta;
    bool penalize_nl;
    llama_wrapper_token* logit_bias;
    int32_t n_logit_bias;
} llama_wrapper_sampling_params;

// Chat template parameters
typedef struct {
    bool add_generation_prompt;
    const char* system_message;
} llama_wrapper_chat_template_params;

// Grammar parameters
typedef struct {
    const char* grammar_string;
    const char* grammar_root;
} llama_wrapper_grammar_params;

// ============================================================================
// INITIALIZATION & BACKEND
// ============================================================================

// Initialize the library
void llama_wrapper_backend_init(void);

// Free all allocated memory
void llama_wrapper_backend_free(void);

// Set log callback
void llama_wrapper_log_set(void (*log_callback)(llama_wrapper_log_level level, const char* text, void* user_data), void* user_data);

// Get system information
size_t llama_wrapper_max_devices(void);
bool llama_wrapper_supports_mmap(void);
bool llama_wrapper_supports_mlock(void);
bool llama_wrapper_supports_gpu_offload(void);

// Time utilities
int64_t llama_wrapper_time_us(void);

// ============================================================================
// MODEL FUNCTIONS
// ============================================================================

// Get default model parameters
llama_wrapper_model_params llama_wrapper_model_default_params(void);

// Load model from file
llama_wrapper_model* llama_wrapper_load_model_from_file(const char* path_model, llama_wrapper_model_params params);

// Free model
void llama_wrapper_free_model(llama_wrapper_model* model);

// Model metadata
uint32_t llama_wrapper_model_meta_count(const llama_wrapper_model* model);
int32_t llama_wrapper_model_meta_key_by_index(const llama_wrapper_model* model, int32_t i, char* buf, size_t buf_size);
int32_t llama_wrapper_model_meta_val_str_by_index(const llama_wrapper_model* model, int32_t i, char* buf, size_t buf_size);
int32_t llama_wrapper_model_meta_val_str(const llama_wrapper_model* model, const char* key, char* buf, size_t buf_size);

// Model info
int32_t llama_wrapper_model_desc(const llama_wrapper_model* model, char* buf, size_t buf_size);
uint64_t llama_wrapper_model_size(const llama_wrapper_model* model);
uint64_t llama_wrapper_model_n_params(const llama_wrapper_model* model);
int32_t llama_wrapper_model_n_ctx_train(const llama_wrapper_model* model);
int32_t llama_wrapper_model_n_embd(const llama_wrapper_model* model);
int32_t llama_wrapper_model_n_layer(const llama_wrapper_model* model);
int32_t llama_wrapper_model_n_head(const llama_wrapper_model* model);
int32_t llama_wrapper_model_n_head_kv(const llama_wrapper_model* model);
int32_t llama_wrapper_model_n_vocab(const llama_wrapper_model* model);
int32_t llama_wrapper_model_rope_freq_scale_train(const llama_wrapper_model* model);
llama_wrapper_rope_scaling_type llama_wrapper_model_rope_type(const llama_wrapper_model* model);

// Model quantization
llama_wrapper_model_quantize_params llama_wrapper_model_quantize_default_params(void);
bool llama_wrapper_model_quantize(const char* fname_inp, const char* fname_out, const llama_wrapper_model_quantize_params* params);

// ============================================================================
// CONTEXT FUNCTIONS
// ============================================================================

// Get default context parameters
llama_wrapper_context_params llama_wrapper_context_default_params(void);

// Create context
llama_wrapper_context* llama_wrapper_new_context_with_model(llama_wrapper_model* model, llama_wrapper_context_params params);

// Free context
void llama_wrapper_free(llama_wrapper_context* ctx);

// Context info
uint32_t llama_wrapper_n_ctx(const llama_wrapper_context* ctx);
uint32_t llama_wrapper_n_batch(const llama_wrapper_context* ctx);
uint32_t llama_wrapper_n_ubatch(const llama_wrapper_context* ctx);
uint32_t llama_wrapper_n_seq_max(const llama_wrapper_context* ctx);

// KV cache management
int32_t llama_wrapper_get_kv_cache_token_count(const llama_wrapper_context* ctx);
int32_t llama_wrapper_get_kv_cache_used_cells(const llama_wrapper_context* ctx);
void llama_wrapper_kv_cache_clear(llama_wrapper_context* ctx);
bool llama_wrapper_kv_cache_seq_rm(llama_wrapper_context* ctx, llama_wrapper_seq_id seq_id, llama_wrapper_pos p0, llama_wrapper_pos p1);
void llama_wrapper_kv_cache_seq_cp(llama_wrapper_context* ctx, llama_wrapper_seq_id seq_id_src, llama_wrapper_seq_id seq_id_dst, llama_wrapper_pos p0, llama_wrapper_pos p1);
void llama_wrapper_kv_cache_seq_keep(llama_wrapper_context* ctx, llama_wrapper_seq_id seq_id);
void llama_wrapper_kv_cache_seq_add(llama_wrapper_context* ctx, llama_wrapper_seq_id seq_id, llama_wrapper_pos p0, llama_wrapper_pos p1, llama_wrapper_pos delta);
void llama_wrapper_kv_cache_seq_div(llama_wrapper_context* ctx, llama_wrapper_seq_id seq_id, llama_wrapper_pos p0, llama_wrapper_pos p1, int32_t d);
llama_wrapper_pos llama_wrapper_kv_cache_seq_pos_max(llama_wrapper_context* ctx, llama_wrapper_seq_id seq_id);
void llama_wrapper_kv_cache_defrag(llama_wrapper_context* ctx);
void llama_wrapper_kv_cache_update(llama_wrapper_context* ctx);

// State management
size_t llama_wrapper_get_state_size(llama_wrapper_context* ctx);
size_t llama_wrapper_copy_state_data(llama_wrapper_context* ctx, uint8_t* dest);
size_t llama_wrapper_set_state_data(llama_wrapper_context* ctx, const uint8_t* src);
bool llama_wrapper_save_session_file(llama_wrapper_context* ctx, const char* path_session, const llama_wrapper_token* tokens, size_t n_token);
bool llama_wrapper_load_session_file(llama_wrapper_context* ctx, const char* path_session, llama_wrapper_token* tokens_out, size_t n_token_capacity, size_t* n_token_count_out);

// ============================================================================
// BATCH FUNCTIONS
// ============================================================================

// Create batch
llama_wrapper_batch* llama_wrapper_batch_init(int32_t n_tokens, int32_t embd, int32_t n_seq_max);

// Free batch
void llama_wrapper_batch_free(llama_wrapper_batch* batch);

// Batch operations
void llama_wrapper_batch_clear(llama_wrapper_batch* batch);
void llama_wrapper_batch_add(llama_wrapper_batch* batch, llama_wrapper_token id, llama_wrapper_pos pos, const llama_wrapper_seq_id* seq_ids, size_t n_seq_ids, bool logits);
int32_t llama_wrapper_batch_n_tokens(const llama_wrapper_batch* batch);

// Decode batch
int32_t llama_wrapper_decode(llama_wrapper_context* ctx, llama_wrapper_batch* batch);

// ============================================================================
// TOKENIZATION FUNCTIONS
// ============================================================================

// Tokenize text
int32_t llama_wrapper_tokenize(const llama_wrapper_model* model, const char* text, int32_t text_len, llama_wrapper_token* tokens, int32_t n_tokens_max, bool add_special, bool parse_special);

// Token to piece
int32_t llama_wrapper_token_to_piece(const llama_wrapper_model* model, llama_wrapper_token token, char* buf, int32_t length, int32_t lstrip, bool special);

// Detokenize
int32_t llama_wrapper_detokenize(const llama_wrapper_model* model, const llama_wrapper_token* tokens, int32_t n_tokens, char* text, int32_t text_len_max, bool remove_special, bool unparse_special);

// Special tokens
llama_wrapper_token llama_wrapper_token_bos(const llama_wrapper_model* model);
llama_wrapper_token llama_wrapper_token_eos(const llama_wrapper_model* model);
llama_wrapper_token llama_wrapper_token_cls(const llama_wrapper_model* model);
llama_wrapper_token llama_wrapper_token_sep(const llama_wrapper_model* model);
llama_wrapper_token llama_wrapper_token_nl(const llama_wrapper_model* model);
llama_wrapper_token llama_wrapper_token_pad(const llama_wrapper_model* model);

// Add special tokens
int32_t llama_wrapper_add_bos_token(const llama_wrapper_model* model);
int32_t llama_wrapper_add_eos_token(const llama_wrapper_model* model);

// Token attributes
llama_wrapper_token llama_wrapper_token_prefix(const llama_wrapper_model* model);
llama_wrapper_token llama_wrapper_token_middle(const llama_wrapper_model* model);
llama_wrapper_token llama_wrapper_token_suffix(const llama_wrapper_model* model);
llama_wrapper_token llama_wrapper_token_eot(const llama_wrapper_model* model);

// Token type
llama_wrapper_token_type llama_wrapper_token_get_type(const llama_wrapper_model* model, llama_wrapper_token token);

// Token score
float llama_wrapper_token_get_score(const llama_wrapper_model* model, llama_wrapper_token token);

// Token attributes check
bool llama_wrapper_token_is_eog(const llama_wrapper_model* model, llama_wrapper_token token);
bool llama_wrapper_token_is_control(const llama_wrapper_model* model, llama_wrapper_token token);

// ============================================================================
// INFERENCE FUNCTIONS
// ============================================================================

// Get logits
float* llama_wrapper_get_logits(llama_wrapper_context* ctx);
float* llama_wrapper_get_logits_ith(llama_wrapper_context* ctx, int32_t i);

// Get embeddings
float* llama_wrapper_get_embeddings(llama_wrapper_context* ctx);
float* llama_wrapper_get_embeddings_ith(llama_wrapper_context* ctx, int32_t i);
float* llama_wrapper_get_embeddings_seq(llama_wrapper_context* ctx, llama_wrapper_seq_id seq_id);

// ============================================================================
// SAMPLING FUNCTIONS
// ============================================================================

// Create sampling context
llama_wrapper_sampling* llama_wrapper_sampling_init(const llama_wrapper_sampling_params* params);

// Free sampling context
void llama_wrapper_sampling_free(llama_wrapper_sampling* ctx_sampling);

// Reset sampling
void llama_wrapper_sampling_reset(llama_wrapper_sampling* ctx_sampling);

// Set seed
void llama_wrapper_set_rng_seed(llama_wrapper_context* ctx, uint32_t seed);

// Sample token
llama_wrapper_token llama_wrapper_sampling_sample(llama_wrapper_sampling* ctx_sampling, llama_wrapper_context* ctx, llama_wrapper_context* ctx_cfg, int32_t idx);

// Accept token
void llama_wrapper_sampling_accept(llama_wrapper_sampling* ctx_sampling, llama_wrapper_context* ctx, llama_wrapper_token id, bool apply_grammar);

// Sampling utilities
llama_wrapper_token llama_wrapper_sample_token_greedy(llama_wrapper_context* ctx, float* logits);
llama_wrapper_token llama_wrapper_sample_token_with_rng(llama_wrapper_context* ctx, float* logits, void* rng);
llama_wrapper_token llama_wrapper_sample_token(llama_wrapper_context* ctx, float* logits);

// Apply logit bias
void llama_wrapper_sample_apply_logit_bias(llama_wrapper_context* ctx, float* logits, const llama_wrapper_token* tokens, int32_t n_tokens, float bias);

// ============================================================================
// GRAMMAR FUNCTIONS
// ============================================================================

// Grammar handle
typedef struct llama_wrapper_grammar llama_wrapper_grammar;

// Parse grammar
llama_wrapper_grammar* llama_wrapper_grammar_init(const llama_wrapper_grammar_params* params);

// Free grammar
void llama_wrapper_grammar_free(llama_wrapper_grammar* grammar);

// Copy grammar
llama_wrapper_grammar* llama_wrapper_grammar_copy(const llama_wrapper_grammar* grammar);

// Sample with grammar
void llama_wrapper_sample_grammar(llama_wrapper_context* ctx, float* logits, llama_wrapper_grammar* grammar);

// Accept grammar
void llama_wrapper_grammar_accept_token(llama_wrapper_context* ctx, llama_wrapper_grammar* grammar, llama_wrapper_token token);

// ============================================================================
// CHAT TEMPLATE FUNCTIONS
// ============================================================================

// Apply chat template
int32_t llama_wrapper_chat_apply_template(const llama_wrapper_model* model, const char* tmpl, const char** chat, size_t n_msg, bool add_ass, char* buf, int32_t length);

// Built-in chat template
int32_t llama_wrapper_model_has_encoder(const llama_wrapper_model* model);
int32_t llama_wrapper_model_has_decoder(const llama_wrapper_model* model);
llama_wrapper_token llama_wrapper_model_decoder_start_token(const llama_wrapper_model* model);
bool llama_wrapper_model_is_recurrent(const llama_wrapper_model* model);

// ============================================================================
// EMBEDDINGS
// ============================================================================

// Pooling type
void llama_wrapper_pooling_type(llama_wrapper_context* ctx, llama_wrapper_pooling_type type);

// ============================================================================
// PERFORMANCE & MONITORING
// ============================================================================

// Timing info
struct llama_wrapper_timings {
    double t_start_ms;
    double t_end_ms;
    double t_load_ms;
    double t_sample_ms;
    double t_p_eval_ms;
    double t_eval_ms;
    
    int32_t n_sample;
    int32_t n_p_eval;
    int32_t n_eval;
};

// Get timings
struct llama_wrapper_timings llama_wrapper_get_timings(llama_wrapper_context* ctx);

// Reset timings
void llama_wrapper_reset_timings(llama_wrapper_context* ctx);

// Print timings
void llama_wrapper_print_timings(llama_wrapper_context* ctx);

// Print system info
void llama_wrapper_print_system_info(void);

// Memory usage
size_t llama_wrapper_get_max_tensor_size(const llama_wrapper_model* model);
void llama_wrapper_dump_timing_info_yaml(FILE* stream, const llama_wrapper_context* ctx);

// ============================================================================
// MIROSTAT SAMPLING
// ============================================================================

// Mirostat v1
void llama_wrapper_sample_entropy(llama_wrapper_context* ctx, float* candidates, float min_temp, float max_temp, float exponent_val);

// Mirostat v2  
void llama_wrapper_sample_temp(llama_wrapper_context* ctx, float* candidates, float temp);

// ============================================================================
// UTILITIES & HELPERS
// ============================================================================

// Get vocab type
llama_wrapper_vocab_type llama_wrapper_vocab_type(const llama_wrapper_model* model);

// Print vocab
void llama_wrapper_model_print_vocab(const llama_wrapper_model* model, const char* fname);

// Architecture
llama_wrapper_arch llama_wrapper_model_arch(const llama_wrapper_model* model);

// Check if embeddings are supported
bool llama_wrapper_model_has_embeddings(const llama_wrapper_model* model);

// Attention type
llama_wrapper_attention_type llama_wrapper_model_attention_type(const llama_wrapper_model* model);

// ============================================================================
// ERROR HANDLING
// ============================================================================

// Get last error
const char* llama_wrapper_get_last_error(void);

// Clear last error  
void llama_wrapper_clear_last_error(void);

// ============================================================================
// MEMORY MANAGEMENT HELPERS
// ============================================================================

// Allocate aligned memory
void* llama_wrapper_aligned_malloc(size_t size);

// Free aligned memory
void llama_wrapper_aligned_free(void* ptr);

#ifdef __cplusplus
}
#endif

#endif // LLAMA_WRAPPER_H