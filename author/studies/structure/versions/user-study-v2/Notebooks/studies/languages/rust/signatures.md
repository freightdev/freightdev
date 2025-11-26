A **function signature** is the part of a function declaration that specifies:

1. **The function’s name**
2. **Its parameters** (names aren’t important to the caller, but their *types* are)
3. **Its return type**
4. (Optionally) any **generic parameters**, **lifetimes**, or **qualifiers** like `unsafe` or `async`

Everything downstream cares about lives in that signature—if you change any piece of it, code that called your function will fail to compile.

---

### Example

```rust
// Full signature:
pub fn load<P: AsRef<Path>>(path: P) -> Result<Model, Error>
```

Breakdown:

* `pub`                → visibility qualifier
* `fn`                 → declares a function
* `load`               → the function’s name
* `<P: AsRef<Path>>`   → generic parameter `P` bounded by the `AsRef<Path>` trait
* `(path: P)`          → one parameter, named `path`, of type `P`
* `-> Result<Model, Error>`
  → return type: on success you get `Model`, on failure an `Error`

If you changed that to:

```rust
pub fn load(path: &str) -> Option<Model>
```

you’ve altered:

* the parameter type (`&str` instead of `P: AsRef<Path>`)
* the return type (`Option<Model>` instead of `Result<Model,Error>`)

That is a **downstream break**—any code expecting the old `load(...) -> Result<…>` signature will no longer compile until it’s updated.

---

### Why signatures matter

* They are the **contract** you offer to callers.
* Changing them is a **major** version bump under SemVer.
* Keeping your signatures stable (and refactoring implementation behind private modules) means you can evolve your code internally without ever breaking your users’ builds.
