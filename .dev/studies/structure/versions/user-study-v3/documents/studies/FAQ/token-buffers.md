# Token Buffers

**Token buffers** are memory structures used to store and manage **tokens**—the fundamental units of data in language models like `llama.cpp`—during inference or generation.

---

## 🧠 What Are Tokens?

In LLMs, a **token** is typically:

* A word, subword, or character
* An integer ID (e.g., `1337` = "Hello")

Example:

```
Input: "I love AI"
Tokens: [121, 456, 789]
```

---

## 🧰 So What Is a Token Buffer?

A **token buffer** is a data structure that holds:

* 🔢 A sequence of token IDs
* 📍 Their positions (for context tracking)
* 🧬 Optional metadata (e.g., sequence ID, batch index, attention mask)

Think of it like a **playlist** of tokens ready to be played by the model.

---

### In `llama.cpp` + Rust FFI Context:

In your Rust wrapper, a token buffer might be represented like this:

```rust
pub struct BatchBuffers {
    pub batch: llama_batch,
    _tokens: Vec<llama_token>,
    _positions: Vec<llama_pos>,
    _seq_ids: Vec<llama_seq_id>,
    _seq_id_ptrs: Vec<*mut llama_seq_id>,
}
```

This is essentially the **input payload** you feed into `llama_decode()`.

---

## 📦 What It’s Used For

* **Prompt Encoding:** Store the encoded version of user input
* **Streaming Generation:** Hold tokens for streaming output
* **Feedback Loop:** Reuse previous tokens for continued generation

---

## 🔄 Lifecycle of a Token Buffer

1. **Tokenize Input:** Turn text into token IDs
2. **Fill the Buffer:** Push tokens, positions, sequence IDs
3. **Run Inference:** Pass to `llama_decode()`
4. **Get Output Token:** From sampler → append to buffer
5. **Repeat:** Until `llama_token_eos()` or limit reached

---

## 🧠 In Summary:

A **token buffer** is the "working memory" of your LLM session:

* Input buffer → what you want the model to process
* Output buffer → what the model just generated
* These are **core to performance, batching, and streaming**

