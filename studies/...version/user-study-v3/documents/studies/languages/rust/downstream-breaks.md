“Downstream” just means any code or crate that depends on yours. A **downstream break** happens when you change your crate’s **public API** in an incompatible way, so that those dependent crates no longer compile (or suddenly misbehave).

Examples of breaking the downstream:

* **Renaming** a `pub fn foo()` to `pub fn bar()`
* **Changing** the signature of a `pub fn load(path: &str)` to `pub fn load(path: PathBuf)`
* **Removing** a `pub type Model = ...` alias

Any of those will cause `use llama_runner::foo;` in another crate to fail.

By hiding implementation inside non-`pub` modules (e.g. `mod internal { … }`) and only re-exporting a small, stable `pub` surface, you can freely refactor the internals—move things around, rename private items—**without** touching that public layer. Downstream crates keep depending on your stable `pub fn init()`, `pub fn load()`, etc., so they never break.
