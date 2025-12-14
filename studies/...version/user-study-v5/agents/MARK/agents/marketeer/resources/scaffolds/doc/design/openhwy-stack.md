.vscode/
├── settings.json            # Global editor settings (formatting, IntelliSense)
├── extensions.json          # Recommended extensions for team consistency
├── launch.json              # Debug configurations (Rust, Node, CLI)
└── tasks.json               # One-click build, test, lint, dev scripts
openhwy/
├── apps/                              # 🖥️ Production-facing apps (UIs only)
│   ├── fed/                           # fedispatching.com - Next.js + Expo + Solito
│   ├── elda/                          # 8teenwheelers.com - Vite (PWA)
│   ├── hwy/                           # open-hwy.com - Vite (PWA)
│   └── docs/                          # Developer & platform documentation site
│
├── crates/                            # 🦀 Rust crates — compiled, tested, reused
│   ├── api/                           # Axum/Actix-powered backend (REST or GraphQL)
│   ├── sdk/                           # Rust SDK consumed by API, CLI, tools
│   ├── ledger/                        # Ledger + keychain trust layer (KCBB/RCBB)
│   ├── auth/                          # Auth tokens, sessions, permission maps
│   ├── agent/                         # MARK protocol runtime logic (toolgraph, tasks)
│   ├── cli/                           # CLI entrypoint (MARK, dev tools, agent exec)
│   └── runtime/                       # Orchestrator, batch runners, container logic
│
├── packages/                          # 📦 Shared frontend packages (TS/JS only)
│   ├── ui/                            # Atomic UI kit (shadcn + Tailwind + Expo-compatible)
│   ├── app/                           # Shared wrappers (AppProvider, NavRouter, etc)
│   ├── hooks/                         # React + Native-safe hooks (auth, agent, session)
│   ├── state/                         # Zustand/Jotai/Store logic
│   ├── types/                         # Shared TypeScript types (schemas, DTOs)
│   ├── utils/                         # Generic helpers (dates, currency, ID, etc.)
│   ├── prompts/                       # AI prompt templates (system, tools, tasks)
│   ├── theme/                         # Theme provider + switch logic
│   ├── tokens/                        # Design tokens (colors, spacing, elevation)
│   ├── assets/                        # Logos, icons, badges
│   ├── i18n/                          # Translations and locale tools
│   ├── markdown/                      # MDX/Markdown renderers, parsers
│   ├── bridge/                        # Web ↔ Native ↔ CLI runtime adapters
│   ├── config/                        # Shared configs (eslint, tailwind, tsconfig)
│   ├── tailwind/                      # Tailwind plugin presets + themes
│   ├── network/                       # Tailscale, Caddy, Cloudflare helpers
│   ├── telemetry/                     # Event tracking, error reporting, logging
│   └── cache/                         # Redis/localStorage caching logic
│
├── tools/                             # 🔧 Scripts, automation, local dev helpers
│   └── scripts/
│       ├── agents/                    # MARK agent indexing, testing, validation
│       ├── assets/                   # Download/validate asset packs
│       ├── bindings/                 # Rust FFI bindgen tools (regen, watch)
│       ├── build/                    # Compile, release, production bundling
│       ├── check/                    # Header check, integrity validations
│       ├── ci/                       # Git, merge, release automation
│       ├── convert/                  # Tokenizer/model format conversion
│       ├── dev/                      # Tree tools, import fixers, folder utilities
│       │   └── ui/                   # UI atomic ops (generate, validate, barrel)
│       ├── docs/                     # Build/lint Markdown, index READMEs
│       ├── env/                      # Platform detection, CUDA/Metal setup
│       ├── model/                    # Model downloads, validation, indexing
│       ├── prompt/                   # Prompt indexers
│       ├── reset/                    # Wipe/reset repo
│       ├── run/                      # Batch runs, local dev tests
│       └── setup/                    # Bootstrap scripts, full env setup
│
infra/
├── environments/                     # 🌍 Environment-specific overrides/configs
│   ├── dev/
│   │   ├── k8s-values.yaml
│   │   ├── cloudflare-override.toml
│   │   └── .env.dev
│   ├── staging/
│   │   ├── k8s-values.yaml
│   │   └── .env.staging
│   └── prod/
│       ├── k8s-values.yaml
│       └── .env.prod
│
├── k8s/                              # ☸️ Kubernetes base manifests and Helm charts
│   ├── base/                         # Core openhwy deployment manifests
│   │   ├── api/
│   │   │   ├── deployment.yaml
│   │   │   └── service.yaml
│   │   ├── fed/
│   │   ├── elda/
│   │   ├── hwy/
│   │   ├── ingress.yaml
│   │   └── secrets.yaml
│   └── charts/                       # Optional Helm charts
│       └── openhwy/
│           ├── Chart.yaml
│           ├── values.yaml
│           └── templates/
│               └── (chart templates...)
│
├── docker/                           # 🐳 All Docker-related logic and multi-target images
│   ├── api.Dockerfile
│   ├── cli.Dockerfile
│   ├── runner.Dockerfile
│   ├── base.Dockerfile
│   └── docker-compose.override.yml
│
├── cloudflare/                       # 🌐 DNS, Zero Trust Tunnels, Routing
│   ├── tunnels/
│   │   ├── dev-tunnel.yml
│   │   └── prod-tunnel.yml
│   ├── rules/
│   │   ├── firewall-rules.json
│   │   └── cache-rules.json
│   └── wrangler.toml
│
├── tailscale/                        # 🔐 Mesh VPN config
│   ├── ACLs/
│   │   └── openhwy-acl.json
│   ├── routes/
│   │   └── route-map.yaml
│   └── tailscale-up.sh
│
├── terraform/                        # 🛠️ Infra as Code (optional, for provisioning)
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── providers.tf
│
└── README.md                         # Infra overview and bootstrapping instructions
│
.github/
├── workflows/                             # 🚀 All GitHub Actions pipelines
│   ├── ci.yml                             # Main CI: lint, test, typecheck
│   ├── cd.yml                             # CD: builds + deploys (K8s, Docker, Cloudflare)
│   ├── rust.yml                           # Rust-specific (crates build/test/check)
│   ├── node.yml                           # TS-specific (packages lint/test/typecheck)
│   ├── preview.yml                        # PR preview builds (Vercel / Netlify / Docker)
│   ├── docker-publish.yml                 # DockerHub / GHCR publishing (tagged releases)
│   └── agent-test.yml                     # MARK agent runtime testing (prompt graph)
│
├── dependabot.yml                         # 🔄 Auto update Rust crates, NPM packages, etc.
├── codeql.yml                             # 🔐 Optional: GitHub Advanced Security scanning
├── ISSUE_TEMPLATE/                        # 📝 Issue templates for contributors/devs
│   ├── bug_report.md
│   ├── feature_request.md
│   └── task_request.md
├── PULL_REQUEST_TEMPLATE.md               # ✅ Required checklist for all PRs
├── FUNDING.yml                            # 💵 (Optional) GitHub Sponsors, OpenCollective, etc.
└── SECURITY.md                            # 🔒 Disclosure policy, contact, response flow
│
├── tests/                             # 🧪 High-level or integration test suites
│   ├── api_contract/
│   ├── ledger_flow/
│   └── agent_graph/
│
├── Cargo.toml                         # Rust workspace config
├── turbo.json                         # Turborepo pipeline config
├── tsconfig.base.json                 # Shared TS config
├── pnpm-workspace.yaml                # PNPM workspace definition
├── package.json                       # Root scripts only
└── README.md
