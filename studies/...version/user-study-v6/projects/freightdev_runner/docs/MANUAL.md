# `manual.md` – FreightDev Runner

This file would give **anyone new on the project** a complete understanding of how it works and that explains the whole system in a way that someone new can understand **everything from structure to build process to adding engines and using features**.

---

## 1️⃣ Overview

**FreightDev Runner** is a high-performance Rust-based framework for running multiple inference engines (starting with LLaMA.cpp) through **FFI (Foreign Function Interface) bindings**.
The goal is to provide a **modular, engine-agnostic runner** that can:

* Build engines from source automatically
* Compile wrapper C/C++ code for Rust interoperability
* Link and optimize per platform (Windows, Linux, macOS)
* Generate Rust bindings for safe interaction with native code
* Support optional GPU/CPU backends and parallelism
* Optionally target WASM or other architectures

Think of it as a **universal model runner** with pluggable engines.

---

## 2️⃣ Project Structure

```
freightdev_runner/
├── Cargo.toml           # Rust package manifest
├── build.rs             # Master build script (engine/build orchestrator)
├── libs/                # Third-party or custom libraries
│   ├── include/
│   │   ├── llama_wrapper.h
│   │   └── llama_wrapper.c
│   └── engine/          # Engines, e.g., llama.cpp
│       └── llama.cpp/
├── src/
│   ├── lib.rs           # Main Rust library API
│   ├── main.rs          # Binary entry point
│   └── bindings/        # Generated Rust bindings from FFI
│       └── ffi_llama_cpp.rs
└── README.md
```

**Notes:**

* `libs/include` → wrapper headers & sources
* `libs/engine` → source code of engines (LLaMA.cpp, etc.)
* `src/bindings` → Rust bindings generated via bindgen
* `build.rs` → orchestrates everything: builds engines, wrapper code, linking, generates bindings

---

## 3️⃣ How It Builds

1. **Build script (`build.rs`)** is executed automatically during `cargo build`.
2. Steps inside `build.rs`:

   ### 3.1 Find or Clone Engine

   * Looks for `libs/engine/llama.cpp`
   * If not found → clones from GitHub

   ### 3.2 Build Engine

   * Uses **CMake** for LLaMA.cpp
   * Configures build based on feature flags:

     | Feature      | Effect                        |
     | ------------ | ----------------------------- |
     | `cuda`       | Enable CUDA GPU backend       |
     | `metal`      | Enable Apple Metal GPU        |
     | `rocm`       | Enable AMD GPU (ROCm)         |
     | `vulkan`     | Enable Vulkan GPU             |
     | `blas`       | Enable CPU BLAS optimizations |
     | `openmp`     | Enable OpenMP multi-threading |
     | `mkl`        | Intel MKL BLAS optimizations  |
     | `accelerate` | Apple Accelerate library      |

   ### 3.3 Build Wrapper C Code

   * Compiles `llama_wrapper.c` into a static library for Rust to link
   * Sets platform-specific compiler flags
   * Architecture-specific optimizations: `x86_64`, `aarch64`

   ### 3.4 Setup Linking

   * Adds library search paths for Rust (`cargo:rustc-link-search`)
   * Links necessary static/dynamic libraries (platform-specific)

   ### 3.5 Generate Bindings (via bindgen)

   * Converts C/C++ headers into safe Rust API in `src/bindings/`
   * Only runs if `regen-bindings` feature is enabled or if headers changed

---

## 4️⃣ Feature Flags

**Cargo features allow selective builds and optimizations:**

| Feature          | Description                           |
| ---------------- | ------------------------------------- |
| `cuda`           | Build CUDA GPU backend                |
| `metal`          | Build Metal backend (macOS)           |
| `rocm`           | Build AMD ROCm backend                |
| `vulkan`         | Build Vulkan GPU backend              |
| `blas`           | CPU BLAS optimization                 |
| `openmp`         | Multi-threading via OpenMP            |
| `mkl`            | Intel MKL BLAS                        |
| `accelerate`     | Apple Accelerate CPU optimizations    |
| `async`          | Enable Tokio runtime                  |
| `parallel`       | Enable Rayon parallelism              |
| `mmap`           | Enable memory-mapped file access      |
| `config-file`    | Optional configuration via file       |
| `regen-bindings` | Regenerate Rust bindings from headers |
| `logging`        | Enable log/env\_logger                |

**Examples:**

* CPU-only build:

```bash
cargo build --release --features "blas openmp"
```

* GPU-enabled build on CUDA machine:

```bash
cargo build --release --features "cuda parallel"
```

---

## 5️⃣ Adding a New Engine

1. Place engine source in `libs/engine/<engine_name>`
2. Add wrapper headers in `libs/include/<engine_name>_wrapper.h` and `.c`
3. Add a new feature flag in `Cargo.toml`
4. Add a build function in `build.rs`:

```rust
#[cfg(feature = "openvino")]
fn build_openvino(...) { ... }
```

5. Call this function from `main()` if the feature is enabled

> This makes the build system modular and future-proof for multiple engines.

---

## 6️⃣ Using the Runner

* **Library usage:** call the Rust API in `src/lib.rs`
* **Binary usage:** `freightdev-runner` executable defined in Cargo.toml
* Access model inference functions through the generated bindings

**Example:**

```rust
use freightdev_runner::inference::*;

let model = LlamaModel::load("model.bin");
let result = model.predict("Hello world!");
```

---

## 7️⃣ WASM (Optional)

* Current `build.rs` is **native-only** (C/C++ compilation)
* To target WASM:

  1. Compile engines separately to WASM (Emscripten or Rust-native)
  2. Use a `wasm/` folder with its own Cargo.toml
  3. Expose FFI through `wasm-bindgen`

> WASM requires separate handling; wrapper C code generally cannot compile directly to WASM.

---

## 8️⃣ Master Build Philosophy

* **Single orchestrator (`build.rs`)** handles all engines based on features
* **Dynamic adaptation** based on OS, architecture, and enabled backends
* Modular enough to add new engines without touching existing code
* Feature flags let you build exactly what you need (CPU/GPU/backends)
* Regenerating bindings ensures Rust always matches C/C++ headers

---

## 9️⃣ Quick Commands

```bash
# Build CPU-only
cargo build --release --features "blas openmp"

# Build with CUDA GPU
cargo build --release --features "cuda parallel"

# Regenerate bindings
cargo build --release --features "regen-bindings"

# Run binary
cargo run --release
```