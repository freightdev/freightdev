A **crate** is the smallest unit of Rust code compilation—it’s either

* a library crate (has a `src/lib.rs`)
* or a binary crate (has a `src/main.rs` or a file under `src/bin/*.rs`)

A **package** is a set of one or more crates that share a single `Cargo.toml`.  By convention:

* A package can contain *one* library crate and *zero or more* binary crates.
* The package root is the directory with your `Cargo.toml`.

In your tree:

```
llama-runner/             ←–– package (v0.1.0)
├── Cargo.toml
├── src/
│   ├── lib.rs            ←–– library crate root
│   ├── main.rs           ←–– default binary crate
│   └── bin/              ←–– extra binaries
│       ├── batch_decode.rs
│       ├── batch_test.rs
│       └── model_check.rs
│
└── wrapper.h            ←–– foreign header for your FFI
```

### 1. How Rust sees this

* **Library crate**:

  * Entry point: `src/lib.rs`
  * Accessible by other Rust crates via `llama_runner = { path = "../llama-runner" }` in their `Cargo.toml`.
* **Default binary**:

  * Entry point: `src/main.rs`
  * Built with `cargo run` (alias for `cargo run --bin llama-runner`).
* **Additional binaries**:

  * Each file in `src/bin/` becomes its own executable, e.g. `cargo run --bin batch_decode`.

All of these share the same `Cargo.toml` (same version, same dependencies)—that’s what makes them a *package*.

### 2. When to split into multiple packages/crates

You’d introduce a new package (with its own `Cargo.toml`) when:

* **Different release cycles**
  You want to version your FFI bindings separately from your core logic.
* **Reusability**
  You have a core library that you’d like other projects to consume without dragging in unrelated binaries.
* **Compile-time isolation**
  Very large codebases can benefit from smaller crates so that incremental rebuilds only recompile changed crates.
* **Clear separation of concerns**
  e.g.

  * `bindings/` crate purely for `bindgen`-generated FFI bindings
  * `core/` crate for safe, high-level Rust wrappers around those bindings
  * `cli/` crate for your command-line tools

#### Example split

```
projects/
└── llama-runner/        ← workspace root (no src/, just Cargo.toml & Cargo.lock)
    ├── Cargo.toml       ← defines a [workspace]
    ├── bindings/        ← package #1: unsafe FFI bindings
    │   ├── Cargo.toml   ← crate = library
    │   └── src/lib.rs
    ├── core/            ← package #2: safe wrappers + tokenizer + runners
    │   ├── Cargo.toml   ← crate = library
    │   └── src/lib.rs
    └── cli/             ← package #3: binaries for batch_decode, interactive, etc.
        ├── Cargo.toml   ← crate = binary (and points to core & bindings as deps)
        └── src/main.rs
```

### 3. Workspaces

If you split into multiple packages, use a **workspace** to tie them together:

```toml
# llama-runner/Cargo.toml
[workspace]
members = [
  "bindings",
  "core",
  "cli",
]
```

* You build everything with `cargo build` at the workspace root.
* Shared dependencies get deduped.
* Versioning and publishing remain independent per package.

### 4. Guidelines for “what to split”

1. **Single Responsibility**
   If a directory (or module tree) is solving a conceptually distinct problem, consider a separate crate.
2. **Reusability**
   If you could reuse code elsewhere (e.g. loaders, prompts, tokenizers), put it in its own library crate.
3. **Compilation time**
   Very large crates slow down incremental builds; splitting can help.
4. **Release boundaries**
   If you’d ever want to bump versions separately (e.g. FFI bindings vs. high-level API), split them now.

---

In your current layout, you have one package with:

* **All your modules** under one library (`lib.rs`)
* **Three binaries** under `src/bin/`

That’s perfectly fine for a small-to-medium project. When it grows—if you find you want to publish the bindings separate from your core logic, or you want lighter installs of just the CLI—you can refactor into a workspace as shown above.
