**Procedural Macros** (“proc-macros”) are Rust’s way to write code that **runs at compile time** and **generates or transforms** Rust code for you. Unlike `macro_rules!` which is purely declarative pattern-matching, proc-macros are small Rust programs that take a token stream in and output a token stream out. There are three varieties:

1. **Derive macros**

   ```rust
   #[derive(Serialize, Deserialize)]
   struct MyStruct { /* … */ }
   ```

   Under the hood, the `serde_derive` proc-macro inspects your struct’s fields and generates `impl Serialize for MyStruct { … }` and `impl Deserialize for MyStruct { … }`.

2. **Attribute macros**

   ```rust
   #[rocket::get("/")]
   fn index() -> &'static str { "Hello" }
   ```

   The `rocket::get` attribute macro rewrites your function into the Rocket framework’s routing boilerplate.

3. **Function-like macros**

   ```rust
   let sql = sql_query!("SELECT * FROM users WHERE id = {}", user_id);
   ```

   A macro like `sql_query!` can parse its input at compile time and emit code that safely binds parameters, builds SQL strings, etc.

---

### Why they’re “heavy”

* **Compile-time work**: Each proc-macro invocation invokes a mini Rust compiler API to parse/expand code. Large codebases with many derives can noticeably slow incremental builds.
* **Opaque errors**: If something goes wrong inside the macro, the compiler errors can be hard to trace back to your own code.
* **Dependency graph**: Pulling in a proc-macro crate like `serde_derive` often brings in its own dependencies (e.g. `syn`, `quote`), which also compile macros.

---

**Code Generation** (codegen) is the broader concept of **automatically producing source code**—either:

* **At compile time**, via proc-macros or build scripts (`build.rs`),
* **Ahead of time**, via external tools (e.g. `bindgen` for C headers, `prost`/`tonic-build` for Protobuf, or your own scripts that output `.rs` files).

#### Examples:

* **`bindgen`** generates Rust FFI bindings from a C header:

  ```rust
  // build.rs
  bindgen::Builder::default()
      .header("wrapper.h")
      .generate()
      .expect("Unable to generate bindings")
      .write_to_file("src/bindings.rs")
      .unwrap();
  ```
* **`prost`** codegen for Protobuf:

  ```rust
  // build.rs
  tonic_build::configure()
      .compile(&["proto/service.proto"], &["proto"])
      .unwrap();
  ```

Both proc-macros and external codegen let you **write less boilerplate** and keep your API surface clean—but they add compile-time cost and complexity, so you often isolate them behind feature flags or in separate crates.
