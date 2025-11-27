jesse@echo-ops /srv 
❯ treestub -I "archives"                                                                         17:33:15
.
├── agents
│   ├── chat_agents
│   │   ├── jester_chat
│   │   │   ├── chat
│   │   │   │   ├── conversations
│   │   │   │   │   └── analyze_conversations.ipynb
│   │   │   │   ├── history
│   │   │   │   ├── sessions
│   │   │   │   └── topics
│   │   │   │       ├── agents.yaml
│   │   │   │       ├── apps.yaml
│   │   │   │       ├── designs.yaml
│   │   │   │       ├── index.yaml
│   │   │   │       ├── platforms.yaml
│   │   │   │       ├── systems.yaml
│   │   │   │       └── tools.yaml
│   │   │   ├── poetry.lock
│   │   │   ├── pyproject.toml
│   │   │   └── readme.md
│   │   └── twins_azhya_enoch
│   │       ├── ai-core.js
│   │       ├── GPT4o-NOTES.md
│   │       ├── package.json
│   │       ├── pyproject.toml
│   │       ├── README.md
│   │       ├── server.js
│   │       ├── stock-predictor.py
│   │       ├── voice-handler.js
│   │       └── web-builder.mjs
│   ├── dev_agents
│   │   ├── codriver
│   │   │   ├── AUTHORS
│   │   │   ├── bin
│   │   │   │   ├── codriver
│   │   │   │   └── codriverd
│   │   │   ├── Cargo.toml
│   │   │   ├── CODE_OF_CONDUCT.md
│   │   │   ├── CODEOWNERS
│   │   │   ├── CONTRIBUTING.md
│   │   │   ├── core
│   │   │   │   ├── boot.rs
│   │   │   │   ├── context.rs
│   │   │   │   ├── kernel.rs
│   │   │   │   ├── memory.rs
│   │   │   │   ├── router.rs
│   │   │   │   └── scheduler..rs
│   │   │   ├── desktop
│   │   │   │   ├── src
│   │   │   │   └── ui
│   │   │   ├── jobs
│   │   │   ├── justfile
│   │   │   ├── LICENSE
│   │   │   ├── README.md
│   │   │   ├── SECURITY.md
│   │   │   ├── src
│   │   │   │   ├── api
│   │   │   │   │   ├── handlers.rs
│   │   │   │   │   ├── mod.rs
│   │   │   │   │   ├── routes.rs
│   │   │   │   │   └── server.rs
│   │   │   │   ├── bindings
│   │   │   │   │   ├── llama_cpp.rs
│   │   │   │   │   └── mod.rs
│   │   │   │   ├── cli.rs
│   │   │   │   ├── commands
│   │   │   │   │   ├── ask.rs
│   │   │   │   │   ├── chat.rs
│   │   │   │   │   ├── clean.rs
│   │   │   │   │   ├── create.rs
│   │   │   │   │   ├── edit.rs
│   │   │   │   │   ├── explain.rs
│   │   │   │   │   ├── index.rs
│   │   │   │   │   ├── run.rs
│   │   │   │   │   ├── scan.rs
│   │   │   │   │   ├── setup.rs
│   │   │   │   │   ├── step.rs
│   │   │   │   │   └── test.rs
│   │   │   │   ├── handlers
│   │   │   │   │   ├── exec.rs
│   │   │   │   │   ├── memory.rs
│   │   │   │   │   ├── network.rs
│   │   │   │   │   ├── register.rs
│   │   │   │   │   └── tls.rs
│   │   │   │   ├── kernel
│   │   │   │   │   ├── clock.rs
│   │   │   │   │   ├── dispatcher.rs
│   │   │   │   │   ├── sync.rs
│   │   │   │   │   └── tempo.rs
│   │   │   │   ├── libs.rs
│   │   │   │   ├── logic
│   │   │   │   │   ├── controller.rs
│   │   │   │   │   ├── extractor.rs
│   │   │   │   │   ├── flow.rs
│   │   │   │   │   ├── generator.rs
│   │   │   │   │   ├── hydrate.rs
│   │   │   │   │   ├── inject.rs
│   │   │   │   │   ├── map.rs
│   │   │   │   │   ├── match.rs
│   │   │   │   │   ├── mod.rs
│   │   │   │   │   ├── summarize.rs
│   │   │   │   │   ├── trigger.rs
│   │   │   │   │   └── vectorize.rs
│   │   │   │   ├── main.rs
│   │   │   │   ├── model
│   │   │   │   │   ├── call.rs
│   │   │   │   │   ├── format.rs
│   │   │   │   │   ├── mod.rs
│   │   │   │   │   ├── prompt.rs
│   │   │   │   │   ├── router.rs
│   │   │   │   │   └── schema.rs
│   │   │   │   ├── runners
│   │   │   │   │   ├── cli.rs
│   │   │   │   │   ├── daemon.rs
│   │   │   │   │   ├── mod.rs
│   │   │   │   │   └── repl.rs
│   │   │   │   ├── signal
│   │   │   │   │   ├── agent.rs
│   │   │   │   │   ├── file.rs
│   │   │   │   │   ├── model.rs
│   │   │   │   │   ├── system.rs
│   │   │   │   │   └── task.rs
│   │   │   │   ├── tests
│   │   │   │   │   ├── cli.rs
│   │   │   │   │   └── flows.rs
│   │   │   │   ├── tools
│   │   │   │   │   ├── apk.rs
│   │   │   │   │   ├── cargo.rs
│   │   │   │   │   ├── cloudflare.rs
│   │   │   │   │   ├── git.rs
│   │   │   │   │   ├── jq.rs
│   │   │   │   │   ├── lsp.rs
│   │   │   │   │   ├── sed.rs
│   │   │   │   │   ├── tailscale.rs
│   │   │   │   │   ├── terraform.rs
│   │   │   │   │   ├── yq.rs
│   │   │   │   │   └── zora.rs
│   │   │   │   └── utils
│   │   │   │       ├── args.rs
│   │   │   │       ├── colors.rs
│   │   │   │       ├── config.rs
│   │   │   │       ├── context.rs
│   │   │   │       ├── env.rs
│   │   │   │       ├── input.rs
│   │   │   │       ├── macros.rs
│   │   │   │       ├── metrics.rs
│   │   │   │       ├── mod.rs
│   │   │   │       ├── output.rs
│   │   │   │       ├── path.rs
│   │   │   │       ├── profile.rs
│   │   │   │       ├── styles.rs
│   │   │   │       ├── time.rs
│   │   │   │       └── tree.rs
│   │   │   ├── tests
│   │   │   │   ├── chaosmonkey
│   │   │   │   └── litmus
│   │   │   └── wrapper.h
│   │   └── marketeer
│   │       └── readme.md
│   ├── infra_agents
│   │   ├── echo_ops
│   │   │   ├── helpers
│   │   │   │   ├── nats
│   │   │   │   └── redis
│   │   │   ├── jobs
│   │   │   │   ├── auth
│   │   │   │   │   ├── authentik
│   │   │   │   │   ├── keycloak
│   │   │   │   │   ├── kong
│   │   │   │   │   ├── letsencrypt
│   │   │   │   │   ├── oathkeeper
│   │   │   │   │   ├── sops
│   │   │   │   │   ├── vault
│   │   │   │   │   └── zitadel
│   │   │   │   ├── ci
│   │   │   │   │   ├── dagger
│   │   │   │   │   ├── drone
│   │   │   │   │   ├── gitea
│   │   │   │   │   ├── githooks
│   │   │   │   │   ├── just
│   │   │   │   │   ├── nomad
│   │   │   │   │   ├── s6-overlay
│   │   │   │   │   └── woodpecker
│   │   │   │   ├── inference
│   │   │   │   │   ├── cucoost
│   │   │   │   │   ├── cudarc
│   │   │   │   │   ├── llama.cpp
│   │   │   │   │   ├── transformers
│   │   │   │   │   ├── triton
│   │   │   │   │   ├── vllm
│   │   │   │   │   └── wasm-bindgen
│   │   │   │   ├── infra
│   │   │   │   │   ├── k3s
│   │   │   │   │   ├── terraform
│   │   │   │   │   ├── varnish
│   │   │   │   │   └── zora
│   │   │   │   └── portals
│   │   │   │       ├── cockpit
│   │   │   │       ├── dashy
│   │   │   │       ├── homarr
│   │   │   │       └── portainer
│   │   │   └── readme.md
│   │   ├── jackknife_jailer
│   │   │   ├── helpers
│   │   │   │   ├── nats
│   │   │   │   └── redis
│   │   │   ├── jobs
│   │   │   │   ├── ddos
│   │   │   │   │   ├── crowdsec
│   │   │   │   │   ├── fail2ban
│   │   │   │   │   ├── fastnetmon
│   │   │   │   │   └── modsecurity
│   │   │   │   ├── dns
│   │   │   │   │   ├── coredns
│   │   │   │   │   ├── mkcert
│   │   │   │   │   └── unbound
│   │   │   │   ├── firewall
│   │   │   │   │   ├── firewalld
│   │   │   │   │   ├── iptables-nft
│   │   │   │   │   ├── pf
│   │   │   │   │   └── ufw
│   │   │   │   ├── monitoring
│   │   │   │   │   ├── cAdvisor
│   │   │   │   │   ├── grafana
│   │   │   │   │   ├── loki
│   │   │   │   │   ├── opentelemetry
│   │   │   │   │   ├── prometheus
│   │   │   │   │   └── vector
│   │   │   │   ├── networking
│   │   │   │   │   ├── bridge
│   │   │   │   │   ├── host-local
│   │   │   │   │   ├── netdata
│   │   │   │   │   ├── nmap
│   │   │   │   │   └── wireguard
│   │   │   │   ├── reverseproxy
│   │   │   │   │   ├── caddy
│   │   │   │   │   ├── haproxy
│   │   │   │   │   ├── nginx
│   │   │   │   │   ├── openresty
│   │   │   │   │   └── traefik
│   │   │   │   │       ├── acme.json
│   │   │   │   │       ├── Dockerfile
│   │   │   │   │       └── traefik.yml
│   │   │   │   └── tunnelling
│   │   │   │       ├── frp
│   │   │   │       ├── headscale
│   │   │   │       ├── inlets
│   │   │   │       ├── teleport
│   │   │   │       └── tunnelto
│   │   │   ├── readme.md
│   │   │   └── scripts
│   │   │       ├── cleanup-logs.sh
│   │   │       └── rotate-secrets.sh
│   │   └── trainr_asus
│   │       ├── helpers
│   │       │   ├── nats
│   │       │   └── redis
│   │       ├── jobs
│   │       │   ├── container
│   │       │   │   ├── buidah
│   │       │   │   ├── buildkit
│   │       │   │   ├── buildkitd
│   │       │   │   ├── containerd
│   │       │   │   ├── crun
│   │       │   │   ├── docker
│   │       │   │   ├── nerdctl
│   │       │   │   └── podman
│   │       │   ├── database
│   │       │   │   ├── btrfs
│   │       │   │   ├── duckdb
│   │       │   │   ├── indexdb
│   │       │   │   ├── minIO
│   │       │   │   ├── postgres
│   │       │   │   │   ├── data
│   │       │   │   │   └── init
│   │       │   │   ├── redis
│   │       │   │   ├── sqlite
│   │       │   │   ├── tantivy
│   │       │   │   └── zfs
│   │       │   ├── venv
│   │       │   │   ├── busybox
│   │       │   │   ├── justfile
│   │       │   │   ├── make
│   │       │   │   ├── musl
│   │       │   │   ├── nix
│   │       │   │   ├── tmux
│   │       │   │   └── zsh
│   │       │   └── vm
│   │       │       ├── cgroups
│   │       │       ├── firecracker
│   │       │       ├── kvm
│   │       │       ├── libvirt
│   │       │       ├── lxc
│   │       │       ├── qemu
│   │       │       └── virt-manager
│   │       ├── readme.md
│   │       └── stacks
│   │           ├── stack.app.yml
│   │           ├── stack.clients.yml
│   │           ├── stack.cli.yml
│   │           ├── stack.core.yml
│   │           ├── stack.dev.yml
│   │           ├── stack.services.yml
│   │           ├── stack.tools.yml
│   │           └── stack.yml
│   └── platform_agents
│       ├── big_bear
│       ├── cargo_connect
│       ├── eco
│       ├── packet_pilot
│       ├── trucker_tales
│       └── whisper_witness
├── apps
│   ├── api
│   │   ├── axum
│   │   ├── salvo
│   │   ├── tower
│   │   ├── tower-http
│   │   └── tracing
│   ├── cli
│   │   ├── bookmark
│   │   │   └── readme.md
│   │   └── storekeeer
│   │       └── readme.md
│   ├── desktop
│   └── store
├── builds
│   └── readme.md
├── _meta
│   ├── agents
│   │   ├── bigbear.agent.yaml
│   │   ├── cargoconnect.agent.yaml
│   │   ├── codriver.agent.yaml
│   │   ├── echo_ops.agent.yaml
│   │   ├── jackknife_jailer.agent.yaml
│   │   ├── jester_chat.agent.yaml
│   │   ├── marketeer.agent.yaml
│   │   ├── packetpilot.agent.yaml
│   │   ├── trainr_asus.agent.yaml
│   │   ├── truckerstale.agent.yaml
│   │   ├── twins_azhya_enoch.agent.yaml
│   │   └── whisperwitness.agent.yaml
│   ├── _meta.yaml
│   ├── models.yaml
│   ├── projects.yaml
│   ├── protocols
│   │   ├── codriver.protocol.yaml
│   │   ├── echo_ops.protocol.yaml
│   │   ├── jackknife_jailer.protocol.yaml
│   │   ├── jester_chat.protocol.yaml
│   │   ├── marketeer.protocols.yaml
│   │   ├── trainr-asus.protocol.yaml
│   │   └── twins_azhya_enoch.protocols.yaml
│   ├── schema_config.yaml
│   ├── scripts.yaml
│   ├── tags.yaml
│   ├── tools.yaml
│   └── tree.yaml
├── models
│   ├── codellama-7b
│   │   └── model.json
│   ├── models.json
│   ├── mythomax-l2-13b
│   │   └── model.json
│   ├── nous-hermes-llama2-7b
│   │   └── model.json
│   ├── openchat-3.5-1210
│   │   └── model.json
│   ├── osmosis-apply-1.7b
│   │   └── model.json
│   ├── qwen1.5-1.8b-chat
│   │   └── model.json
│   ├── tinyllama-1.1b-chat-v1.0
│   │   └── model.json
│   ├── yi-1.5-9b-chat
│   │   └── model.json
│   └── zephyr-7b
│       └── model.json
├── platforms
│   ├── 8teenwheelers
│   │   └── README.md
│   ├── fedispatching
│   │   └── readme.md
│   ├── open-hwy
│   │   ├── apps
│   │   │   ├── mobile
│   │   │   │   ├── app-env.d.ts
│   │   │   │   ├── app.json
│   │   │   │   ├── App.tsx
│   │   │   │   ├── babel.config.js
│   │   │   │   ├── index.js
│   │   │   │   ├── metro.config.js
│   │   │   │   ├── package.json
│   │   │   │   └── tsconfig.json
│   │   │   └── web
│   │   │       ├── app
│   │   │       │   ├── layout.tsx
│   │   │       │   ├── (marketing)
│   │   │       │   │   ├── about
│   │   │       │   │   │   └── page.tsx
│   │   │       │   │   ├── careers
│   │   │       │   │   │   └── page.tsx
│   │   │       │   │   ├── contact
│   │   │       │   │   │   └── page.tsx
│   │   │       │   │   ├── feedback
│   │   │       │   │   │   └── page.tsx
│   │   │       │   │   ├── page.tsx
│   │   │       │   │   ├── pricing
│   │   │       │   │   │   └── page.tsx
│   │   │       │   │   └── testimonial
│   │   │       │   │       └── page.tsx
│   │   │       │   ├── (pages)
│   │   │       │   │   ├── blog
│   │   │       │   │   │   ├── layout.tsx
│   │   │       │   │   │   ├── page.tsx
│   │   │       │   │   │   └── [slug]
│   │   │       │   │   │       └── page.tsx
│   │   │       │   │   ├── docs
│   │   │       │   │   │   ├── layout.tsx
│   │   │       │   │   │   └── page.tsx
│   │   │       │   │   ├── help
│   │   │       │   │   │   ├── layout.tsx
│   │   │       │   │   │   └── page.tsx
│   │   │       │   │   ├── legal
│   │   │       │   │   │   ├── layout.tsx
│   │   │       │   │   │   └── page.tsx
│   │   │       │   │   └── showcase
│   │   │       │   │       ├── layout.tsx
│   │   │       │   │       └── page.tsx
│   │   │       │   └── (platform)
│   │   │       │       ├── admin
│   │   │       │       │   ├── dashboard
│   │   │       │       │   │   ├── changes
│   │   │       │       │   │   │   ├── course
│   │   │       │       │   │   │   │   └── page.tsx
│   │   │       │       │   │   │   ├── dashboard
│   │   │       │       │   │   │   │   └── page.tsx
│   │   │       │       │   │   │   ├── layout
│   │   │       │       │   │   │   │   └── page.tsx
│   │   │       │       │   │   │   ├── page
│   │   │       │       │   │   │   │   └── page.tsx
│   │   │       │       │   │   │   └── portal
│   │   │       │       │   │   │       └── page.tsx
│   │   │       │       │   │   ├── layout.tsx
│   │   │       │       │   │   ├── reviews
│   │   │       │       │   │   │   ├── agent
│   │   │       │       │   │   │   │   └── [id]
│   │   │       │       │   │   │   │       ├── audits
│   │   │       │       │   │   │   │       ├── badges
│   │   │       │       │   │   │   │       ├── billing
│   │   │       │       │   │   │   │       ├── connections
│   │   │       │       │   │   │   │       ├── dashboard
│   │   │       │       │   │   │   │       ├── feedback
│   │   │       │       │   │   │   │       ├── licenses
│   │   │       │       │   │   │   │       ├── profile
│   │   │       │       │   │   │   │       ├── progress
│   │   │       │       │   │   │   │       ├── roles
│   │   │       │       │   │   │   │       ├── settings
│   │   │       │       │   │   │   │       ├── status
│   │   │       │       │   │   │   │       ├── tools
│   │   │       │       │   │   │   │       └── views
│   │   │       │       │   │   │   ├── load
│   │   │       │       │   │   │   │   └── [id]
│   │   │       │       │   │   │   │       ├── audits
│   │   │       │       │   │   │   │       ├── connections
│   │   │       │       │   │   │   │       ├── feedback
│   │   │       │       │   │   │   │       ├── licenses
│   │   │       │       │   │   │   │       ├── progress
│   │   │       │       │   │   │   │       └── status
│   │   │       │       │   │   │   ├── model
│   │   │       │       │   │   │   │   └── [id]
│   │   │       │       │   │   │   │       ├── audits
│   │   │       │       │   │   │   │       ├── badges
│   │   │       │       │   │   │   │       ├── billing
│   │   │       │       │   │   │   │       ├── connections
│   │   │       │       │   │   │   │       ├── dashboard
│   │   │       │       │   │   │   │       ├── feedback
│   │   │       │       │   │   │   │       ├── licenses
│   │   │       │       │   │   │   │       ├── profile
│   │   │       │       │   │   │   │       ├── progress
│   │   │       │       │   │   │   │       ├── roles
│   │   │       │       │   │   │   │       ├── settings
│   │   │       │       │   │   │   │       ├── status
│   │   │       │       │   │   │   │       ├── tools
│   │   │       │       │   │   │   │       └── views
│   │   │       │       │   │   │   ├── page
│   │   │       │       │   │   │   │   └── [id]
│   │   │       │       │   │   │   │       ├── analytics
│   │   │       │       │   │   │   │       ├── audits
│   │   │       │       │   │   │   │       ├── changes
│   │   │       │       │   │   │   │       ├── metrics
│   │   │       │       │   │   │   │       └── views
│   │   │       │       │   │   │   └── user
│   │   │       │       │   │   │       └── [id]
│   │   │       │       │   │   │           ├── audits
│   │   │       │       │   │   │           ├── badges
│   │   │       │       │   │   │           ├── billing
│   │   │       │       │   │   │           ├── connections
│   │   │       │       │   │   │           ├── dashboard
│   │   │       │       │   │   │           ├── feedback
│   │   │       │       │   │   │           ├── licenses
│   │   │       │       │   │   │           ├── profile
│   │   │       │       │   │   │           ├── progress
│   │   │       │       │   │   │           ├── roles
│   │   │       │       │   │   │           ├── settings
│   │   │       │       │   │   │           ├── status
│   │   │       │       │   │   │           ├── tools
│   │   │       │       │   │   │           └── views
│   │   │       │       │   │   └── testing
│   │   │       │       │   │       ├── api
│   │   │       │       │   │       │   └── page.tsx
│   │   │       │       │   │       ├── dashboard
│   │   │       │       │   │       │   └── page.tsx
│   │   │       │       │   │       ├── pages
│   │   │       │       │   │       │   └── page.tsx
│   │   │       │       │   │       └── sandbox
│   │   │       │       │   │           └── page.tsx
│   │   │       │       │   └── settings
│   │   │       │       │       ├── account
│   │   │       │       │       │   └── page.tsx
│   │   │       │       │       ├── badges
│   │   │       │       │       │   └── page.tsx
│   │   │       │       │       ├── connectors
│   │   │       │       │       │   └── page.tsx
│   │   │       │       │       ├── datacontrol
│   │   │       │       │       │   └── page.tsx
│   │   │       │       │       ├── general
│   │   │       │       │       │   └── page.tsx
│   │   │       │       │       ├── layout.tsx
│   │   │       │       │       ├── licenses
│   │   │       │       │       │   └── page.tsx
│   │   │       │       │       ├── notifications
│   │   │       │       │       │   └── page.tsx
│   │   │       │       │       ├── payments
│   │   │       │       │       │   ├── history
│   │   │       │       │       │   │   └── page.tsx
│   │   │       │       │       │   └── page.tsx
│   │   │       │       │       ├── personalization
│   │   │       │       │       │   └── page.tsx
│   │   │       │       │       └── security
│   │   │       │       │           └── page.tsx
│   │   │       │       ├── (auth)
│   │   │       │       │   ├── layout.tsx
│   │   │       │       │   ├── login
│   │   │       │       │   │   └── page.tsx
│   │   │       │       │   ├── logout
│   │   │       │       │   ├── oauth
│   │   │       │       │   │   ├── callback
│   │   │       │       │   │   │   └── page.tsx
│   │   │       │       │   │   └── page.tsx
│   │   │       │       │   ├── reset
│   │   │       │       │   ├── signup
│   │   │       │       │   │   └── page.tsx
│   │   │       │       │   └── verify
│   │   │       │       └── (user)
│   │   │       │           ├── course
│   │   │       │           │   ├── layout.tsx
│   │   │       │           │   ├── leaderboard
│   │   │       │           │   │   └── page.tsx
│   │   │       │           │   ├── learning
│   │   │       │           │   │   └── page.tsx
│   │   │       │           │   └── profile
│   │   │       │           │       └── page.tsx
│   │   │       │           ├── dashboard
│   │   │       │           │   ├── billing
│   │   │       │           │   │   └── page.tsx
│   │   │       │           │   ├── clients
│   │   │       │           │   │   ├── [clientId]
│   │   │       │           │   │   │   └── page.tsx
│   │   │       │           │   │   └── page.tsx
│   │   │       │           │   ├── connections
│   │   │       │           │   │   ├── community
│   │   │       │           │   │   │   └── page.tsx
│   │   │       │           │   │   ├── create
│   │   │       │           │   │   │   └── page.tsx
│   │   │       │           │   │   ├── loadboard
│   │   │       │           │   │   │   └── page.tsx
│   │   │       │           │   │   ├── page.tsx
│   │   │       │           │   │   └── status
│   │   │       │           │   │       └── page.tsx
│   │   │       │           │   ├── documents
│   │   │       │           │   │   └── page.tsx
│   │   │       │           │   ├── layout.tsx
│   │   │       │           │   ├── loads
│   │   │       │           │   │   ├── [loadId]
│   │   │       │           │   │   │   └── page.tsx
│   │   │       │           │   │   └── page.tsx
│   │   │       │           │   ├── profile
│   │   │       │           │   │   └── page.tsx
│   │   │       │           │   ├── reports
│   │   │       │           │   │   └── page.tsx
│   │   │       │           │   └── tools
│   │   │       │           │       └── page.tsx
│   │   │       │           └── settings
│   │   │       │               ├── account
│   │   │       │               │   └── page.tsx
│   │   │       │               ├── badges
│   │   │       │               │   └── page.tsx
│   │   │       │               ├── connectors
│   │   │       │               │   └── page.tsx
│   │   │       │               ├── datacontrol
│   │   │       │               │   └── page.tsx
│   │   │       │               ├── general
│   │   │       │               │   └── page.tsx
│   │   │       │               ├── layout.tsx
│   │   │       │               ├── licenses
│   │   │       │               │   └── page.tsx
│   │   │       │               ├── notifications
│   │   │       │               │   └── page.tsx
│   │   │       │               ├── payments
│   │   │       │               │   ├── history
│   │   │       │               │   │   └── page.tsx
│   │   │       │               │   └── page.tsx
│   │   │       │               ├── personalization
│   │   │       │               │   └── page.tsx
│   │   │       │               └── security
│   │   │       │                   └── page.tsx
│   │   │       ├── app-env.d.ts
│   │   │       ├── next.config.js
│   │   │       ├── next-env.d.ts
│   │   │       ├── package.json
│   │   │       ├── postcss.config.mjs
│   │   │       ├── public
│   │   │       │   └── vercel.svg
│   │   │       ├── src
│   │   │       │   └── index.ts
│   │   │       └── tsconfig.json
│   │   ├── docs
│   │   │   ├── api
│   │   │   │   ├── agents.md
│   │   │   │   ├── auth.md
│   │   │   │   ├── examples
│   │   │   │   │   ├── fetch-agent.md
│   │   │   │   │   └── run-prompt.md
│   │   │   │   ├── index.md
│   │   │   │   └── models.md
│   │   │   ├── badges
│   │   │   │   ├── assigning-badges.md
│   │   │   │   ├── certified-badges.md
│   │   │   │   └── ledger-badges.md
│   │   │   ├── build.md
│   │   │   ├── design
│   │   │   │   ├── components.md
│   │   │   │   ├── openhwy-design.md
│   │   │   │   ├── openhwy-overview.md
│   │   │   │   ├── openhwy-protocols.md
│   │   │   │   ├── openhwy-stack.md
│   │   │   │   ├── system.md
│   │   │   │   ├── tokens.md
│   │   │   │   └── visuals.md
│   │   │   ├── docker.md
│   │   │   ├── ethics
│   │   │   │   ├── ai.md
│   │   │   │   ├── automation.md
│   │   │   │   ├── data.md
│   │   │   │   ├── human.md
│   │   │   │   └── transparency.md
│   │   │   ├── features
│   │   │   │   ├── chat.md
│   │   │   │   ├── dashboard.md
│   │   │   │   ├── inference.md
│   │   │   │   ├── licensing.md
│   │   │   │   ├── local-database.md
│   │   │   │   └── portal.md
│   │   │   ├── guides
│   │   │   │   ├── cli.md
│   │   │   │   ├── customizing.md
│   │   │   │   ├── deploy.md
│   │   │   │   ├── setup.md
│   │   │   │   └── training.md
│   │   │   ├── index.md
│   │   │   ├── install.md
│   │   │   ├── onboarding
│   │   │   │   ├── agents.md
│   │   │   │   ├── developers.md
│   │   │   │   ├── faq.md
│   │   │   │   └── users.md
│   │   │   ├── overview
│   │   │   │   ├── architecture.md
│   │   │   │   ├── diagram.md
│   │   │   │   ├── intro.md
│   │   │   │   ├── license.md
│   │   │   │   ├── mission.md
│   │   │   │   ├── roadmap.md
│   │   │   │   └── terminology.md
│   │   │   ├── platforms
│   │   │   │   ├── eco.md
│   │   │   │   ├── elda.md
│   │   │   │   ├── fed.md
│   │   │   │   ├── hwy.md
│   │   │   │   └── openhwy.md
│   │   │   ├── protocols
│   │   │   │   ├── access
│   │   │   │   │   ├── kcbb-marker.md
│   │   │   │   │   ├── license-permissions.md
│   │   │   │   │   ├── multi-key-structure.md
│   │   │   │   │   ├── rcbb-recovery.md
│   │   │   │   │   └── trust-grant-flow.md
│   │   │   │   ├── agents
│   │   │   │   │   ├── agent-role-lock.md
│   │   │   │   │   ├── elda-boundary.md
│   │   │   │   │   ├── impersonation-rules.md
│   │   │   │   │   └── markdown-audit.md
│   │   │   │   ├── badges
│   │   │   │   │   ├── assignment-flow.md
│   │   │   │   │   ├── badge-clocking.md
│   │   │   │   │   ├── behavior-mapping.md
│   │   │   │   │   └── redemption-paths.md
│   │   │   │   ├── defense
│   │   │   │   │   ├── forceful-key-trace.md
│   │   │   │   │   ├── gov-override.md
│   │   │   │   │   └── tattle-tale.md
│   │   │   │   ├── dispatch
│   │   │   │   │   ├── dispatcher-verification.md
│   │   │   │   │   ├── tool-unlocking.md
│   │   │   │   │   └── training-gate.md
│   │   │   │   ├── ethics
│   │   │   │   │   ├── agent-logging.md
│   │   │   │   │   ├── ai-boundaries.md
│   │   │   │   │   ├── behavior-ledgering.md
│   │   │   │   │   └── driver-protection.md
│   │   │   │   ├── identity
│   │   │   │   │   ├── identity-keys.md
│   │   │   │   │   ├── license-creation.md
│   │   │   │   │   ├── model-isolation.md
│   │   │   │   │   └── peer-identity.md
│   │   │   │   ├── ledger
│   │   │   │   │   ├── access-conditions.md
│   │   │   │   │   ├── badge-linking.md
│   │   │   │   │   ├── report-ingestion.md
│   │   │   │   │   └── write-only-default.md
│   │   │   │   ├── models
│   │   │   │   │   ├── agent-whitelisting.md
│   │   │   │   │   ├── eco-driver-support.md
│   │   │   │   │   ├── elda-protocol.md
│   │   │   │   │   └── fed-dispatch-flow.md
│   │   │   │   └── README.md
│   │   │   ├── quickstart.md
│   │   │   └── system-overview.md
│   │   ├── LICENSE
│   │   ├── package.json
│   │   ├── platforms
│   │   ├── pnpm-workspace.yaml
│   │   ├── README.md
│   │   ├── tools
│   │   │   ├── direct_dispatch
│   │   │   ├── error_echo
│   │   │   ├── fuel_factor
│   │   │   ├── iron_insight
│   │   │   ├── key_keeper
│   │   │   ├── legal_logger
│   │   │   ├── quick_qoute
│   │   │   ├── secret_safe
│   │   │   ├── unit_usage
│   │   │   └── voice_validator
│   │   ├── tsconfig.base.json
│   │   ├── tsconfig.json
│   │   └── turbo.json
│   └── owlusive-treasures
│       └── README.md
└── services
    ├── badge-ledger
    ├── llama_runner
    │   ├── build.rs
    │   ├── Cargo.toml
    │   ├── justfile
    │   ├── README.md
    │   ├── scripts
    │   │   ├── check-ffi-headers.sh
    │   │   └── regen-llama-engine.sh
    │   ├── src
    │   │   ├── bindings
    │   │   │   ├── llama_cpp.rs
    │   │   │   └── mod.rs
    │   │   ├── lib.rs
    │   │   ├── loaders
    │   │   │   ├── model.rs
    │   │   │   └── mod.rs
    │   │   ├── main.rs
    │   │   ├── prompts
    │   │   │   ├── format.rs
    │   │   │   ├── mod.rs
    │   │   │   ├── system.rs
    │   │   │   └── tokenize.rs
    │   │   ├── runners
    │   │   │   ├── check.rs
    │   │   │   ├── interactive.rs
    │   │   │   └── mod.rs
    │   │   └── tokens
    │   │       ├── batch.rs
    │   │       ├── check.rs
    │   │       └── mod.rs
    │   └── wrapper.h
    ├── openhwy-licensing
    └── trakapay................jesse@echo-ops /srv 
