**SemVer** stands for **Semantic Versioning**, a versioning scheme that conveys meaning about the underlying changes in each release. It uses a three-number format:

```
MAJOR.MINOR.PATCH
```

1. **MAJOR** version (X.0.0)

   * Incremented when you make **incompatible API changes**.
   * Any downstream crate depending on `^MAJOR.*` may break when MAJOR increases.

2. **MINOR** version (0.Y.0)

   * Incremented when you add **backward-compatible functionality** (new features) without breaking existing API.
   * Downstream crates that accept `^MAJOR.MINOR.*` will pick up these safely.

3. **PATCH** version (0.0.Z)

   * Incremented for **backward-compatible bug fixes**.
   * Only correct errors; do not add features or break API.

---

### Why SemVer matters in Rust

* **Cargo’s default version requirement**
  When you write in your `Cargo.toml`

  ```toml
  [dependencies]
  llama_runner = "1.2.3"
  ```

  Cargo interprets that as

  ```text
  >=1.2.3, <2.0.0
  ```

  Meaning it will accept any `1.x.y` release that’s ≥ 1.2.3, but never 2.0.0 or above, because a new MAJOR could break your code.

* **Predictability for downstream crates**
  If your crate follows SemVer strictly, consumers know:

  * **Patch** bumps are safe—only fixes.
  * **Minor** bumps are safe—only additive.
  * **Major** bumps may require them to update their code.

---

### Pre-releases and Build Metadata

You can also have prerelease or build metadata tags:

* **Pre-release**:

  ```
  1.4.0-alpha.1
  ```

  Indicates an unstable, pre-release version.

* **Build metadata** (ignored by version precedence):

  ```
  1.4.0+001234abcd
  ```

---

### Summary

* **SemVer = MAJOR.MINOR.PATCH**
* **MAJOR** → incompatible changes
* **MINOR** → new, backward-compatible features
* **PATCH** → backward-compatible bug fixes

By sticking to SemVer, you ensure that both your **binaries** and any **downstream libraries** can depend on your crate with confidence that versions mean consistent things.
