## 1. Declarative Macros (`macro_rules!`)

* **What they are**
  Pattern‐matching macros that expand at compile time into Rust code fragments.
* **When to use**

  * Simple repetition or boilerplate elimination where Rust’s syntax patterns suffice.
  * No external dependencies or complex parsing needed.

```rust
// A v! macro to create Vecs conveniently
macro_rules! v {
    ( $( $x:expr ),* $(,)? ) => {
        {
            let mut temp = Vec::new();
            $( temp.push($x); )*
            temp
        }
    };
}

let xs = v![1, 2, 3]; // expands to push calls
```

* **Pros & cons**

  * ✅ No extra crates
  * ✅ Fast compilation
  * ❌ Limited pattern matching (no full Rust AST)
  * ❌ Error messages point at macro definition, not call site

---

## 2. Procedural Macros (Proc-Macros)

Rust code that runs during compilation to generate or transform code. Requires its own crate with `proc-macro = true`.

### 2.1 Derive Macros

* **Syntax**

  ```rust
  #[derive(MyTrait)]
  struct S { /* fields */ }
  ```
* **How it works**
  The derive crate reads the item’s AST via the `syn` crate, generates `impl MyTrait for S { … }` using `quote!`.

```rust
// in my_derive/src/lib.rs
use proc_macro::TokenStream;
use quote::quote;
use syn;

#[proc_macro_derive(HelloWorld)]
pub fn hello_world(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    let name = &ast.ident;
    quote! {
        impl #name {
            pub fn hello() {
                println!("Hello, {}!", stringify!(#name));
            }
        }
    }.into()
}
```

### 2.2 Attribute Macros

* **Syntax**

  ```rust
  #[my_attribute(args…)]
  fn foo() { … }
  ```
* **Use cases**

  * Web-framework routing (e.g. Rocket’s `#[get("/")]`)
  * Test frameworks, custom logging, embedding metadata

### 2.3 Function-Like Macros

* **Syntax**

  ```rust
  let sql = sql_query!("SELECT * FROM users WHERE id = {}", id);
  ```
* **Use cases**

  * Domain-specific languages (DSLs)
  * Compile-time validation or transformation of input tokens

---

## 3. Build-Script Codegen (`build.rs`)

### 3.1 `bindgen` (FFI)

* Generates Rust bindings from C headers:

```rust
// build.rs
fn main() {
    bindgen::Builder::default()
        .header("wrapper.h")
        .generate()
        .expect("bindgen failed")
        .write_to_file("src/bindings.rs")
        .unwrap();
}
```

* **When to use**: wrapping C libraries, auto-regenerating on header change.

### 3.2 `cc` Crate

* Compiles bundled C/C++ code into a static library:

```rust
// build.rs
fn main() {
    cc::Build::new()
        .file("src/native/foo.c")
        .flag_if_supported("-std=c11")
        .compile("native");
}
```

* **When to use**: shipping C code alongside your Rust crate.

### 3.3 Protobuf/GRPC Codegen

* **`prost` / `tonic-build`**:

```rust
// build.rs
fn main() {
    tonic_build::configure()
        .compile(&["proto/service.proto"], &["proto"])
        .unwrap();
}
```

* **When to use**: generating Rust types and client/server stubs from `.proto` files.

---

## 4. Trade-Offs & Best Practices

| Technique                  | Compile-Time Cost | Flexibility               | Typical Use Case               |
| -------------------------- | ----------------- | ------------------------- | ------------------------------ |
| `macro_rules!`             | Low               | Pattern-based only        | Simple repetition/boilerplate  |
| Proc-Macros (derive)       | Medium–High       | Full AST manipulation     | `serde`, framework DSLs        |
| Proc-Macros (attr/fn-like) | High              | Custom DSLs, routing      | Web frameworks, complex macros |
| `build.rs` codegen         | Medium            | External tool integration | FFI, protobuf, code generation |

1. **Isolate heavy codegen**

   * Gate behind Cargo **features** (`default-features = false`)
   * Put in a **separate crate** so only consumers that need it pay the cost.

2. **Limit API surface**

   * Keep tokens and generated modules behind private modules.
   * Re-export a minimal, stable set of `pub` items.

3. **Measure impact**

   * Use `cargo +nightly build --timings`
   * Use `cargo bloat` and `cargo tree`

4. **Versioning**

   * Any change to a proc-macro’s output or a build-script–generated API should bump the **MAJOR** version (SemVer).

---

## 5. Putting It All Together

* **Start** with `macro_rules!` for trivial cases.
* **Add derive macros** when you need to auto-implement traits (e.g. serialization).
* **Use attribute or function-like proc-macros** for DSLs or routing glue.
* **Leverage `build.rs`** for external codegen (C bindings, Protobuf).
* **Isolate & gate** heavy codegen behind features or separate crates.

By understanding each layer—and when to choose it—you’ll be able to architect a Rust codebase that scales from a tiny utility to a multi-crate workspace without surprising compile-time or maintenance pitfalls.