❯ cd archives                                                                                    17:33:28
jesse@echo-ops /srv/archives 
❯ treestub                                                                                       17:34:01
.
├── docs
│   └── overview.ecosystem.md
├── lessons
│   ├── notes
│   │   ├── ast.md
│   │   ├── battle-hardened-list.md
│   │   ├── build-ideas.md
│   │   ├── cc.md
│   │   ├── cli-command-structure.md
│   │   ├── codriver_note_001.md
│   │   ├── cranelift.md
│   │   ├── deps-measuring.md
│   │   ├── downstream-breaks.md
│   │   ├── HIR&MIR.md
│   │   ├── hotspot.md
│   │   ├── IDE-notes.md
│   │   ├── install-full-power-setup.md
│   │   ├── install-power-setup.md
│   │   ├── JIT&AOT.md
│   │   ├── lisp-clojure.md
│   │   ├── LXC-vs-Docker.md
│   │   ├── macros&codegen2.md
│   │   ├── macros&codegen.md
│   │   ├── public-wifi-bypass-tunneling-designs.md
│   │   ├── REPLs.md
│   │   ├── root-tree-explain.md
│   │   ├── run-dev.md
│   │   ├── semvar.md
│   │   ├── signatures.md
│   │   └── usage-dev.md
│   ├── studies
│   │   ├── lang
│   │   │   ├── c++.md
│   │   │   ├── c.md
│   │   │   ├── css.md
│   │   │   ├── eslang.md
│   │   │   ├── html.md
│   │   │   ├── java.md
│   │   │   ├── javascript.md
│   │   │   ├── json.md
│   │   │   ├── kotin.md
│   │   │   ├── markdown.md
│   │   │   ├── python.md
│   │   │   ├── rust.md
│   │   │   ├── typescript.md
│   │   │   └── yaml.md
│   │   ├── languages
│   │   │   ├── arabic.md
│   │   │   ├── chinese.md
│   │   │   ├── english.md
│   │   │   ├── franch.md
│   │   │   ├── german.md
│   │   │   ├── japanese.md
│   │   │   ├── portuguese.md
│   │   │   └── spanish.md
│   │   ├── references
│   │   │   ├── bookos
│   │   │   │   ├── markdb-setup-v1.md
│   │   │   │   └── README.md
│   │   │   ├── scratch-pad.md
│   │   │   └── token-buffers.md
│   │   ├── rust
│   │   │   ├── bindings
│   │   │   │   └── bindings-check.md
│   │   │   ├── cli
│   │   │   │   ├── decision-making.md
│   │   │   │   ├── example-layout.md
│   │   │   │   ├── glue-vs-engine.md
│   │   │   │   └── orthogonality.md
│   │   │   └── crates
│   │   │       ├── avaliable-crates.md
│   │   │       ├── cargo-rules.md
│   │   │       ├── crates-vs-packages2.md
│   │   │       ├── crates-vs-packages3.md
│   │   │       └── crates-vs-packages.md
│   │   └── system
│   │       ├── alpine-linux-overview.md
│   │       ├── asus-system-diagnostic.md
│   │       ├── asus-system-overview.md
│   │       ├── docker-secure-setup.md
│   │       ├── full-wipe-and-setup.md
│   │       ├── how-hosting-works.md
│   │       ├── POSIX&system-level-commands.md
│   │       ├── setup-asus-decisions.md
│   │       ├── what-does-'.d'-mean-in-linux.md
│   │       ├── what-is-tailscale-really.md
│   │       ├── what-tailscale-actually-is.md
│   │       └── where-things-live.md
│   └── tools
│       ├── mistral.md
│       ├── ollama.md
│       └── whisper.md
├── mark_system
│   ├── AUTHORS
│   ├── beats
│   │   ├── connect.beat
│   │   ├── fallback.beat
│   │   ├── linking.beat
│   │   ├── mark.beat
│   │   ├── marker.beat
│   │   ├── passing.beat
│   │   ├── routing.beat
│   │   ├── signing.beat
│   │   ├── summary.beat
│   │   ├── system.beat
│   │   ├── tempo.beat
│   │   ├── trail.beat
│   │   └── writing.baet
│   ├── bets
│   │   ├── agent.bet
│   │   ├── README.md
│   │   ├── system.bet
│   │   └── user.bet
│   ├── books
│   │   ├── agent
│   │   │   ├── book.md
│   │   │   ├── markers
│   │   │   │   └── fallback.mrkr
│   │   │   ├── pages
│   │   │   │   ├── logging.md
│   │   │   │   └── scratch-pad.md
│   │   │   ├── ribbons
│   │   │   │   └── summary.rib
│   │   │   └── trails
│   │   │       ├── agent-session.trl
│   │   │       └── marker-ink.trl
│   │   ├── mark
│   │   │   ├── book.md
│   │   │   ├── markers
│   │   │   │   └── signing.mrk
│   │   │   ├── pages
│   │   │   │   └── system-logs.md
│   │   │   ├── ribbons
│   │   │   │   └── init.rib
│   │   │   └── trails
│   │   │       └── boot.trl
│   │   └── user
│   │       ├── book.md
│   │       ├── markers
│   │       │   └── system.mrkr
│   │       ├── pages
│   │       │   ├── profile.md
│   │       │   └── settings.md
│   │       ├── ribbons
│   │       │   ├── intro.rib
│   │       │   └── welcome.rib
│   │       └── trails
│   │           └── user-session.trl
│   ├── CODE_OF_CONDUCT.md
│   ├── CODEOWNERS
│   ├── CONTRIBUTING.md
│   ├── docs
│   │   ├── api
│   │   │   └── integration.md
│   │   ├── beats
│   │   │   └── intro.md
│   │   ├── bets
│   │   │   └── intro.md
│   │   ├── books
│   │   │   └── intro.md
│   │   ├── commands
│   │   │   ├── init
│   │   │   │   ├── mark-init--agent.md
│   │   │   │   ├── mark-init--db.md
│   │   │   │   └── mark-init.md
│   │   │   ├── mark-beat.md
│   │   │   ├── mark-exec.md
│   │   │   └── mark-tempo.md
│   │   ├── economy
│   │   │   └── cost-structure.md
│   │   ├── faqs
│   │   │   ├── index.md
│   │   │   ├── what-is-a-beat.md
│   │   │   ├── what-is-a-bet.md
│   │   │   ├── what-is-a-clock.md
│   │   │   ├── what-is-a-delay.md
│   │   │   ├── what-is-a-marker.md
│   │   │   ├── what-is-a-mark.md
│   │   │   ├── what-is-an-actor.md
│   │   │   ├── what-is-an-agent.md
│   │   │   ├── what-is-an-inkstroke.md
│   │   │   ├── what-is-an-inkwell.md
│   │   │   ├── what-is-a-ppur.md
│   │   │   ├── what-is-a-pulse.md
│   │   │   ├── what-is-a-ribbon.md
│   │   │   ├── what-is-a-stroke.md
│   │   │   ├── what-is-a-sync.md
│   │   │   ├── what-is-a-tempo.md
│   │   │   ├── what-is-a-trail.md
│   │   │   └── what-is-ink.md
│   │   ├── markers
│   │   │   └── intro.md
│   │   ├── marks
│   │   │   └── intro.md
│   │   ├── memory
│   │   │   └── intro.md
│   │   ├── ribbons
│   │   │   └── intro.md
│   │   └── trails
│   │       └── intro.md
│   ├── LICENSE
│   ├── markers
│   │   ├── fallback.mrkr
│   │   ├── linking.mrkr
│   │   ├── mark.mrkr
│   │   ├── passing.mrkr
│   │   ├── routing.mrkr
│   │   ├── signing.mrkr
│   │   ├── summary.mrkr
│   │   ├── system.mrkr
│   │   ├── tempo.mrkr
│   │   ├── trail.mrkr
│   │   └── writing.mrkr
│   ├── marks
│   │   ├── bet.mrk
│   │   ├── boot.mrk
│   │   ├── ink.mrk
│   │   └── marker.mrk
│   ├── memory
│   │   ├── archive
│   │   │   └── backup_20240717.mem
│   │   ├── index.json
│   │   └── store
│   │       ├── agent.mem
│   │       ├── mark.mem
│   │       └── user.mem
│   ├── README.md
│   ├── ribbons
│   │   ├── cache
│   │   │   └── summary_gpt4o.rib
│   │   ├── index.json
│   │   └── store
│   │       ├── boot.rib
│   │       ├── intro.rib
│   │       ├── summary.rib
│   │       └── welcome.rib
│   ├── schema
│   │   ├── beat.schema.json
│   │   ├── bet.schema.json
│   │   ├── marker.schema.json
│   │   ├── mark.schema.json
│   │   ├── memory.schema.json
│   │   ├── ribbon.schema.json
│   │   └── trail.schema.json
│   ├── schemas
│   │   ├── beat.yaml
│   │   ├── bet.yaml
│   │   ├── book.yaml
│   │   ├── chapter.yaml
│   │   ├── cover.yaml
│   │   ├── ink.yaml
│   │   ├── keeper.yaml
│   │   ├── license.yaml
│   │   ├── marker.yaml
│   │   ├── mark.yaml
│   │   ├── page.yaml
│   │   ├── ribbon.yaml
│   │   ├── stroke.yaml
│   │   └── trail.yaml
│   ├── SECURITY.md
│   ├── stroke.md
│   └── trails
│       ├── index.json
│       ├── store
│       │   ├── agent.trl
│       │   ├── bet.trl
│       │   ├── ink.trl
│       │   ├── marker.trl
│       │   └── user.trl
│       └── tmp
│           └── abc123.trl
├── memories
│   ├── constants
│   │   ├── env
│   │   │   ├── base.env
│   │   │   ├── dev.env
│   │   │   └── prod.env
│   │   ├── goals
│   │   └── intents
│   ├── context
│   │   ├── active
│   │   │   ├── chat
│   │   │   │   ├── 2025-07-01T-session.001.yaml
│   │   │   │   ├── 2025-07-02T-session-002.yaml
│   │   │   │   └── logs
│   │   │   │       ├── 001.log
│   │   │   │       └── 002.log
│   │   │   ├── prompts
│   │   │   ├── tasks
│   │   │   └── topics
│   │   └── clock
│   ├── domains
│   │   ├── 8teenwheelers.com.md
│   │   ├── fedispatching.com.md
│   │   └── open-hwy.com.md
│   ├── queue
│   │   ├── inbox.yaml
│   │   └── stack.yaml
│   ├── runtime
│   │   ├── input.yaml
│   │   ├── loop.yaml
│   │   ├── output.yaml
│   │   └── ticks.yaml
│   ├── _saves
│   │   ├── delta
│   │   │   ├── 2025-07-01.changes.yaml
│   │   │   └── 2050-07-02.changes.yaml
│   │   ├── errors
│   │   │   ├── failed-routes
│   │   │   ├── halucinations
│   │   │   └── runtime
│   │   ├── history
│   │   │   ├── chatgpt
│   │   │   │   ├── chatgpt_saved_memories.txt
│   │   │   │   └── old_chatgpt_saved_memories.txt
│   │   │   └── events
│   │   │       ├── agent
│   │   │       │   └── 2025-07-01.agent.yaml
│   │   │       └── system
│   │   │           └── 2025-07-01.events.yaml
│   │   └── snapshots
│   │       ├── 2025-07-01.snapshot.yaml
│   │       └── 2025-07-02.snapshot.yaml
│   ├── state
│   │   ├── emotion
│   │   │   ├── current.yaml
│   │   │   └── reasons.yaml
│   │   ├── flags
│   │   │   ├── debug.yaml
│   │   │   ├── fail_safe.yaml
│   │   │   └── verbose.yaml
│   │   ├── focus
│   │   │   ├── agent.yaml
│   │   │   └── goal.yaml
│   │   ├── locks
│   │   │   ├── api.yaml
│   │   │   ├── system.yaml
│   │   │   └── task.yaml
│   │   ├── mode
│   │   │   ├── current.yaml
│   │   │   └── history.yaml
│   │   ├── position
│   │   │   ├── file.yaml
│   │   │   └── topic.yaml
│   │   └── signals
│   │       ├── event.yaml
│   │       ├── interrupt.yaml
│   │       └── status.yaml
│   ├── tasks
│   │   ├── active
│   │   ├── planed
│   │   └── queue
│   └── usage
│       ├── limits.yaml
│       ├── tmestamps.yaml
│       └── tokens.yaml
├── pricing
│   ├── levels
│   │   └── support.levels.yaml
│   ├── packages
│   │   ├── add-on.packages.yaml
│   │   ├── agent.packages.yaml
│   │   ├── ai.packages.yaml
│   │   ├── analytics.packages.yaml
│   │   ├── auth.packages.yaml
│   │   ├── bundle.packages.yaml
│   │   ├── cms.packages.yaml
│   │   ├── dashboard.packages.yaml
│   │   ├── database.packages.yaml
│   │   ├── delivery.packages.yaml
│   │   ├── devops.packages.yaml
│   │   ├── dev.packages.yaml
│   │   ├── infra.packages.yaml
│   │   ├── mobile.packages.yaml
│   │   ├── monorepo.packages.yaml
│   │   ├── payments.packages.yaml
│   │   ├── platform.packages.yaml
│   │   ├── seo.packages.yaml
│   │   ├── starter.packages.yaml
│   │   ├── storefront.packages.yaml
│   │   └── training.packages.yaml
│   ├── pages
│   │   └── legal.pages.yaml
│   └── stages
│       └── revision.stage.yaml
├── prompts
│   ├── chat
│   │   ├── casual-convo.prompt.json
│   │   ├── emotional-support.prompt.json
│   │   ├── humorist.prompt.json
│   │   ├── roleplay-character.prompt.json
│   │   └── socratic-guide.prompt.json
│   ├── code
│   │   ├── code-debugger.prompt.json
│   │   ├── code-explainer.prompt.json
│   │   ├── code-optimizer.prompt.json
│   │   ├── code-reviewer.prompt.json
│   │   └── code-rewriter.prompt.json
│   ├── content
│   │   ├── blog-writer.prompt.json
│   │   ├── copywriter.prompt.json
│   │   ├── newsletter-drafter.prompt.json
│   │   ├── product-description.prompt.json
│   │   └── tweet-generator.prompt.json
│   ├── creative
│   │   ├── lore-builder.prompt.json
│   │   ├── novelist.prompt.json
│   │   ├── poet.prompt.json
│   │   └── story-prompt-engine.prompt.json
│   ├── data
│   │   ├── dataframe-debugger.prompt.json
│   │   ├── json-schema-generator.prompt.json
│   │   ├── log-summarizer.prompt.json
│   │   └── table-analyzer.prompt.json
│   ├── dev
│   │   ├── api-drafter.prompt.json
│   │   ├── commit-writer.prompt.json
│   │   ├── dev-coach.prompt.json
│   │   └── docstring-generator.prompt.json
│   ├── legal
│   │   ├── legalese-translator.prompt.json
│   │   ├── nda-drafter.prompt.json
│   │   └── terms-reviewer.prompt.json
│   ├── memory
│   │   ├── memory-auditor.prompt.json
│   │   ├── memory-refresher.prompt.json
│   │   ├── memory-summary.prompt.json
│   │   └── started_memory.yaml
│   ├── moderation
│   │   ├── content-flagger.prompt.json
│   │   ├── nsfw-filter.prompt.json
│   │   └── safety-checker.prompt.json
│   ├── prompts.json
│   ├── reasoning
│   │   ├── chain-of-thought.prompt.json
│   │   ├── fact-checker.prompt.json
│   │   ├── planner.prompt.json
│   │   └── verifier.prompt.json
│   ├── _saves
│   │   ├── blocked
│   │   ├── failed
│   │   ├── generated
│   │   ├── scored
│   │   └── trusted
│   ├── schema
│   │   └── agent_schema.yaml
│   ├── search
│   │   ├── document-finder.prompt.json
│   │   ├── retrieval-agent.prompt.json
│   │   ├── site-scanner.prompt.json
│   │   └── web-searcher.prompt.json
│   ├── summarization
│   │   ├── call-summary.prompt.json
│   │   ├── document-summary.prompt.json
│   │   ├── news-digester.prompt.json
│   │   └── realtime-transcript-summary.prompt.json
│   ├── system
│   │   ├── default-assistant.prompt.json
│   │   ├── guard-rails.prompt.json
│   │   ├── minimalist-system.prompt.json
│   │   └── verbose-instructor.prompt.json
│   ├── task
│   │   ├── task-decomposer.prompt.json
│   │   ├── task-router.prompt.json
│   │   ├── task-solver.prompt.json
│   │   └── task-verifier.prompt.json
│   ├── trees
│   │   ├── domain-tree.md
│   │   ├── fs-tree.md
│   │   ├── src-tree.md
│   │   └── stack-tree.md
│   └── voice
│       ├── radio-announcer.prompt.json
│       ├── tone-analyzer.prompt.json
│       ├── voice-coach.prompt.json
│       └── voice-style-selector.prompt.json
├── protocols
│   ├── access
│   │   ├── access_conditions.protocol.yaml
│   │   ├── audit_access.protocol.yaml
│   │   └── override_access.protocol.yaml
│   ├── agent
│   │   ├── aa-zz
│   │   │   ├── auto_assist.protocol.yaml
│   │   │   ├── big_bear.protocol.yaml
│   │   │   ├── cargo_connect.protocol.yaml
│   │   │   ├── direct_dispatcher.protocol.yaml
│   │   │   ├── error_echo.protocol.yaml
│   │   │   ├── fuel_factor.protocol.yaml
│   │   │   ├── ghost_guard.protcol.yaml
│   │   │   ├── hazard_hauler.protocol.yaml
│   │   │   ├── iron_insight.protocol.yaml
│   │   │   ├── jackknife_jailer.protocol.yaml
│   │   │   ├── key_keeper.protocol.yaml
│   │   │   ├── legal_logger.protocol.yaml
│   │   │   ├── memory_mark.protocol.yaml
│   │   │   ├── night_nexus.protocol.yaml
│   │   │   ├── oversize_overseer.protocol.yaml
│   │   │   ├── packet_pilot.protocol.yaml
│   │   │   ├── quick_quote.protocol.yaml
│   │   │   ├── radar_reach.protocol.yaml
│   │   │   ├── secret_safe.protocol.yaml
│   │   │   ├── trucker_tales.protcol.yaml
│   │   │   ├── unit_usage.protocol.yaml
│   │   │   ├── voice_validator.protocol.yaml
│   │   │   ├── whisper_witness.protocol.yaml
│   │   │   ├── xeno_xeno.protocol.yaml
│   │   │   ├── yes_yes.protocol.yaml
│   │   │   └── zone_zipper.protocol.yaml
│   │   ├── co-driver.protocol.yaml
│   │   ├── gpt.protcol.yaml
│   │   └── marketeer.protocol.yaml
│   ├── badges
│   │   ├── assigning_badge.protocol.yaml
│   │   ├── badge_clock.protocol.yaml
│   │   └── badge_linking.protocol.yaml
│   ├── blocking
│   │   ├── redemption_path.protocol.yaml
│   │   └── training_gateway.protocol.yaml
│   ├── core
│   │   ├── acces.protocol.yaml
│   │   ├── agent.protocol.yaml
│   │   ├── badge.protocol.yaml
│   │   ├── blocking.protocol.yaml
│   │   ├── core.protocol.yaml
│   │   ├── defense.protocol.yaml
│   │   ├── ethics.protocol.yaml
│   │   ├── identity.protocol.yaml
│   │   ├── key_mark.protocol.yaml
│   │   ├── ledger.protocol.yaml
│   │   ├── license.protocol.yaml
│   │   ├── model.protocol.yaml
│   │   ├── platform.protocol.yaml
│   │   ├── security.protocol.yaml
│   │   ├── system.protocol.yaml
│   │   └── tool.protocol.yaml
│   ├── defense
│   │   ├── federated_agent_routing.protocol.yaml
│   │   ├── forceful_key_trace.protocol.yaml
│   │   └── model_logic_trace.protocol.yaml
│   ├── ethics
│   │   ├── agent_ethics.protocol.yaml
│   │   ├── behavior_mapping.protocol.yaml
│   │   ├── in-the-loop_dispatch.protocol.yaml
│   │   ├── license_ethics.protocol.yaml
│   │   ├── model_ethics.protocol.yaml
│   │   ├── platform_ethics.protocol.yaml
│   │   ├── platform_isolation.protocol.yaml
│   │   ├── report_chain.protocol.yaml
│   │   └── tattle_tale.protocol.yaml
│   ├── identity
│   │   ├── key_identity.protocol.yaml
│   │   └── peer_identity.protocol.yaml
│   ├── ledger
│   │   ├── permissioned_read.protocol.yaml
│   │   ├── report_ingestion.protocol.yaml
│   │   └── write_only.protocol.yaml
│   ├── license
│   │   ├── create_license.protocol.yaml
│   │   ├── license_verification.protocol.yaml
│   │   └── suspend_license.protocol.yaml
│   ├── model
│   │   ├── agent_blacklisting.protocol.yaml
│   │   ├── agent_whitelisting.protocol.yaml
│   │   ├── eco.protocol.yaml
│   │   ├── elda.protocol.yaml
│   │   ├── fed.protocol.yaml
│   │   ├── hwy.protocol.yaml
│   │   └── twins.protocol.yaml
│   ├── platform
│   │   ├── 8teenwheelers.protocol.yaml
│   │   ├── bookstore.protocol.yaml
│   │   ├── client_tales.protocol.yaml
│   │   ├── fedispatching.protocol.yaml
│   │   ├── open-hwy.protocol.yaml
│   │   ├── owlusive_treasures.protocol.yaml
│   │   └── traka_pay.protocol.yaml
│   ├── security
│   │   ├── kcbb_rcbb.protocol.yaml
│   │   └── key_rotation.protocol.yaml
│   ├── system
│   │   ├── beat_sync.protocol.yaml
│   │   ├── bet_engine.protocol.yaml
│   │   ├── book_os.protocol.yaml
│   │   ├── ink_burn.protocol.yaml
│   │   ├── keeper_db.protocol.yaml
│   │   ├── marker_router.protocol.yaml
│   │   ├── mark_kernel.protocol.yaml
│   │   ├── memory_scroll.protocol.yaml
│   │   ├── ribbon_trail.protocol.yaml
│   │   ├── token_stroke.protocol.yaml
│   │   └── trail_ledger.protocol.yaml
│   └── tool
│       ├── lock_tool.protocol.yaml
│       ├── unlock_tool.protocol.yaml
│       └── using_tool.protocol.yaml
└── stories
    ├── a-builders-tale
    │   ├── tale-1-i'll-do-it-anyway
    │   │   ├── Chapter-01.md
    │   │   ├── Chapter-02.md
    │   │   ├── Chapter-03.md
    │   │   ├── Chapter-04.md
    │   │   ├── Chapter-05.md
    │   │   ├── Chapter-06.md
    │   │   ├── Chapter-07.md
    │   │   ├── Chapter-08.md
    │   │   ├── Chapter-09.md
    │   │   ├── Chapter-10.md
    │   │   ├── Chapter-11.md
    │   │   ├── Chapter-12.md
    │   │   ├── Chapter-13.md
    │   │   ├── Chapter-14.md
    │   │   ├── Chapter-15.md
    │   │   ├── *Chapter-16.md
    │   │   ├── Chapter-17.md
    │   │   ├── Chapter-18.md
    │   │   ├── Chapter-19.md
    │   │   ├── *Chapter-20.md
    │   │   ├── Chapter-21.md
    │   │   ├── Chapter-22.md
    │   │   ├── Chapter-23.md
    │   │   ├── Chapter-24.md
    │   │   ├── *Chapter-25.md
    │   │   ├── Chapter-26.md
    │   │   ├── Chapter-27.md
    │   │   ├── Chapter-28.md
    │   │   ├── Chapter-29.md
    │   │   ├── Chapter-30.md
    │   │   ├── Chapter-31.md
    │   │   └── Chapter-32.md
    │   ├── tale-2-but-you-said
    │   │   ├── Chapter-01.md
    │   │   ├── Chapter-02.md
    │   │   ├── Chapter-03.md
    │   │   ├── Chapter-04.md
    │   │   ├── *Chapter-05.md
    │   │   ├── Chapter-06.md
    │   │   ├── Chapter-07.md
    │   │   ├── Chapter-08.md
    │   │   ├── Chapter-09.md
    │   │   ├── Chapter-10.md
    │   │   ├── *Chapter-11.md
    │   │   ├── Chapter-12.md
    │   │   ├── Chapter-13.md
    │   │   ├── *Chapter-14.md
    │   │   ├── Chapter-15.md
    │   │   ├── Chapter-16.md
    │   │   ├── *Chapter-17.md
    │   │   ├── Chapter-18.md
    │   │   ├── *Chapter-19.md
    │   │   ├── *Chapter-20.md
    │   │   ├── Chapter-21.md
    │   │   ├── Chapter-22.md
    │   │   ├── Chapter-23.md
    │   │   ├── Chapter-24.md
    │   │   ├── Chapter-25.md
    │   │   ├── Chapter-26.md
    │   │   ├── Chapter-27.md
    │   │   ├── Chapter-28.md
    │   │   ├── Chapter-29.md
    │   │   ├── *Chapter-30.md
    │   │   ├── Chapter-31.md
    │   │   └── Chapter-32.md
    │   └── tale-3-i-wrote-it-anway
    │       ├── Chapter-01.md
    │       ├── Chapter-02.md
    │       ├── Chapter-03.md
    │       ├── Chapter-04.md
    │       ├── Chapter-05.md
    │       ├── Chapter-06.md
    │       ├── Chapter-07.md
    │       ├── Chapter-08.md
    │       ├── Chapter-09.md
    │       ├── Chapter-10.md
    │       ├── Chapter-11.md
    │       ├── Chapter-12.md
    │       ├── Chapter-13.md
    │       ├── Chapter-14.md
    │       ├── Chapter-15.md
    │       ├── Chapter-16.md
    │       ├── Chapter-17.md
    │       ├── Chapter-18.md
    │       ├── Chapter-19.md
    │       ├── Chapter-20.md
    │       ├── Chapter-21.md
    │       ├── Chapter-22.md
    │       ├── Chapter-23.md
    │       ├── Chapter-24.md
    │       ├── Chapter-25.md
    │       ├── Chapter-26.md
    │       ├── Chapter-27.md
    │       ├── Chapter-28.md
    │       ├── Chapter-29.md
    │       ├── Chapter-30.md
    │       ├── Chapter-31.md
    │       └── Chapter-32.md
    └── a-truckers-tale
        └── tale-1-a-long-way-home
            ├── Chapter-01.md
            ├── Chapter-02.md
            ├── Chapter-03.md
            ├── Chapter-04.md
            ├── Chapter-05.md
            ├── Chapter-06.md
            ├── Chapter-07.md
            ├── Chapter-08.md
            ├── Chapter-09.md
            ├── Chapter-10.md
            ├── Chapter-11.md
            ├── Chapter-12.md
            ├── Chapter-13.md
            ├── Chapter-14.md
            ├── Chapter-15.md
            ├── Chapter-16.md
            ├── Chapter-17.md
            ├── Chapter-18.md
            ├── Chapter-19.md
            ├── Chapter-20.md
            ├── Chapter-21.md
            ├── Chapter-22.md
            ├── Chapter-23.md
            ├── Chapter-24.md
            ├── Chapter-25.md
            ├── Chapter-26.md
            ├── Chapter-27.md
            ├── Chapter-28.md
            ├── Chapter-29.md
            ├── Chapter-30.md
            ├── Chapter-31.md
            └── Chapter-32.md
