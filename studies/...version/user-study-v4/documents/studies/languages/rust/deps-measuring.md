You judge a dependency’s “weight” by its impact on **compile‐time**, **binary size**, and **transitive dependency graph**. Here’s how to tell:

1. **Inspect the dependency graph**

   ```bash
   cargo tree --edges normal     # shows direct and transitive deps
   cargo tree --duplicates       # flags multiple versions
   ```

   • If pulling in a crate drags in dozens of others transitively, that’s a red flag.

2. **Measure compile‐time impact**

   * **Nightly timing reports**:

     ```bash
     RUSTC_BOOTSTRAP=1 cargo +nightly build --timings
     ```

     Look in `target/timings/` to see which crate takes the longest.
   * **Incremental rebuilds**: change one file in a crate, run `cargo build` again. If it still recompiles most of your workspace, that crate’s “heavy” in rebuild cost.

3. **Check binary size**

   * Use [`cargo bloat`](https://github.com/rust-unofficial/cargo-bloat):

     ```bash
     cargo install cargo-bloat
     cargo bloat --release --crates
     ```

     It shows which crates contribute most to your final `.rlib` or executable.

4. **Watch for build‐script or C code**
   Anything with a `build.rs`, `cc` crate, or C/C++ dependencies often adds significant compile time (and potential platform‐specific complexity).

5. **Proc‐macros and codegen**
   Crates that provide procedural macros (e.g. `serde_derive`, `rocket_codegen`) can be expensive: the macro expansion phase can dominate build time.

6. **Feature flags**
   Many crates ship optional features that pull in extra code. Always audit which features you actually enable:

   ```toml
   [dependencies]
   serde = { version = "1.0", default-features = false, features = ["derive"] }
   ```

   Disabling unneeded features can convert a “heavy” crate into a “light” one.

7. **Local experimentation**
   If you suspect a crate is heavy, try isolating it into its own small project and run:

   ```bash
   time cargo build
   ```

   Compare that to building your full workspace.

---

**Rule of thumb**: if a dependency consistently adds >500 ms to incremental rebuilds or produces >100 KB of code in your binary, consider splitting it into its own crate (or gating it behind a feature) so that consumers who don’t need it aren’t forced to pay that cost.
