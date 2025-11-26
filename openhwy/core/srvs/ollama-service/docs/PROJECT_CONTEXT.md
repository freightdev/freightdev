=== PROJECT CONTEXT ===
Path: /home/jesse/main/projects/ollama-control-service
Created: Thu Sep  4 06:11:49 PM EDT 2025

=== FILE STATS ===
Total Files: 45
Go Files: 24
JS Files: 0
TS Files: 0
Python Files: 0
Java Files: 0
Markdown Files: 4

=== DIRECTORY STRUCTURE ===
.
├── api
│   ├── grpc-api.go
│   ├── handler
│   │   ├── authentication-handler.go
│   │   └── websocket-handler.go
│   ├── rest-api.go
│   └── routing
│       └── model-routing.go
├── build-errors-20250904-170759.log
├── cmd
│   ├── bin
│   └── main.go
├── configs
│   ├── constants.yaml
│   ├── features.yaml
│   ├── limits.yaml
│   ├── model
│   │   ├── personas.yaml
│   │   └── prompt-templates.yaml
│   ├── models.yaml
│   └── server.yaml
├── databases
│   └── storage-database.go
├── docker
│   ├── docker-compose.yaml
│   ├── Dockerfile
│   └── gpu.dockerfile
├── docs
│   ├── API.md
│   ├── ARCHITECTURE.md
│   └── SETUP.md
├── go.mod
├── go.sum
├── managers
│   ├── config-manager.go
│   ├── conversation-manager.go
│   ├── disk-manager.go
│   ├── inference-manager.go
│   ├── memory-manager.go
│   ├── model-manager.go
│   ├── session-manager.go
│   ├── token-manager.go
│   └── websocket-manager.go
├── models
│   ├── chat-model.go
│   ├── code-model.go
│   └── reasoning-model.go
├── project-analyze.zsh
├── PROJECT_CONTEXT.md
├── scripts
│   ├── analyze-ocs-structure.sh
│   ├── ocs-debug.sh
│   └── quick-setup-ocs.sh
└── src
    ├── tools
    │   ├── code-tools.go
    │   ├── file-tools.go
    │   └── search-tools.go
    └── utils
        ├── generate.go
        └── mapping.go

17 directories, 45 files

=== TOP LEVEL FILES ===
api
build-errors-20250904-170759.log
cmd
configs
databases
docker
docs
go.mod
go.sum
managers
models
project-analyze.zsh
PROJECT_CONTEXT.md
scripts
src

=== RECENT CHANGES ===
No git history available

=== FILE SIZES (TOP 10) ===
./managers/conversation-manager.go (27746 bytes)
./managers/inference-manager.go (24316 bytes)
./managers/memory-manager.go (24045 bytes)
./managers/websocket-manager.go (20521 bytes)
./go.sum (18904 bytes)
./managers/token-manager.go (18241 bytes)
./managers/session-manager.go (16667 bytes)
./databases/storage-database.go (15546 bytes)
./managers/disk-manager.go (15070 bytes)
./managers/model-manager.go (13592 bytes)
