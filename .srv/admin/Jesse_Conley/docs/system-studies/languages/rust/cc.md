The **`cc` crate** is a small build-dependency that lets you compile and link C (and C++) source files as part of your Rust build process. It’s commonly pulled in under your `build.rs` script whenever you need to:

* Ship or wrap existing C/C++ code (e.g. a native library you bundle with your crate).
* Generate bindings (via `bindgen`) against a C/C++ API.

---

## How it works

1. **Add it as a build-dependency** in your `Cargo.toml`:

   ```toml
   [build-dependencies]
   cc = "1.0"
   ```

2. **Invoke it in `build.rs`**:

   ```rust
   // build.rs
   fn main() {
       // Create a new compiler invocation…
       cc::Build::new()
           // …add one or more C/C++ source files…
           .file("src/native/foo.c")
           .file("src/native/bar.c")
           // …optionally add include paths, defines, compiler flags…
           .include("src/native/include")
           .define("ENABLE_FEATURE_X", None)
           .flag_if_supported("-std=c11")
           // …and finally compile into a static lib named "native"
           .compile("native");
   }
   ```

   Under the hood it:

   1. Picks your system’s C/C++ compiler (`cc`/`gcc`/`clang` on Unix, `msvc` on Windows).
   2. Runs the necessary compile commands.
   3. Emits a `libnative.a` (or `.lib`) that Cargo automatically links into your Rust crate.

---

## Why “heavy”?

* **Compile-time cost**: Every time you change a C source file, `cc` will re-compile it.
* **Platform complexity**: Handling include paths, compiler flags, cross-compilation quirks.
* **Native toolchain dependency**: You must have a C/C++ compiler installed and correctly configured.

---

### When to watch out

* If your crate only needs pure-Rust functionality, avoid pulling in `cc`.
* If you do need it, consider isolating all your C/C++ code into a dedicated crate (or feature) so that consumers who don’t need native code won’t pay the build-time cost.

---

In short, **`cc`** is the standard Rust way to build and bundle C/C++ code alongside your Rust code via `build.rs`.
