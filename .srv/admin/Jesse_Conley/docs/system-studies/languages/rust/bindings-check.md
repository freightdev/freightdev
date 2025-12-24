# 🧠 llama.cpp Symbols Extraction
_Extracted from: \n
## 🔍 Struct: llama_batch
        typedef struct llama_batch {
            int32_t n_tokens;
    
            llama_token  *  token;
            float        *  embd;
            llama_pos    *  pos;
            int32_t      *  n_seq_id;
            llama_seq_id ** seq_id;
            int8_t       *  logits;   // TODO: rename this to "output"
        } llama_batch;
    
        enum llama_model_kv_override_type {
            LLAMA_KV_OVERRIDE_TYPE_INT,
            LLAMA_KV_OVERRIDE_TYPE_FLOAT,
            LLAMA_KV_OVERRIDE_TYPE_BOOL,
            LLAMA_KV_OVERRIDE_TYPE_STR,
        };
    
        struct llama_model_kv_override {
            enum llama_model_kv_override_type tag;
    
    --
        LLAMA_API struct llama_batch llama_batch_get_one(
                      llama_token * tokens,
                          int32_t   n_tokens);
    
        // Allocates a batch of tokens on the heap that can hold a maximum of n_tokens
        // Each token can be assigned up to n_seq_max sequence ids
        // The batch has to be freed with llama_batch_free()
        // If embd != 0, llama_batch.embd will be allocated with size of n_tokens * embd * sizeof(float)
        // Otherwise, llama_batch.token will be allocated to store n_tokens llama_token
        // The rest of the llama_batch members are allocated with size n_tokens
        // All members are left uninitialized
        LLAMA_API struct llama_batch llama_batch_init(
                int32_t n_tokens,
                int32_t embd,
                int32_t n_seq_max);
    
        // Frees a batch of tokens allocated with llama_batch_init()
        LLAMA_API void llama_batch_free(struct llama_batch batch);
    
        // Process a batch of tokens.
        // In contrast to llama_decode() - this call does not use KV cache.
        // For encode-decoder contexts, processes the batch using the encoder.
        // Can store the encoder output internally for later use by the decoder's cross-attention layers.
        //   0 - success
        // < 0 - error. the memory state is restored to the state before this call
        LLAMA_API int32_t llama_encode(
                struct llama_context * ctx,
                  struct llama_batch   batch);
    
        // Process a batch of tokens.
        // Requires the context to have a memory.
        // For encode-decoder contexts, processes the batch using the decoder.
        // Positive return values does not mean a fatal error, but rather a warning.
        // Upon fatal-error or abort, the ubatches that managed to be been processed will remain in the memory state of the context
        //   To handle this correctly, query the memory state using llama_memory_seq_pos_min() and llama_memory_seq_pos_max()
        // Upon other return values, the memory state is restored to the state before this call
        //    0 - success
        //    1 - could not find a KV slot for the batch (try reducing the size of the batch or increase the context)
        //    2 - aborted     (processed ubatches will remain in the context's memory)
        //   -1 - invalid input batch
        // < -1 - fatal error (processed ubatches will remain in the context's memory)
        LLAMA_API int32_t llama_decode(
                struct llama_context * ctx,
                  struct llama_batch   batch);
    
        // Set the number of threads used for decoding
        // n_threads is the number of threads used for generation (single token)
        // n_threads_batch is the number of threads used for prompt and batch processing (multiple tokens)
        LLAMA_API void llama_set_n_threads(struct llama_context * ctx, int32_t n_threads, int32_t n_threads_batch);
    
        // Get the number of threads used for generation of a single token.
        LLAMA_API int32_t llama_n_threads(struct llama_context * ctx);
    
        // Get the number of threads used for prompt and batch processing (multiple token).
        LLAMA_API int32_t llama_n_threads_batch(struct llama_context * ctx);
    
        // Set whether the context outputs embeddings or not
        // TODO: rename to avoid confusion with llama_get_embeddings()
        LLAMA_API void llama_set_embeddings(struct llama_context * ctx, bool embeddings);
    
        // Set whether to use causal attention or not
        // If set to true, the model will only attend to the past tokens
        LLAMA_API void llama_set_causal_attn(struct llama_context * ctx, bool causal_attn);
    
    --
        //LLAMA_API void llama_decode_with_sampler(struct llama_context * ctx, struct llama_sampler * smpl, struct llama_batch batch, ...);
    
        //
        // Model split
        //
    
        /// @details Build a split GGUF final path for this chunk.
        ///          llama_split_path(split_path, sizeof(split_path), "/models/ggml-model-q4_0", 2, 4) => split_path = "/models/ggml-model-q4_0-00002-of-00004.gguf"
        //  Returns the split_path length.
        LLAMA_API int llama_split_path(char * split_path, size_t maxlen, const char * path_prefix, int split_no, int split_count);
    
        /// @details Extract the path prefix from the split_path if and only if the split_no and split_count match.
        ///          llama_split_prefix(split_prefix, 64, "/models/ggml-model-q4_0-00002-of-00004.gguf", 2, 4) => split_prefix = "/models/ggml-model-q4_0"
        //  Returns the split_prefix length.
        LLAMA_API int llama_split_prefix(char * split_prefix, size_t maxlen, const char * split_path, int split_no, int split_count);
    
        // Print system information
        LLAMA_API const char * llama_print_system_info(void);
    
        // Set callback for all future logging events.
        // If this is not called, or NULL is supplied, everything is output on stderr.

## 🔍 Type: llama_token
        typedef int32_t llama_token;
        typedef struct llama_token_data {
        typedef struct llama_token_data_array {

## 🔍 Function: llama_decode
        // Input data for llama_encode/llama_decode
        // A llama_batch object can contain input about one or many sequences
        // The provided arrays (i.e. token, embd, pos, etc.) must have size of n_tokens
        //
    --
        //            (if set to NULL, the token position will be tracked automatically by llama_encode/llama_decode)
        // - seq_id : the sequence to which the respective token belongs
        //            (if set to NULL, the sequence ID will be assumed to be 0)
        // - logits : if zero, the logits (and/or the embeddings) for the respective token will not be output
    --
            uint32_t n_batch;           // logical maximum batch size that can be submitted to llama_decode
            uint32_t n_ubatch;          // physical maximum batch size
            uint32_t n_seq_max;         // max number of sequences (i.e. distinct states for recurrent models)
            int32_t  n_threads;         // number of threads to use for generation
    --
            // if it returns true, execution of llama_decode() will be aborted
            // currently works only with CPU execution
            ggml_abort_callback abort_callback;
            void *              abort_callback_data;
    --
        // Returns true if the model contains a decoder that requires llama_decode() call
        LLAMA_API bool llama_model_has_decoder(const struct llama_model * model);
    
        // For encoder-decoder models, this function returns id of the token that must be provided
    --
        //   - lazily on next llama_decode()
        // p0 < 0 : [0,  p1]
        // p1 < 0 : [p0, inf)
        DEPRECATED(LLAMA_API void llama_kv_self_seq_add(
    --
        //   - lazily on next llama_decode()
        // p0 < 0 : [0,  p1]
        // p1 < 0 : [p0, inf)
        DEPRECATED(void llama_kv_self_seq_div(
    --
        //   - lazily on next llama_decode()
        DEPRECATED(LLAMA_API void llama_kv_self_defrag(struct llama_context * ctx),
                "simply remove this call, the context will automatically decide when to do a defragmentation based on 'defrag_thold'");
    
    --
                "simply remove this call, updates are applied lazily on the next llama_decode()");
    
        //
        // State / sessions
    --
        // The position of the tokens will be tracked automatically by llama_decode
        //
        // NOTE: this is a helper function to facilitate transition to the new batch API - avoid using it
        //
    --
        // In contrast to llama_decode() - this call does not use KV cache.
        // For encode-decoder contexts, processes the batch using the encoder.
        // Can store the encoder output internally for later use by the decoder's cross-attention layers.
        //   0 - success
    --
        LLAMA_API int32_t llama_decode(
                struct llama_context * ctx,
                  struct llama_batch   batch);
    
    --
        // If true, all model tensors are activated during llama_decode() to load and cache their weights.
        LLAMA_API void llama_set_warmup(struct llama_context * ctx, bool warmup);
    
        // Set abort callback
    --
        // Token logits obtained from the last call to llama_decode()
        // The logits for which llama_batch.logits[i] != 0 are stored contiguously
        // in the order they have appeared in the batch.
        // Rows: number of tokens for which llama_batch.logits[i] != 0
    --
        //        llama_decode(ctx, batch);
        //
        //        // sample from the logits of the last token in the batch
        //        const llama_token id = llama_sampler_sample(smpl, ctx, -1);
    --
        //LLAMA_API void llama_decode_with_sampler(struct llama_context * ctx, struct llama_sampler * smpl, struct llama_batch batch, ...);
    
        //
        // Model split

## 🔍 EOS Token Macro or Function
        LLAMA_API llama_token llama_vocab_eos(const struct llama_vocab * vocab); // end-of-sentence
        DEPRECATED(LLAMA_API llama_token llama_token_eos(const struct llama_vocab * vocab), "use llama_vocab_eos instead");

## 🔍 All llama_token_to_piece Variants
        LLAMA_API int32_t llama_token_to_piece(
                  const struct llama_vocab * vocab,
                               llama_token   token,
                                      char * buf,
                                   int32_t   length,
                                   int32_t   lstrip,
