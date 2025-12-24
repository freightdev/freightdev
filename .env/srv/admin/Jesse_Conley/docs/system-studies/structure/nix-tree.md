/etc/nixos
├── configuration.nix              # Main system config (imports modules)
├── hardware-configuration.nix     # Auto-generated hardware setup
├── flake.nix                      # Flake entrypoint (modern Nix)
├── flake.lock                     # Pin versions
├── modules/                       # Custom system modules
│   ├── devtools.nix               # Rust, Go, Node, etc.
│   ├── gpu.nix                    # NVIDIA or AMD setup
│   ├── cuda.nix                   # CUDA install logic
│   ├── infra.nix                  # Infrastructure stack (vault, traefik...)
│   ├── docker.nix                 # Container daemon setup
│   ├── networking.nix             # Networking (tailscale, wireguard...)
│   └── users.nix                  # User accounts, SSH, groups
├── services/                      # Service-specific config
│   ├── postgres.nix
│   ├── vector.nix
│   ├── grafana.nix
│   ├── vault.nix
│   ├── traefik.nix
│   ├── tailscale.nix
│   └── teleport.nix
├── secrets/                       # Encrypted/secure config
│   ├── vault.nix
│   └── ssh-keys.nix
└── overlays/
    └── custom-packages.nix        # Local overrides or private packages

/home/jesse
└── .config/
    └── nixpkgs/
        └── config.nix             # User-level package options
