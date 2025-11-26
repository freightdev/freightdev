21:15 jesse@echo-ops in ~/Workspace 
# tree -L 4
.
├── ai
│   ├── ai.json
│   ├── chats
│   │   ├── analyze_conversations.ipynb
│   │   ├── chats.json
│   │   └── history
│   │       ├── chat
│   │       ├── errors
│   │       ├── events
│   │       ├── memory
│   │       └── prompts
│   ├── context
│   │   ├── active
│   │   │   ├── tasks
│   │   │   └── topics
│   │   ├── cache
│   │   ├── context.json
│   │   └── notebook
│   ├── core
│   │   ├── bootstrape
│   │   │   ├── healthcheck.yaml
│   │   │   └── startup.yaml
│   │   ├── bridge
│   │   │   ├── agent-link.json
│   │   │   ├── data-handlers
│   │   │   └── relay
│   │   ├── core.json
│   │   ├── dsl
│   │   │   ├── agent.marco
│   │   │   ├── hydration.syntax
│   │   │   ├── rules
│   │   │   ├── schemas
│   │   │   └── signal.logic
│   │   ├── goals
│   │   ├── intents
│   │   ├── journal
│   │   │   ├── events
│   │   │   ├── journal.json
│   │   │   ├── notes
│   │   │   ├── reflections
│   │   │   ├── reminders
│   │   │   ├── vocabs
│   │   │   └── voids
│   │   ├── memory
│   │   │   ├── clock
│   │   │   ├── constants
│   │   │   ├── knowledge
│   │   │   ├── memory.json
│   │   │   ├── memory_starter.yaml
│   │   │   ├── personal
│   │   │   ├── sessions
│   │   │   ├── states
│   │   │   └── topics
│   │   ├── permissions
│   │   │   ├── levels
│   │   │   ├── limits
│   │   │   ├── roles
│   │   │   └── zones
│   │   ├── prompts
│   │   │   ├── chat
│   │   │   ├── code
│   │   │   ├── content
│   │   │   ├── creative
│   │   │   ├── data
│   │   │   ├── dev
│   │   │   ├── legal
│   │   │   ├── memory
│   │   │   ├── meta.json
│   │   │   ├── moderation
│   │   │   ├── reasoning
│   │   │   ├── saved
│   │   │   ├── search
│   │   │   ├── summarization
│   │   │   ├── system
│   │   │   ├── task
│   │   │   └── voice
│   │   └── training
│   │       ├── studies
│   │       └── training.json
│   ├── logic
│   │   ├── extractor
│   │   │   └── context
│   │   ├── generate
│   │   │   ├── logic
│   │   │   ├── prompt
│   │   │   ├── script
│   │   │   └── test
│   │   ├── hydrator
│   │   ├── loader
│   │   ├── parser
│   │   ├── router
│   │   ├── signal
│   │   │   ├── agent
│   │   │   ├── system
│   │   │   └── task
│   │   ├── summarize
│   │   └── vectorize
│   ├── logs
│   │   └── logs.json
│   ├── models
│   │   ├── codellama-7b
│   │   │   ├── model.json
│   │   │   └── Q4_K_M
│   │   ├── models.json
│   │   ├── mythomax-l2-13b
│   │   │   ├── model.json
│   │   │   └── Q4_K_M
│   │   ├── nous-hermes-llama2-7b
│   │   │   ├── model.json
│   │   │   └── Q4_K_M
│   │   ├── openchat-3.5-1210
│   │   │   ├── model.json
│   │   │   └── Q4_K_M
│   │   ├── osmosis-apply-1.7b
│   │   │   ├── model.json
│   │   │   └── Q4_K_M
│   │   ├── qwen1.5-1.8b-chat
│   │   │   ├── model.json
│   │   │   └── Q4_K_M
│   │   ├── tinyllama-1.1b-chat-v1.0
│   │   │   ├── model.json
│   │   │   └── Q4_K_M
│   │   ├── yi-1.5-9b-chat
│   │   │   ├── model.json
│   │   │   └── Q4_K_M
│   │   └── zephyr-7b
│   │       ├── model.json
│   │       └── Q4_K_M
│   └── tasks
│       ├── active
│       ├── completed
│       ├── failed
│       ├── planed
│       ├── queue
│       └── tasks.json
├── designs
│   ├── agents
│   │   ├── agents.json
│   │   ├── ECO
│   │   │   └── README.md
│   │   ├── ELDA
│   │   │   └── README.md
│   │   ├── FED
│   │   │   └── README.md
│   │   └── HWY
│   │       └── README.md
│   ├── designs.json
│   ├── models
│   │   ├── Marketeer
│   │   │   └── README.md
│   │   ├── models.json
│   │   ├── OpenHWY
│   │   │   └── README.md
│   │   └── Traka
│   │       └── README.md
│   ├── systems
│   │   ├── bookmark
│   │   │   ├── AUTHORS
│   │   │   ├── CODE_OF_CONDUCT.md
│   │   │   ├── CODEOWNERS
│   │   │   ├── CONTRIBUTING.md
│   │   │   ├── covers
│   │   │   ├── display
│   │   │   ├── LICENSE
│   │   │   ├── pages
│   │   │   ├── README.md
│   │   │   ├── scrolls
│   │   │   ├── SECURITY.md
│   │   │   └── store
│   │   ├── book-os
│   │   │   ├── AUTHORS
│   │   │   ├── beat-sync
│   │   │   ├── bet-engine
│   │   │   ├── bookos-glossary
│   │   │   ├── CODE_OF_CONDUCT.md
│   │   │   ├── CODEOWNERS
│   │   │   ├── CONTRIBUTING.md
│   │   │   ├── ink-burn
│   │   │   ├── ink_trails
│   │   │   ├── keeper-db
│   │   │   ├── key-mark
│   │   │   ├── LICENSE
│   │   │   ├── marker-router
│   │   │   ├── mark_kernel
│   │   │   ├── memory-scroll
│   │   │   ├── README.md
│   │   │   ├── ribbon-trail
│   │   │   ├── schemas
│   │   │   ├── SECURITY.md
│   │   │   └── token_stroke
│   │   ├── mark-system
│   │   │   ├── AUTHORS
│   │   │   ├── beats
│   │   │   ├── bets
│   │   │   ├── books
│   │   │   ├── CODE_OF_CONDUCT.md
│   │   │   ├── CODEOWNERS
│   │   │   ├── CONTRIBUTING.md
│   │   │   ├── docs
│   │   │   ├── LICENSE
│   │   │   ├── markers
│   │   │   ├── marks
│   │   │   ├── memory
│   │   │   ├── README.md
│   │   │   ├── ribbons
│   │   │   ├── schema
│   │   │   ├── SECURITY.md
│   │   │   ├── stroke.md
│   │   │   └── trails
│   │   ├── systems.json
│   │   └── tale-system
│   │       ├── AUTHORS
│   │       ├── CODE_OF_CONDUCT.md
│   │       ├── CODEOWNERS
│   │       ├── CONTRIBUTING.md
│   │       ├── docs
│   │       ├── download
│   │       ├── idea
│   │       ├── LICENSE
│   │       ├── pages
│   │       ├── README.md
│   │       └── SECURITY.md
│   └── tools
│       ├── agent
│       │   ├── agent.json
│       │   ├── auto_assist
│       │   ├── big_bear
│       │   ├── cargo_connect
│       │   ├── direct_dispatcher
│       │   ├── error_echo
│       │   ├── fuel_factor
│       │   ├── ghost_guard
│       │   ├── hazard_hauler
│       │   ├── iron_insight
│       │   ├── jackknife_jailer
│       │   ├── key_keeper
│       │   ├── legal_logger
│       │   ├── memory_mark
│       │   ├── night_nexus
│       │   ├── oversize_overseer
│       │   ├── packet_pilot
│       │   ├── quick_quote
│       │   ├── radar_reach
│       │   ├── secret_safe
│       │   ├── trucker_tales
│       │   ├── twins-azhya-enoch
│       │   ├── unit_usage
│       │   ├── voice_validator
│       │   ├── whisper_witness
│       │   ├── xeno_xeno
│       │   ├── yes_yes
│       │   └── zone_zipper
│       └── controller
│           ├── bookjs
│           ├── bookmark
│           ├── cli.json
│           ├── keeper
│           ├── markdb
│           ├── ppur
│           ├── sysctr
│           └── trainr
├── docs
│   ├── api
│   │   ├── agents.md
│   │   ├── auth.md
│   │   ├── examples
│   │   │   ├── fetch-agent.md
│   │   │   └── run-prompt.md
│   │   ├── index.md
│   │   └── models.md
│   ├── badges
│   │   ├── assigning-badges.md
│   │   ├── certified-badges.md
│   │   └── ledger-badges.md
│   ├── design
│   │   ├── components.md
│   │   ├── openhwy-design.md
│   │   ├── openhwy-overview.md
│   │   ├── openhwy-protocols.md
│   │   ├── openhwy-stack.md
│   │   ├── system.md
│   │   ├── tokens.md
│   │   └── visuals.md
│   ├── docs.json
│   ├── ethics
│   │   ├── ai.md
│   │   ├── automation.md
│   │   ├── data.md
│   │   ├── human.md
│   │   └── transparency.md
│   ├── features
│   │   ├── chat.md
│   │   ├── dashboard.md
│   │   ├── inference.md
│   │   ├── licensing.md
│   │   ├── local-database.md
│   │   └── portal.md
│   ├── guides
│   │   ├── cli.md
│   │   ├── customizing.md
│   │   ├── deploy.md
│   │   ├── setup.md
│   │   └── training.md
│   ├── misc
│   │   ├── build.md
│   │   ├── docker.md
│   │   ├── index.md
│   │   ├── install.md
│   │   ├── quickstart.md
│   │   └── system-overview.md
│   ├── onboarding
│   │   ├── agents.md
│   │   ├── developers.md
│   │   ├── faq.md
│   │   └── users.md
│   ├── overview
│   │   ├── architecture.md
│   │   ├── diagram.md
│   │   ├── intro.md
│   │   ├── license.md
│   │   ├── mission.md
│   │   ├── roadmap.md
│   │   └── terminology.md
│   ├── platforms
│   │   ├── eco.md
│   │   ├── elda.md
│   │   ├── fed.md
│   │   ├── hwy.md
│   │   └── openhwy.md
│   └── trees
│       ├── core-stub.md
│       ├── domain-tree.md
│       ├── fs-tree.md
│       ├── src-tree.md
│       ├── stack-tree.md
│       └── state-stub.md
├── meta
│   └── meta.json
├── platforms
│   ├── domains
│   │   ├── 8teenwheelers
│   │   │   ├── 8teenwheelers.com.md
│   │   │   ├── apps
│   │   │   ├── AUTHORS
│   │   │   ├── CHANGELOG.md
│   │   │   ├── CODE_OF_CONDUCT.md
│   │   │   ├── CODEOWNERS
│   │   │   ├── CONTRIBUTING.md
│   │   │   ├── index.json
│   │   │   ├── LICENSE
│   │   │   ├── package.json
│   │   │   ├── pnpm-workspace.yaml
│   │   │   ├── README.md
│   │   │   ├── SECURITY.md
│   │   │   ├── tsconfig.base.json
│   │   │   ├── tsconfig.json
│   │   │   └── turbo.json
│   │   ├── domains.json
│   │   ├── fedispatching
│   │   │   ├── apps
│   │   │   ├── AUTHORS
│   │   │   ├── CHANGELOG.md
│   │   │   ├── CODE_OF_CONDUCT.md
│   │   │   ├── CODEOWNERS
│   │   │   ├── CONTRIBUTING.md
│   │   │   ├── fedispatching.com.md
│   │   │   ├── index.json
│   │   │   ├── LICENSE
│   │   │   ├── package.json
│   │   │   ├── pnpm-lock.yaml
│   │   │   ├── pnpm-workspace.yaml
│   │   │   ├── prettier.config.js
│   │   │   ├── README.md
│   │   │   ├── SECURITY.md
│   │   │   ├── tsconfig.base.json
│   │   │   ├── tsconfig.json
│   │   │   └── turbo.json
│   │   ├── open-hwy
│   │   │   ├── apps
│   │   │   ├── AUTHORS
│   │   │   ├── CHANGELOG.md
│   │   │   ├── CODE_OF_CONDUCT.md
│   │   │   ├── CODEOWNERS
│   │   │   ├── CONTRIBUTING.md
│   │   │   ├── index.json
│   │   │   ├── LICENSE
│   │   │   ├── open-hwy.com.md
│   │   │   ├── package.json
│   │   │   ├── pnpm-workspace.yaml
│   │   │   ├── README.md
│   │   │   ├── SECURITY.md
│   │   │   ├── tsconfig.base.json
│   │   │   ├── tsconfig.json
│   │   │   └── turbo.json
│   │   ├── owlusive-treasures
│   │   │   ├── apps
│   │   │   ├── AUTHORS
│   │   │   ├── CHANGELOG.md
│   │   │   ├── CODE_OF_CONDUCT.md
│   │   │   ├── CODEOWNERS
│   │   │   ├── CONTRIBUTING.md
│   │   │   ├── index.json
│   │   │   ├── LICENSE
│   │   │   ├── package.json
│   │   │   ├── pnpm-workspace.yaml
│   │   │   ├── README.md
│   │   │   ├── SECURITY.md
│   │   │   ├── tsconfig.base.json
│   │   │   ├── tsconfig.json
│   │   │   └── turbo.json
│   │   └── trakapay
│   │       ├── apps
│   │       ├── AUTHORS
│   │       ├── CHANGELOG.md
│   │       ├── CODE_OF_CONDUCT.md
│   │       ├── CODEOWNERS
│   │       ├── CONTRIBUTING.md
│   │       ├── index.json
│   │       ├── LICENSE
│   │       ├── package.json
│   │       ├── pnpm-workspace.yaml
│   │       ├── README.md
│   │       ├── SECURITY.md
│   │       ├── tsconfig.base.json
│   │       ├── tsconfig.json
│   │       └── turbo.json
│   ├── packages
│   │   ├── app
│   │   │   └── README.md
│   │   ├── auth
│   │   │   └── README.md
│   │   ├── packages.json
│   │   └── ui
│   │       ├── components
│   │       ├── index copy.ts
│   │       ├── index.ts
│   │       ├── package.json
│   │       ├── postcss.config.mjs
│   │       ├── README.md
│   │       ├── src
│   │       ├── tsconfig.json
│   │       └── tsup.config.ts
│   ├── platforms.json
│   └── protocols
│       ├── access
│       │   ├── access_conditions.protocol.yaml
│       │   ├── audit_access.protocol.yaml
│       │   └── override_access.protocol.yaml
│       ├── agent
│       │   ├── aa-zz
│       │   ├── co-driver.protocol.yaml
│       │   ├── gpt.protcol.yaml
│       │   └── marketeer.protocol.yaml
│       ├── badges
│       │   ├── assigning_badge.protocol.yaml
│       │   ├── badge_clock.protocol.yaml
│       │   └── badge_linking.protocol.yaml
│       ├── blocking
│       │   ├── redemption_path.protocol.yaml
│       │   └── training_gateway.protocol.yaml
│       ├── core
│       │   ├── acces.protocol.yaml
│       │   ├── agent.protocol.yaml
│       │   ├── badge.protocol.yaml
│       │   ├── blocking.protocol.yaml
│       │   ├── core.protocol.yaml
│       │   ├── defense.protocol.yaml
│       │   ├── ethics.protocol.yaml
│       │   ├── identity.protocol.yaml
│       │   ├── key_mark.protocol.yaml
│       │   ├── ledger.protocol.yaml
│       │   ├── license.protocol.yaml
│       │   ├── model.protocol.yaml
│       │   ├── platform.protocol.yaml
│       │   ├── security.protocol.yaml
│       │   ├── system.protocol.yaml
│       │   └── tool.protocol.yaml
│       ├── defense
│       │   ├── federated_agent_routing.protocol.yaml
│       │   ├── forceful_key_trace.protocol.yaml
│       │   └── model_logic_trace.protocol.yaml
│       ├── ethics
│       │   ├── agent_ethics.protocol.yaml
│       │   ├── behavior_mapping.protocol.yaml
│       │   ├── in-the-loop_dispatch.protocol.yaml
│       │   ├── license_ethics.protocol.yaml
│       │   ├── model_ethics.protocol.yaml
│       │   ├── platform_ethics.protocol.yaml
│       │   ├── platform_isolation.protocol.yaml
│       │   ├── report_chain.protocol.yaml
│       │   └── tattle_tale.protocol.yaml
│       ├── identity
│       │   ├── key_identity.protocol.yaml
│       │   └── peer_identity.protocol.yaml
│       ├── ledger
│       │   ├── permissioned_read.protocol.yaml
│       │   ├── report_ingestion.protocol.yaml
│       │   └── write_only.protocol.yaml
│       ├── license
│       │   ├── create_license.protocol.yaml
│       │   ├── license_verification.protocol.yaml
│       │   └── suspend_license.protocol.yaml
│       ├── model
│       │   ├── agent_blacklisting.protocol.yaml
│       │   ├── agent_whitelisting.protocol.yaml
│       │   ├── eco.protocol.yaml
│       │   ├── elda.protocol.yaml
│       │   ├── fed.protocol.yaml
│       │   ├── hwy.protocol.yaml
│       │   └── twins.protocol.yaml
│       ├── platform
│       │   ├── 8teenwheelers.protocol.yaml
│       │   ├── bookstore.protocol.yaml
│       │   ├── client_tales.protocol.yaml
│       │   ├── fedispatching.protocol.yaml
│       │   ├── open-hwy.protocol.yaml
│       │   ├── owlusive_treasures.protocol.yaml
│       │   └── traka_pay.protocol.yaml
│       ├── protocols.json
│       ├── security
│       │   ├── kcbb_rcbb.protocol.yaml
│       │   └── key_rotation.protocol.yaml
│       ├── system
│       │   ├── beat_sync.protocol.yaml
│       │   ├── bet_engine.protocol.yaml
│       │   ├── book_os.protocol.yaml
│       │   ├── ink_burn.protocol.yaml
│       │   ├── keeper_db.protocol.yaml
│       │   ├── marker_router.protocol.yaml
│       │   ├── mark_kernel.protocol.yaml
│       │   ├── memory_scroll.protocol.yaml
│       │   ├── ribbon_trail.protocol.yaml
│       │   ├── token_stroke.protocol.yaml
│       │   └── trail_ledger.protocol.yaml
│       └── tool
│           ├── lock_tool.protocol.yaml
│           ├── unlock_tool.protocol.yaml
│           └── using_tool.protocol.yaml
├── repos
│   ├── codriver
│   │   ├── AUTHORS
│   │   ├── Cargo.toml
│   │   ├── CHANGELOG.md
│   │   ├── CODE_OF_CONDUCT.md
│   │   ├── CODEOWNERS
│   │   ├── codriver_note_001.md
│   │   ├── CONTRIBUTING.md
│   │   ├── core
│   │   │   ├── boot.rs
│   │   │   ├── context.rs
│   │   │   ├── kernel.rs
│   │   │   ├── memory.rs
│   │   │   ├── router.rs
│   │   │   └── scheduler..rs
│   │   ├── justfile
│   │   ├── LICENSE
│   │   ├── README.md
│   │   ├── SECURITY.md
│   │   └── src
│   │       ├── api
│   │       ├── bindings
│   │       ├── cli.rs
│   │       ├── commands
│   │       ├── handlers
│   │       ├── libs.rs
│   │       ├── logic
│   │       ├── main.rs
│   │       ├── model
│   │       ├── runners
│   │       ├── signal
│   │       ├── tests
│   │       ├── tools
│   │       └── utils
│   ├── freightdev
│   │   ├── CHANGELOG.md
│   │   ├── pricing
│   │   │   ├── package
│   │   │   ├── platform
│   │   │   └── pricing.json
│   │   ├── README.md
│   │   └── stories
│   │       ├── builder-tales
│   │       ├── stories.json
│   │       └── trucker-tales
│   ├── llama_runner
│   │   ├── AUTHORS
│   │   ├── build.rs
│   │   ├── Cargo.toml
│   │   ├── CHANGELOG.md
│   │   ├── CODE_OF_CONDUCT.md
│   │   ├── CODEOWNERS
│   │   ├── CONTRIBUTING.md
│   │   ├── justfile
│   │   ├── LICENSE
│   │   ├── llama.cpp
│   │   ├── README.md
│   │   ├── scripts
│   │   │   ├── check-ffi-headers.sh
│   │   │   └── regen-llama-engine.sh
│   │   ├── SECURITY.md
│   │   ├── src
│   │   │   ├── bindings
│   │   │   ├── lib.rs
│   │   │   ├── loaders
│   │   │   ├── main.rs
│   │   │   ├── prompts
│   │   │   ├── runners
│   │   │   └── tokens
│   │   └── wrapper.h
│   └── repos.json
├── schemas
│   ├── agents
│   │   ├── bigbear.agent.yaml
│   │   ├── cargoconnect.agent.yaml
│   │   ├── legallogger.agent.yaml
│   │   ├── packetpilot.agent.yaml
│   │   ├── truckertales.agent.yaml
│   │   └── whisperwitness.agent.yaml
│   ├── raw
│   │   ├── agent.schema.yaml
│   │   ├── meta.schema.yaml
│   │   ├── prompt.schema.yaml
│   │   └── raw.schema.yaml
│   └── schemas.json
├── tools
│   ├── controllers
│   │   ├── archbox
│   │   │   ├── archbox
│   │   │   └── install.sh
│   │   ├── controllers.json
│   │   ├── scriptctr
│   │   │   ├── install.sh
│   │   │   └── scriptctr
│   │   ├── tmpctr
│   │   │   ├── install.sh
│   │   │   └── tmpctr
│   │   └── zshctr
│   │       ├── install.sh
│   │       └── zshctr
│   ├── scripts
│   │   ├── check
│   │   │   └── syscheck.zsh
│   │   ├── convert
│   │   │   ├── json-to-yaml.sh
│   │   │   └── yaml-to-json.sh
│   │   ├── git
│   │   │   └── git-keeper.sh
│   │   ├── helper
│   │   │   ├── capitalize.sh
│   │   │   ├── git-keeper.sh
│   │   │   ├── log.sh
│   │   │   ├── recent-output.sh
│   │   │   ├── save_memory.sh
│   │   │   ├── syscheck.zsh
│   │   │   └── testsys.zsh
│   │   ├── markdown
│   │   │   ├── tree-copy.sh
│   │   │   ├── tree-delete.sh
│   │   │   ├── tree-make.sh
│   │   │   └── treestub-copy.zsh
│   │   ├── meta
│   │   │   └── barrel-to-yaml.sh
│   │   ├── models
│   │   │   ├── check-integrity.sh
│   │   │   ├── download-models.sh
│   │   │   ├── index-models.sh
│   │   │   ├── index-prompts.sh
│   │   │   ├── list-models.sh
│   │   │   ├── list-prompts.sh
│   │   │   ├── pull-all.sh
│   │   │   └── validate-models.sh
│   │   ├── scripts.json
│   │   ├── tools
│   │   │   ├── install-tools.sh
│   │   │   ├── Miniconda3-latest-Linux-x86_64.sh
│   │   │   ├── setup-tools.sh
│   │   │   └── setup-zsh.sh
│   │   └── ui
│   │       ├── barrel-ui.sh
│   │       ├── create-ui.sh
│   │       ├── rewrite-imports.sh
│   │       ├── unbarrel-ui.sh
│   │       └── validate-ui.sh
│   └── tools.json
└── workspace.json