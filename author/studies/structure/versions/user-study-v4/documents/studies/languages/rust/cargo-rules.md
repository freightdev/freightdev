Below is a **minimal but complete workspace map** that will carry your entire stack (MARK, FED, OpenHWY, ELDA, etc.) without forcing refactors later.  Treat each bullet as a *crate directory* under `packages/`.

---

## 0 Shared Infrastructure

| Crate        | Type       | Why it exists                                                                                              |
| ------------ | ---------- | ---------------------------------------------------------------------------------------------------------- |
| **common**   | lib        | `Result`, error enums, telemetry, tracing setup.  Every other crate depends on this one—never the reverse. |
| **config**   | lib        | Reads `*.toml`, env, CLI flags; merges at runtime.                                                         |
| **database** | lib        | Connection pool + migration helpers (uses `sqlx` or `sea‑orm`).                                            |
| **auth**     | lib        | JWT / key‑pair validation, shared between CLI/API.                                                         |
| **macros**   | proc‑macro | One place for `derive(Error)`, `instrument`, etc.                                                          |

---

## 1 MARK (Markdown Agent Routing Kernel)

| Crate          | Type | Depends on                                                                 |
| -------------- | ---- | -------------------------------------------------------------------------- |
| **mark\_core** | lib  | `common`, `config`, `database`                                             |
| **mark\_cli**  | bin  | `mark_core`, `common`, `clap`                                              |
| **mark\_api**  | bin  | `mark_core`, `common`, `axum`                                              |
| **mark\_lang** | lib  | grammar & parser for `.mark`, `.marker`, `.mds` files; used by `mark_core` |

---

## 2 OpenHWY (TMS / License Hub)

| Crate             | Type | Depends on                             |
| ----------------- | ---- | -------------------------------------- |
| **openhwy\_core** | lib  | `common`, `config`, `database`, `auth` |
| **openhwy\_api**  | bin  | `openhwy_core`, `common`, `axum`       |
| **openhwy\_cli**  | bin  | `openhwy_core`, `common`, `clap`       |

---

## 3 FED (Dispatcher SaaS)

| Crate         | Type | Depends on                   |
| ------------- | ---- | ---------------------------- |
| **fed\_core** | lib  | `common`, `openhwy_core`     |
| **fed\_api**  | bin  | `fed_core`, `common`, `axum` |
| **fed\_cli**  | bin  | `fed_core`, `common`, `clap` |

---

## 4 ELDA (Guardian AI)

| Crate          | Type | Depends on                    |
| -------------- | ---- | ----------------------------- |
| **elda\_core** | lib  | `common`, `openhwy_core`      |
| **elda\_api**  | bin  | `elda_core`, `common`, `axum` |

---

## 5 Tooling / Orchestration

| Crate              | Type | Purpose                                                     |
| ------------------ | ---- | ----------------------------------------------------------- |
| **scripts**        | bin  | Small one‑off helpers (e.g., DB seed, migrations, backups). |
| **benchmarks**     | bin  | Criterion or `iai` performance harnesses for core crates.   |
| **wasm\_bindings** | lib  | Wrap selected core functions for WASM (browser, WASI).      |

---

## 6 Front‑End (if you embed Rust)

If you need SSR or WASM components with Leptos/Yew:

| Crate        | Type    | Depends on                                                           |
| ------------ | ------- | -------------------------------------------------------------------- |
| **web\_app** | bin/lib | `mark_core`, `fed_core`, `elda_core` plus Leptos/Yew/Tauri as needed |

---

### How to Wire the Workspace

```toml
# Cargo.toml at repo root
[workspace]
members = [
  "packages/common",
  "packages/config",
  "packages/database",
  "packages/auth",
  "packages/macros",

  "packages/mark/core",
  "packages/mark/cli",
  "packages/mark/api",
  "packages/mark/lang",

  "packages/openhwy/core",
  "packages/openhwy/cli",
  "packages/openhwy/api",

  "packages/fed/core",
  "packages/fed/cli",
  "packages/fed/api",

  "packages/elda/core",
  "packages/elda/api",

  "packages/tooling/scripts",
  "packages/tooling/benchmarks",
  "packages/tooling/wasm_bindings",

  # optional front‑end:
  # "packages/web_app",
]
resolver = "2"
```

---

### Naming Rules Recap

1. **`<domain>_core`** → pure business logic.
2. **`<domain>_cli`**  → clap parser + dispatch to core.
3. **`<domain>_api`**  → HTTP server (axum/actix) exposing core.
4. **Cross‑cutting crates** (`common`, `config`, `auth`, `macros`, `database`) live at top level and have **no dependency** on domain cores.

Follow this map and you’ll never paint yourself into a corner.
