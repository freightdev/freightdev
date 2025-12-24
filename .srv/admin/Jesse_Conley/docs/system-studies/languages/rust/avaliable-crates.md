### 🧠 KNOWING EVERYTHING: What You’re Actually Learning

| Concept      | Real Meaning                                            | Crates That Exist                                          | Why You Might Replace It                          |
| ------------ | ------------------------------------------------------- | ---------------------------------------------------------- | ------------------------------------------------- |
| `utils/fn/`  | Micro-ops (formatting, checking, converting, splitting) | `itertools`, `unicode-segmentation`, `regex`, `serde_json` | If you want control, remove deps, or optimize     |
| `macros.rs`  | Local DSL or reusable code-gen tricks                   | `paste`, `macro_rules!`, `proc_macro`                      | Macros are performance-friendly logic injection   |
| `output.rs`  | Human output control                                    | `indicatif`, `console`, `termion`, `crossterm`             | You keep your theme/style consistent              |
| `input.rs`   | How a tool listens                                      | `dialoguer`, `inquire`, `rustyline`                        | Replacing for better UX, CLI interop              |
| `context.rs` | Global object registry or memory pipe                   | `anyhow`, `once_cell`, `tokio::sync::RwLock`               | You’re wiring a stateful runtime by hand          |
| `env.rs`     | Reads `.env` or system vars                             | `dotenv`, `env_logger`                                     | Custom fallback, runtime injection                |
| `config.rs`  | Loads static settings                                   | `config`, `serde`, `toml`, `json5`, `yaml-rust`            | So you control hot-reloading, validation          |
| `path.rs`    | Resolve relative vs absolute, etc.                      | `std::fs`, `path-absolutize`                               | You normalize file flow per system                |
| `metrics.rs` | Basic usage counters                                    | `metrics`, `prometheus`, `opentelemetry`                   | Replacing to reduce overhead or emit custom stats |
| `tree.rs`    | Pretty-print directory or graph                         | `dptree`, `petgraph`, `indextree`, `tabled`                | You show your own hierarchy like Cursor           |

