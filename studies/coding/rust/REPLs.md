**JIT (Just-In-Time) Compilation**

* **When it happens**: At runtime, as the program runs.
* **How it works**: The engine compiles hot or requested code paths on the fly—from an IR or bytecode—into native machine code.
* **Pros**:

  * Can do **runtime profiling** and **specialize** code for the actual workload or CPU features.
  * Enables dynamic languages and plugins (e.g. Java’s HotSpot, V8 for JavaScript, Wasmtime for Wasm).
* **Cons**:

  * **Startup overhead**: you pay a compile cost during execution.
  * **Memory**: you need space for the JIT compiler and generated code.

---

**AOT (Ahead-Of-Time) Compilation**

* **When it happens**: Before execution, typically at build time.
* **How it works**: The entire program (or module) is compiled from source or IR down to machine code in one go, producing a standalone binary or library.
* **Pros**:

  * **Fast startup**—no compile work at runtime.
  * Predictable performance and memory footprint.
  * Simplifies deployment (just ship the binary).
* **Cons**:

  * No opportunity to specialize based on actual runtime data or environment.
  * Larger tuning burden must happen at compile time (you can’t adapt later).

---

### Hybrid Approaches

* **Tiered JIT** (e.g. Java): start with a fast, low-optimization AOT pass or interpreter, then recompile hot spots with heavier optimizations at runtime.
* **AOT + JIT** for Wasm: you might AOT-compile some modules ahead of time and JIT any dynamic plugins or sandboxed user code.

---

### In the Rust Ecosystem

* **Default `rustc` + LLVM** = pure AOT: you get a native binary at `cargo build --release`.
* **`rustc_codegen_cranelift` (experimental)** can target AOT or JIT via Cranelift.
* **Wasmtime** uses Cranelift under the hood to JIT-compile Wasm modules at runtime, trading off a little peak perf for *very* fast startup.

You choose **AOT** when you need fast startup and a standalone deliverable; you choose **JIT** when you need runtime specialization, plugin loading, or dynamic code generation.
