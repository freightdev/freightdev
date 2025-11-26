jesse@archbox /srv 
❯ treestub -I "docs"                                                                                               23:43:09
.
├── agent
│   ├── eco
│   ├── elda
│   ├── fed
│   ├── hwy
│   └── README.md
├── apps
│   ├── api
│   │   ├── endpoints
│   │   │   ├── graphQL
│   │   │   └── rest
│   │   ├── middleware
│   │   │   ├── auth
│   │   │   └── grpc
│   │   │       ├── client
│   │   │       ├── docker-compose.yml
│   │   │       ├── Dockerfile
│   │   │       ├── proto
│   │   │       └── server
│   │   ├── rate-limits
│   │   └── README.md
│   ├── mobile
│   │   └── README.md
│   ├── pkg
│   │   ├── chatbot
│   │   ├── payment
│   │   │   ├── paypal
│   │   │   └── stripe
│   │   └── README.md
│   ├── pwa
│   │   ├── README.md
│   │   └── wasm
│   │       ├── README.md
│   │       ├── spin
│   │       ├── wasmedge
│   │       └── wasmtime
│   ├── README.md
│   └── web
│       ├── 8teenwheelers
│       │   ├── app
│       │   │   └── index.html
│       │   ├── data
│       │   └── docker-compose.yml
│       ├── fedispatching
│       │   ├── app
│       │   │   └── index.html
│       │   ├── data
│       │   └── docker-compose.yml
│       ├── open-hwy
│       │   ├── app
│       │   │   └── index.html
│       │   ├── data
│       │   └── docker-compose.yml
│       └── README.md
├── infra
│   ├── ai
│   │   ├── llama_cpp
│   │   │   ├── conf.d
│   │   │   ├── docker-compose.yml
│   │   │   ├── Dockerfile
│   │   │   └── models
│   │   ├── openvino
│   │   │   ├── conf.d
│   │   │   ├── docker-compose.yml
│   │   │   ├── Dockerfile
│   │   │   └── models
│   │   ├── ray
│   │   │   ├── conf.d
│   │   │   └── docker-compose.yml
│   │   ├── README.md
│   │   └── triton
│   │       ├── conf.d
│   │       ├── docker-compose.yml
│   │       ├── Dockerfile
│   │       └── model-repository
│   ├── env
│   │   ├── containerd
│   │   ├── devenv
│   │   ├── docker
│   │   ├── nix
│   │   ├── README.md
│   │   └── turbo
│   ├── manager
│   │   ├── pm2
│   │   ├── README.md
│   │   ├── supervisord
│   │   └── systemd
│   ├── observability
│   │   ├── alertmanager
│   │   ├── btop
│   │   ├── cAdvisor
│   │   ├── ELK
│   │   ├── fail2ban
│   │   ├── fluentbit
│   │   ├── grafana
│   │   │   ├── data
│   │   │   ├── docker-compose.yml
│   │   │   └── provisioning
│   │   ├── jaeger
│   │   │   ├── conf.d
│   │   │   └── docker-compose.yml
│   │   ├── journald
│   │   ├── loki
│   │   │   ├── config.yml
│   │   │   ├── data
│   │   │   └── docker-compose.yml
│   │   ├── ncdu
│   │   ├── nodeexporter
│   │   ├── prometheus
│   │   │   ├── data
│   │   │   ├── docker-compose.yml
│   │   │   └── prometheus.yml
│   │   ├── README.md
│   │   ├── uptimekuma
│   │   └── vector
│   │       ├── data
│   │       ├── docker-compose.yml
│   │       └── vector.toml
│   ├── orchestration
│   │   ├── ansible
│   │   │   ├── inventory
│   │   │   └── playbook
│   │   ├── argocd
│   │   ├── README.md
│   │   ├── terraform
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   └── variables.tf
│   │   └── zora
│   ├── README.md
│   ├── security
│   │   ├── gpg
│   │   ├── README.md
│   │   ├── sops
│   │   │   ├── conf.d
│   │   │   ├── keys
│   │   │   └── README.md
│   │   └── vault
│   │       ├── conf.d
│   │       ├── data
│   │       └── docker-compose.yml
│   └── worker
│       ├── borg
│       ├── celery
│       ├── dask
│       ├── pagerduty
│       ├── README.md
│       ├── restic
│       └── temoral
├── _meta
│   ├── _meta.yaml
│   ├── models.yaml
│   ├── projects.yaml
│   ├── schemas
│   │   ├── meta.schema.yaml
│   │   ├── prompt.schema.yaml
│   │   ├── raw.schema.yaml
│   │   └── schema_config.yaml
│   ├── scripts.yaml
│   ├── tags.yaml
│   ├── tools.yaml
│   └── tree.yaml
├── network
│   ├── api
│   │   ├── evony
│   │   ├── gateway
│   │   ├── kong
│   │   │   ├── data
│   │   │   ├── docker-compose.yml
│   │   │   └── kong.conf
│   │   ├── krakend
│   │   └── README.md
│   ├── cdn
│   │   ├── openresty
│   │   ├── README.md
│   │   └── varnish
│   ├── connection
│   │   ├── centrifugo
│   │   ├── nats
│   │   │   ├── Dockerfile
│   │   │   └── README.md
│   │   ├── README.md
│   │   └── socket.io
│   ├── dns
│   │   ├── bind9
│   │   ├── blocky
│   │   ├── coredns
│   │   ├── powerdns
│   │   ├── README.md
│   │   └── unbound
│   ├── firewall
│   │   ├── crowdsec
│   │   ├── firewalld
│   │   ├── iptables
│   │   ├── nftables
│   │   ├── pf
│   │   ├── README.md
│   │   └── ufw
│   ├── identity
│   │   ├── dex
│   │   │   ├── config.yaml
│   │   │   └── Dockerfile
│   │   ├── keycloak
│   │   │   ├── data
│   │   │   ├── docker-compose.yml
│   │   │   ├── realm-export.json
│   │   │   └── themes
│   │   ├── README.md
│   │   ├── step-ca
│   │   ├── teleport
│   │   │   ├── Dockerfile
│   │   │   ├── rules.yaml
│   │   │   ├── teleport.yaml
│   │   │   └── trusted-cluster.yaml
│   │   └── zitabel
│   │       ├── Dockerfile
│   │       └── zitadel.yaml
│   ├── mesh
│   │   ├── istio
│   │   ├── linkerd
│   │   └── README.md
│   ├── proxy
│   │   ├── caddy
│   │   │   ├── Caddyfile
│   │   │   ├── data
│   │   │   └── docker-compose.yml
│   │   ├── haproxy
│   │   ├── nginx
│   │   │   ├── conf.d
│   │   │   │   ├── 8teenwheelers.conf
│   │   │   │   ├── fedispatching.conf
│   │   │   │   ├── global.conf
│   │   │   │   └── open-hwy.conf
│   │   │   ├── data
│   │   │   │   └── public
│   │   │   ├── docker-compose.yml
│   │   │   └── ssl
│   │   │       ├── 8teenwheelers.fullchain.pem
│   │   │       ├── cloudflare-origin-ca.pem
│   │   │       ├── fedispatching.fullchain.pem
│   │   │       ├── open-hwy.fullchain.pem
│   │   │       └── rootCA.pem
│   │   ├── README.md
│   │   └── traefik
│   ├── README.md
│   └── tunnel
│       ├── asterisk
│       ├── cloudflared
│       │   ├── config.yml
│       │   ├── creds.json
│       │   ├── docker-compose.yml
│       │   └── logs
│       ├── frp
│       ├── inlents
│       ├── openrc
│       ├── README.md
│       ├── ssh
│       ├── tailscale
│       └── wiregaurd
├── platform
│   ├── assets
│   │   ├── memories
│   │   │   ├── constants
│   │   │   │   ├── env
│   │   │   │   │   ├── base.env
│   │   │   │   │   ├── dev.env
│   │   │   │   │   └── prod.env
│   │   │   │   ├── goals
│   │   │   │   └── intents
│   │   │   ├── context
│   │   │   │   ├── active
│   │   │   │   │   ├── chat
│   │   │   │   │   │   ├── 2025-07-01T-session.001.yaml
│   │   │   │   │   │   ├── 2025-07-02T-session-002.yaml
│   │   │   │   │   │   └── logs
│   │   │   │   │   │       ├── 001.log
│   │   │   │   │   │       └── 002.log
│   │   │   │   │   ├── prompts
│   │   │   │   │   ├── tasks
│   │   │   │   │   └── topics
│   │   │   │   └── clock
│   │   │   ├── domains
│   │   │   │   ├── 8teenwheelers.com.md
│   │   │   │   ├── fedispatching.com.md
│   │   │   │   └── open-hwy.com.md
│   │   │   ├── queue
│   │   │   │   ├── inbox.yaml
│   │   │   │   └── stack.yaml
│   │   │   ├── runtime
│   │   │   │   ├── input.yaml
│   │   │   │   ├── loop.yaml
│   │   │   │   ├── output.yaml
│   │   │   │   └── ticks.yaml
│   │   │   ├── _saves
│   │   │   │   ├── delta
│   │   │   │   │   ├── 2025-07-01.changes.yaml
│   │   │   │   │   └── 2050-07-02.changes.yaml
│   │   │   │   ├── errors
│   │   │   │   │   ├── failed-routes
│   │   │   │   │   ├── halucinations
│   │   │   │   │   └── runtime
│   │   │   │   ├── history
│   │   │   │   │   ├── chatgpt
│   │   │   │   │   │   ├── chatgpt_saved_memories.txt
│   │   │   │   │   │   └── old_chatgpt_saved_memories.txt
│   │   │   │   │   └── events
│   │   │   │   │       ├── agent
│   │   │   │   │       │   └── 2025-07-01.agent.yaml
│   │   │   │   │       └── system
│   │   │   │   │           └── 2025-07-01.events.yaml
│   │   │   │   └── snapshots
│   │   │   │       ├── 2025-07-01.snapshot.yaml
│   │   │   │       └── 2025-07-02.snapshot.yaml
│   │   │   ├── state
│   │   │   │   ├── emotion
│   │   │   │   │   ├── current.yaml
│   │   │   │   │   └── reasons.yaml
│   │   │   │   ├── flags
│   │   │   │   │   ├── debug.yaml
│   │   │   │   │   ├── fail_safe.yaml
│   │   │   │   │   └── verbose.yaml
│   │   │   │   ├── focus
│   │   │   │   │   ├── agent.yaml
│   │   │   │   │   └── goal.yaml
│   │   │   │   ├── locks
│   │   │   │   │   ├── api.yaml
│   │   │   │   │   ├── system.yaml
│   │   │   │   │   └── task.yaml
│   │   │   │   ├── mode
│   │   │   │   │   ├── current.yaml
│   │   │   │   │   └── history.yaml
│   │   │   │   ├── position
│   │   │   │   │   ├── file.yaml
│   │   │   │   │   └── topic.yaml
│   │   │   │   └── signals
│   │   │   │       ├── event.yaml
│   │   │   │       ├── interrupt.yaml
│   │   │   │       └── status.yaml
│   │   │   ├── tasks
│   │   │   │   ├── active
│   │   │   │   ├── planed
│   │   │   │   └── queue
│   │   │   └── usage
│   │   │       ├── limits.yaml
│   │   │       ├── tmestamps.yaml
│   │   │       └── tokens.yaml
│   │   ├── models
│   │   │   ├── codellama-7b
│   │   │   │   └── model.json
│   │   │   ├── models.json
│   │   │   ├── mythomax-l2-13b
│   │   │   │   └── model.json
│   │   │   ├── nous-hermes-llama2-7b
│   │   │   │   └── model.json
│   │   │   ├── openchat-3.5-1210
│   │   │   │   └── model.json
│   │   │   ├── osmosis-apply-1.7b
│   │   │   │   └── model.json
│   │   │   ├── qwen1.5-1.8b-chat
│   │   │   │   └── model.json
│   │   │   ├── tinyllama-1.1b-chat-v1.0
│   │   │   │   └── model.json
│   │   │   ├── yi-1.5-9b-chat
│   │   │   │   ├── model.json
│   │   │   │   └── tinyllama-1.1b-chat-v1.0
│   │   │   │       └── model.json
│   │   │   └── zephyr-7b
│   │   │       └── model.json
│   │   └── prompts
│   │       ├── chat
│   │       │   ├── casual-convo.prompt.json
│   │       │   ├── emotional-support.prompt.json
│   │       │   ├── humorist.prompt.json
│   │       │   ├── roleplay-character.prompt.json
│   │       │   └── socratic-guide.prompt.json
│   │       ├── code
│   │       │   ├── code-debugger.prompt.json
│   │       │   ├── code-explainer.prompt.json
│   │       │   ├── code-optimizer.prompt.json
│   │       │   ├── code-reviewer.prompt.json
│   │       │   └── code-rewriter.prompt.json
│   │       ├── content
│   │       │   ├── blog-writer.prompt.json
│   │       │   ├── copywriter.prompt.json
│   │       │   ├── newsletter-drafter.prompt.json
│   │       │   ├── product-description.prompt.json
│   │       │   └── tweet-generator.prompt.json
│   │       ├── creative
│   │       │   ├── lore-builder.prompt.json
│   │       │   ├── novelist.prompt.json
│   │       │   ├── poet.prompt.json
│   │       │   └── story-prompt-engine.prompt.json
│   │       ├── data
│   │       │   ├── dataframe-debugger.prompt.json
│   │       │   ├── json-schema-generator.prompt.json
│   │       │   ├── log-summarizer.prompt.json
│   │       │   └── table-analyzer.prompt.json
│   │       ├── dev
│   │       │   ├── api-drafter.prompt.json
│   │       │   ├── commit-writer.prompt.json
│   │       │   ├── dev-coach.prompt.json
│   │       │   └── docstring-generator.prompt.json
│   │       ├── legal
│   │       │   ├── legalese-translator.prompt.json
│   │       │   ├── nda-drafter.prompt.json
│   │       │   └── terms-reviewer.prompt.json
│   │       ├── memory
│   │       │   ├── memory-auditor.prompt.json
│   │       │   ├── memory-refresher.prompt.json
│   │       │   ├── memory-summary.prompt.json
│   │       │   └── started_memory.yaml
│   │       ├── moderation
│   │       │   ├── content-flagger.prompt.json
│   │       │   ├── nsfw-filter.prompt.json
│   │       │   └── safety-checker.prompt.json
│   │       ├── prompts.json
│   │       ├── reasoning
│   │       │   ├── chain-of-thought.prompt.json
│   │       │   ├── fact-checker.prompt.json
│   │       │   ├── planner.prompt.json
│   │       │   └── verifier.prompt.json
│   │       ├── _saves
│   │       │   ├── blocked
│   │       │   ├── failed
│   │       │   ├── generated
│   │       │   ├── scored
│   │       │   └── trusted
│   │       ├── schema
│   │       │   └── agent_schema.yaml
│   │       ├── search
│   │       │   ├── document-finder.prompt.json
│   │       │   ├── retrieval-agent.prompt.json
│   │       │   ├── site-scanner.prompt.json
│   │       │   └── web-searcher.prompt.json
│   │       ├── summarization
│   │       │   ├── call-summary.prompt.json
│   │       │   ├── document-summary.prompt.json
│   │       │   ├── news-digester.prompt.json
│   │       │   └── realtime-transcript-summary.prompt.json
│   │       ├── system
│   │       │   ├── default-assistant.prompt.json
│   │       │   ├── guard-rails.prompt.json
│   │       │   ├── minimalist-system.prompt.json
│   │       │   └── verbose-instructor.prompt.json
│   │       ├── task
│   │       │   ├── task-decomposer.prompt.json
│   │       │   ├── task-router.prompt.json
│   │       │   ├── task-solver.prompt.json
│   │       │   └── task-verifier.prompt.json
│   │       ├── trees
│   │       │   ├── domain-tree.md
│   │       │   ├── fs-tree.md
│   │       │   ├── src-tree.md
│   │       │   └── stack-tree.md
│   │       └── voice
│   │           ├── radio-announcer.prompt.json
│   │           ├── tone-analyzer.prompt.json
│   │           ├── voice-coach.prompt.json
│   │           └── voice-style-selector.prompt.json
│   ├── ci_cd
│   │   ├── buildkit
│   │   │   ├── build-config.toml
│   │   │   └── Dockerfile
│   │   ├── dagger
│   │   ├── drone
│   │   ├── gitea
│   │   ├── jenkins
│   │   ├── justfile
│   │   ├── nerdctl
│   │   ├── nomad
│   │   └── README.md
│   ├── database
│   │   ├── duckdb
│   │   │   ├── data
│   │   │   └── docker-compose.yml
│   │   ├── mariadb
│   │   ├── mongodb
│   │   ├── mysql
│   │   ├── postgres
│   │   │   ├── data
│   │   │   ├── docker-compose.yml
│   │   │   └── initdb
│   │   ├── README.md
│   │   └── sqlite
│   │       ├── data
│   │       ├── db.sqlite
│   │       └── docker-compose.yml
│   ├── job
│   │   ├── indexdb
│   │   ├── kafka
│   │   ├── rabbitMQ
│   │   ├── README.md
│   │   ├── redis
│   │   │   ├── data
│   │   │   ├── docker-compose.yml
│   │   │   └── redis.conf
│   │   └── tantivy
│   ├── mail
│   │   ├── mailu
│   │   │   └── data
│   │   └── README.md
│   ├── README.md
│   ├── scripts
│   │   ├── build.zsh
│   │   ├── ci
│   │   │   ├── entrypoint.zsh
│   │   │   └── setup-env.zsh
│   │   ├── controller
│   │   │   ├── delete-controllers.zsh
│   │   │   └── install-controllers.zsh
│   │   ├── coverage.zsh
│   │   ├── docker
│   │   │   ├── backup-db.sh
│   │   │   ├── ci-build.sh
│   │   │   ├── prune.sh
│   │   │   ├── restore-db.sh
│   │   │   ├── stack-down.sh
│   │   │   ├── stack-new.sh
│   │   │   └── stack-up.sh
│   │   ├── format.zsh
│   │   ├── gen
│   │   │   └── regen-llama-engine.sh
│   │   ├── git
│   │   │   ├── clean-repo.zsh
│   │   │   └── keeper.sh
│   │   ├── helper
│   │   │   ├── capitalize.sh
│   │   │   ├── json-to-yaml.sh
│   │   │   ├── log.sh
│   │   │   ├── recent-output.sh
│   │   │   ├── syscheck.zsh
│   │   │   ├── testsys.zsh
│   │   │   └── yaml-to-json.sh
│   │   ├── lint.zsh
│   │   ├── md
│   │   │   ├── tree-copy.sh
│   │   │   ├── tree-delete.sh
│   │   │   └── tree-make.sh
│   │   ├── meta
│   │   │   └── barrel-to-yaml.sh
│   │   ├── misc
│   │   │   └── install
│   │   │       └── install-intel-npu.zsh
│   │   ├── model
│   │   │   ├── check-integrity.sh
│   │   │   ├── download-models.sh
│   │   │   ├── index-models.sh
│   │   │   ├── index-prompts.sh
│   │   │   ├── list-models.sh
│   │   │   ├── list-prompts.sh
│   │   │   ├── pull-all.sh
│   │   │   └── validate-models.sh
│   │   ├── README.md
│   │   ├── test.zsh
│   │   ├── ui
│   │   │   ├── barrel-ui.sh
│   │   │   ├── create-ui.sh
│   │   │   ├── rewrite-imports.sh
│   │   │   ├── unbarrel-ui.sh
│   │   │   └── validate-ui.sh
│   │   └── watch
│   │       ├── tailscale-exit-node-fix.zsh
│   │       └── tailscale-exit-node-watch.zsh
│   ├── storage
│   │   ├── block
│   │   │   ├── iSCSI
│   │   │   └── LVM
│   │   ├── btrfs
│   │   ├── object
│   │   │   ├── ceph
│   │   │   ├── minio
│   │   │   │   ├── conf.d
│   │   │   │   ├── data
│   │   │   │   └── docker-compose.yml
│   │   │   └── s3
│   │   ├── README.md
│   │   └── zfs
│   └── tools
│       ├── curl
│       ├── htop
│       ├── jq
│       ├── mc
│       ├── nano
│       ├── podman
│       ├── rclone
│       ├── README.md
│       ├── vim
│       ├── wget
│       ├── yq
│       └── zsync
└── stack
    ├── agent
    │   ├── stack.eco.yml
    │   ├── stack.elda.yml
    │   ├── stack.fed.yml
    │   ├── stack.hwy.yml
    │   └── stack.yml
    ├── apps
    │   ├── stack.api.yml
    │   ├── stack.mobile.yml
    │   ├── stack.pkg.yml
    │   ├── stack.pwa.yml
    │   ├── stack.web.yml
    │   └── stack.yml
    ├── infra
    │   ├── stack.ai.yml
    │   ├── stack.env.yml
    │   ├── stack.maganer.yml
    │   ├── stack.observability.yml
    │   ├── stack.orchestration.yml
    │   ├── stack.security.yml
    │   ├── stack.worker.yml
    │   └── stack.yml
    ├── network
    │   ├── stack.api.yml
    │   ├── stack.cdn.yml
    │   ├── stack.connection.yml
    │   ├── stack.dns.yml
    │   ├── stack.firewall.yml
    │   ├── stack.identity.yml
    │   ├── stack.mesh.yml
    │   ├── stack.proxy.yml
    │   ├── stack.tunnel.yml
    │   └── stack.yml
    ├── platform
    │   ├── stack.api.yml
    │   ├── stack.assets.yml
    │   ├── stack.ci_cd.yml
    │   ├── stack.database.yml
    │   ├── stack.docs.yml
    │   ├── stack.job.yml
    │   ├── stack.mail.yml
    │   ├── stack.scripts.yml
    │   └── stack.tools.yml
    └── README.md
