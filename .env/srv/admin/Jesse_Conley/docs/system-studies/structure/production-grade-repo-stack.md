project-root/
├── .vscode/                  # Editor-specific settings, keybindings, launch configs
│   ├── settings.json         # Repo-specific VS Code settings (formatting, lint rules)
│   ├── extensions.json       # Recommended extensions for this project
│   ├── launch.json           # Debugger launch configs
│   └── tasks.json            # Build/test tasks for VS Code's Task Runner
│
├── src/                      # Main application source code
│   ├── app/                  # Core app logic / features
│   ├── components/           # UI components (if frontend)
│   ├── services/             # API calls, business logic, integrations
│   ├── utils/                # Shared utility functions
│   └── index.(ts|js|go|py)   # Entry point
│
├── tests/                    # Unit/integration/e2e tests
│   ├── __mocks__/            # Mock data/services
│   ├── integration/          # Integration tests
│   └── unit/                 # Unit tests
│
├── scripts/                  # Automation scripts (build, deploy, migrations, cleanup)
│   ├── build.sh
│   ├── deploy.zsh
│   └── index-yaml.sh
│
├── config/                   # Environment configs (dev/staging/prod)
│   ├── default.json
│   ├── development.json
│   ├── production.json
│   └── local.json
│
├── public/                   # Static assets (frontend apps)
│   ├── index.html
│   ├── favicon.ico
│   └── images/
│
├── docs/                     # Project documentation
│   ├── architecture.md
│   ├── api.md
│   └── setup.md
│
├── .env.example              # Environment variables template
├── .gitignore                # Git ignore rules
├── .editorconfig             # Cross-editor formatting rules
├── .prettierrc                # Prettier code style
├── .eslintrc.json             # ESLint config (if JS/TS)
├── Dockerfile                 # Container build instructions
├── docker-compose.yml         # Local container setup
├── Makefile / justfile        # Task automation
├── package.json / pyproject.toml / Cargo.toml / go.mod   # Dependency manager file
├── README.md                  # Project overview
└── LICENSE                    # License info
