## 🚀 Build & Run

### Quick Start (justfile)

🚀 Usage

    just dev — Run interactively (fast)

    just build — Full production LTO + bindings

    just run "Tell me a joke" — Pass input directly to your runner

    just bindings — Just regen bindings

    just env — Show versions

    just clean — Clear target/


This compiles the project and runs CMake if required. Will link `llama.cpp` as static lib.


---
### 🔁 Run the Nightly (beta)

Use Rustup:

**Set Overrides**

```bash
rustup install nightly
rustup default nightly          # Make nightly your global default
rustup override set nightly     # Only use nightly in the current folder
```

**Unset Overrides**
```bash
rustup default stable
rustup override unset
```

---

### 🔁 Rebuild with Bindings Regeneration

To regenerate FFI bindings from `wrapper.h`:

**Without +nightly**

```bash
REGEN_BINDINGS=1 cargo build --release
```

**With +nightly**

```bash
REGEN_BINDINGS=1 cargo +nightly build --release
```

### 🏃 Run the Binary

```bash
cargo run --release
```

This launches the model runner CLI. Follow on-screen prompts to enter questions.

---

### 🔍 Debug Build

```bash
RUST_BACKTRACE=1 cargo build -vv
RUST_BACKTRACE=1 cargo run -vv
```

---

## 🔄 Reset Bindings (if `bindings.rs` breaks)

Backup the old bindings:

```bash
## Optonal
rm -rf src/tools/bindings.rs
## Recommended
mv src/tools/bindings.rs src/tools/bindings.backup.rs
```

Then regenerate with:

```bash
REGEN_BINDINGS=1 cargo build --release
```

---

## 📁 File Structure Overview

```
src/
  main.rs                # Entry point: CLI prompt → model decode
  tools/
    batch.rs             # Token batching logic
    bindings.rs          # Auto-generated FFI bindings
    mod.rs               # Tools mod root
wrapper.h                # C header for bindgen
build.rs                 # Rust build script (CMake + bindgen)
```

---

## 🧠 Notes

* Make sure your `main.rs` os pointing to a `.gguf` model
* Make sure `llama.cpp` is in `src/model/engines/llama.cpp`

* Bindings regenerate only if:
  * `src/tools/bindings.rs` does not exist

* Supports static linking (`.a` files) for full offline compatibility
* Will use Ninja for fast parallel CMake builds

---

