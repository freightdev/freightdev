Here’s a **bare‑metal Rust project layout** for a multi‑command CLI (à la `git`, `cargo`, or `kubectl`). Nothing but files + folders so you can see how everything plugs together before you write code.

```text
mark-cli/                       # ← cargo workspace root
├── Cargo.toml                  # workspace definition
├── crates/                     # split into libraries + the final binary
│   ├── core/                   # pure logic, no CLI deps
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── book.rs
│   │       ├── mark.rs
│   │       └── utils.rs
│   │
│   ├── cli/                    # reusable clap wrappers, shared flags
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── flags/
│   │       │   ├── fast.rs
│   │       │   ├── force.rs
│   │       │   ├── parse.rs
│   │       │   └── target.rs
│   │       └── commands/
│   │           ├── book/
│   │           │   ├── create.rs
│   │           │   ├── assign.rs
│   │           │   └── spine.rs
│   │           ├── mark/
│   │           │   ├── create.rs
│   │           │   ├── assign.rs
│   │           │   ├── path.rs
│   │           │   ├── remark.rs
│   │           │   └── step.rs
│   │           └── mod.rs      # `pub use …` re‑exports
│   │
│   └── app/                    # the actual binary target
│       ├── Cargo.toml
│       └── src/
│           ├── main.rs         # only parses CLI + dispatches
│           └── mod.rs          # glue if main gets chunky
│
└── docs/                       # your markdown spec tree
    └── mark/
        └── cli/
            ├── overview/
            ├── commands/
            └── flags/
```

### How the pieces relate

| Layer           | Crate  | Purpose                                          | Depends on                |
| --------------- | ------ | ------------------------------------------------ | ------------------------- |
| **Binary**      | `app`  | `main.rs` → parse CLI (clap) → call `cli::*`     | `cli`, `core`             |
| **CLI helpers** | `cli`  | All flags & sub‑command structs (clap v4 derive) | `core` for business logic |
| **Logic**       | `core` | Pure, testable functions. No clap here.          | *nothing* (std only)      |

### Typical `main.rs`

```rust
use cli::Cli;             // re‑exported root clap struct
use cli::dispatch;        // fn that routes to core

fn main() {
    // parse args → Enum with sub‑commands
    let cli = Cli::parse();
    if let Err(e) = dispatch(cli) {
        eprintln!("❌ {e}");
        std::process::exit(1);
    }
}
```

### Why this shape works

* **Unit‑testable** – logic lives in `core`, zero clap or I/O noise.
* **Swappable front‑ends** – tomorrow a TUI or gRPC layer can call the same `core` crate.
* **Docs naturally mirror code** – every folder under `docs/mark/cli/commands/` has a matching module in `cli/src/commands/`.

Copy this skeleton, run `cargo new --lib` / `cargo new --bin` to fill the crates, then wire up each command one by one.
