# 🧠 Execution Memory & Vaulting
vault/
├── trails/
│   └── completed/            # .trail.yaml after execution
├── ribbons/
│   └── verified/             # Archived .rib.yaml ribbons
├── agents/
│   └── memory/               # Long-term agent memory snapshots
├── sessions/
│   └── <id>.yaml             # Archived runtime sessions

# 📥 Incoming Execution Queue
inbox/
├── dropped/                  # Files dropped here will be auto-loaded
├── deferred/                 # Queued, scheduled .mark files
├── failed/                   # Crashed or error-producing trails
├── processed/                # Completed, cleaned up inbox entries

# 🧾 Schema & Spec Protocols
spec/
├── mark.schema.yaml          # .mark structure spec
├── ribbon.schema.yaml        # .rib.yaml file structure
├── agent.schema.yaml         # Agent structure
├── context.schema.yaml       # Runtime/session context
├── process.schema.yaml       # Process instruction format
├── flags.yaml                # CLI + agent-understood flags
├── markdown.tokens.yaml      # Symbolic language guide (e.g. *~*, ::{{}}, etc)

# 🧠 Identity / Role Mapping
identity/
├── registry.yaml             # All known agent/human identities
├── agent/
│   ├── elda.yaml
│   ├── fed.yaml
│   ├── guest.yaml
│   └── root.yaml
├── user/
│   ├── jesse.yaml
│   └── dev.yaml

# 🧾 Contracts & Capabilities
contracts/
├── elda/
│   ├── onboarding.mark
│   └── response.mark
├── fed/
│   └── dispatch.mark
├── guest/
│   └── readonly.mark

# 💬 Execution Comms / Prompt-Response Logs
comms/
├── threads/
│   └── elda-session-01.md
├── prompts/
│   ├── latest.json
│   └── logs/
├── replies/
│   └── elda-response.yaml
├── logs/
│   └── conversation.ndjson

# 🛰️ System Signal Layer
signal/
├── heartbeat.log             # Active pulse of kernel
├── load.json                 # CPU/memory/load tracking
├── state.yaml                # Current state summary
├── clock.log                 # Timestamp events (trail start/end/etc)
├── metrics.ndjson            # Trail-level stats and telemetry

# 📊 Agent Trail Insights
trailmaps/
├── index.yaml                # All known trail IDs
├── heatmap.json              # Popular routes and agents
├── flowcharts/
│   └── onboarding-graph.dot

# 📁 Book Indexes
book/
├── bookmarks/
│   └── elda-onboarding.md
├── licenses/
│   └── openhwy-license.mark
├── process/
│   ├── catch.yaml
│   ├── return.yaml
│   └── upload.yaml
