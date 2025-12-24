memory/
└── state/
    ├── index.state.yaml             # Index of all tracked state files
    ├── mode/
    │   ├── current.yaml             # Current operational mode (e.g., assist, learn, idle)
    │   └── history.yaml             # Previous modes (chronological)
    ├── flags/
    │   ├── debug.yaml               # On/off switch for debug mode
    │   ├── verbose.yaml             # Verbosity toggle
    │   └── fail_safe.yaml           # Error recovery flag
    ├── position/
    │   ├── file.yaml                # Last active file (path, line, column)
    │   └── topic.yaml               # Last known conversation or context name
    ├── runtime/
    │   ├── input.yaml               # Most recent user input
    │   ├── output.yaml              # Most recent response
    │   ├── loop.yaml                # Active execution loop metadata
    │   └── ticks.yaml               # Number of agent ticks (cycles since start)
    ├── usage/
    │   ├── tokens.yaml              # Token count and budget
    │   ├── limits.yaml              # Throttles or constraints
    │   └── timestamps.yaml          # Last-used and time-based markers
    ├── emotion/
    │   ├── current.yaml             # Feeling (e.g. "confident", "stuck", "curious")
    │   └── reasons.yaml             # Why it feels that way
    ├── queue/
    │   ├── inbox.yaml               # Incoming requests/tasks
    │   └── stack.yaml               # LIFO stack for focus tasks
    ├── locks/
    │   ├── api.yaml                 # External resource locks
    │   ├── system.yaml              # System resource locks
    │   └── task.yaml                # Current task lock (if any)
    └── focus/
        ├── agent.yaml               # Focused sub-agent (if multitasking)
        └── goal.yaml                # Current objective in mind
