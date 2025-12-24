core/
├── bootstraps/              # agent launcher, env checks, preflight
│   ├── startup.yaml
│   └── healthcheck.sh
├── constants/               # hardcoded truths or system config
│   ├── env/                 # environment vars and modes
│   ├── memory/              # agent's baseline memory blocks
│   │   ├── goals/
│   │   ├── intents/
│   │   ├── prompts/
│   │   ├── protocols/
│   │   ├── roles/
│   │   └── permissions/
│   │       ├── levels/
│   │       ├── limits/
│   │       ├── roles/
│   │       └── zones/
│   └── index.constants.yaml
├── context/                 # live agent context during runtime
│   ├── active/
│   ├── cache/
│   ├── notebook/
│   └── index.context.yaml
├── logic/                   # full execution graph & logic trees
│   ├── extractor/
│   │   └── context/
│   ├── generate/
│   │   ├── logic/
│   │   ├── prompt/
│   │   ├── script/
│   │   └── test/
│   ├── hydrator/            # used to inject or merge state
│   ├── loader/              # loads logic chains or resources
│   ├── parser/              # AST or token interpreters
│   ├── router/              # logic switching or model selection
│   ├── signal/
│   │   ├── agent/
│   │   ├── system/
│   │   └── task/
│   ├── summarize/
│   ├── vectorize/           # embedding, vector logic
│   └── index.logic.yaml
├── rules/                   # guardrails, filters, permissions
│   ├── safe.rules.yaml
│   ├── access.rules.yaml
│   └── index.rules.yaml
├── tasks/                   # agent's task queue (can be runtime)
│   ├── active/
│   ├── completed/
│   ├── failed/
│   ├── planed/
│   ├── queue/
│   └── index.tasks.yaml
├── index.core.yaml
