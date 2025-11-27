| Use Case            | What You Can Build                                                     |
| ------------------- | ---------------------------------------------------------------------- |
| 🔐 Security         | Encrypt prompt history, gated access to model                          |
| 🎮 Games            | NPCs that respond using a local model                                  |
| 🧰 Tools            | Local agent CLI (e.g. dev assistant, planning tool)                    |
| 📟 APIs             | Wrap it into a JSON HTTP server or WebSocket                           |
| 📱 Mobile           | Embed into a Rust-powered mobile app with Tauri or Rust-native wrapper |
| 🪵 Logging          | Intercept tokens, trace memory, log decisions for analysis             |
| 🧠 RL / Fine-tuning | Modify sampling, apply reinforcement logic, auto-labeling tools        |

| Goal                   | Tooling                                                   |
| ---------------------- | --------------------------------------------------------- |
| 🧠 Add multi-turn chat | Track KV cache + token history                            |
| 🧵 Add streaming       | Use `llama_decode` in a loop, print tokens one-by-one     |
| 🌐 Build an API        | Wrap it in `axum`, `warp`, or `actix-web`                 |
| 🎛 Add control knobs   | Token limits, temperature, top-p, frequency penalty       |
| 🔐 Lock it             | Use `ring` or `aes-gcm` to encrypt unlock keys            |
| 🧪 Add tests           | Use `proptest` or `quickcheck` to fuzz prompt input       |
| 🖼 Serve a UI          | Hook into `tauri`, `leptos`, or `yew` for local UI        |
| ⚡ Speed tune          | Profile with `perf`, `flamegraph`, or `cargo instruments` |

| Capability                  | What It Means                                        |
| --------------------------- | ---------------------------------------------------- |
| 🧠 `llama_tokenize()`       | Convert raw strings to tokens with full vocab access |
| ⚙️ `llama_decode()`         | Feed batches to the model, run inference manually    |
| 🧵 `llama_kv_*`             | Work with memory state (KV cache) per session        |
| 🔁 `llama_sampler_*`        | Control temperature, repetition penalty, top-p, etc. |
| 📤 `llama_token_to_piece()` | Convert model outputs back to text                   |
| 🗂 Load multiple models     | Swap GGUF files on the fly in Rust logic             |
| 🔐 Bind it to system        | Lock model behind AES, tokens, license, etc.         |
| 🚀 Fully offline              | No Python, no servers, no PyTorch or CUDA required   |
