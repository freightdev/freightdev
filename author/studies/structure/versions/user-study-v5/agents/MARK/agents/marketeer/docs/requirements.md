# Requirements

## System Requirements

- **Operating System**: Linux, macOS, or WSL on Windows
- **Shell**: Bash 4.0 or higher
- **Dependencies**: 
  - `grep` (GNU grep recommended)
  - `sed`
  - `awk`
  - Standard POSIX utilities

## Optional Dependencies

- **yq** - For advanced YAML parsing (install with `sudo snap install yq` or `brew install yq`)
- **jq** - For JSON processing in advanced schemas
- **git** - For version control integration schemas

## Schema Requirements

### Minimum Schema Structure
```yaml
name: "Tool Name"
actions:
  - type: "action_type"
```

### Recommended Schema Structure
```yaml
name: "Tool Name"
description: "What this tool does"
version: "1.0"

variables:
  key1: "default_value"
  key2: ""

prompts:
  - key: "input_name"
    question: "What is your input?"
    type: "text|select|confirm|number"
    options: ["opt1", "opt2"]  # for select type
    default: "default_value"
    required: true
    validation: "regex_pattern"

conditions:
  - name: "condition_name"
    expression: "{{variable}} == 'value'"

actions:
  - type: "create_file|run_command|copy_file|template"
    condition: "condition_name"  # optional
    # action-specific parameters
```

## Action Types

### Core Actions
- `create_file` - Create files from templates
- `run_command` - Execute shell commands
- `copy_file` - Copy files with variable substitution
- `template` - Process template files
- `prompt` - Interactive user input
- `validate` - Validate inputs or conditions

### Extended Actions (Future)
- `http_request` - Make API calls
- `database_query` - Database operations
- `git_operation` - Git commands
- `docker_operation` - Docker/container operations
- `ssh_command` - Remote command execution

## Variable Substitution

Variables are substituted using `{{variable_name}}` syntax:
- User inputs: `{{user_input_key}}`
- Schema variables: `{{variable_key}}`
- Environment variables: `{{env.ENV_VAR}}`
- System info: `{{system.hostname}}`, `{{system.user}}`

## File Organization

```
~/.config/marketeer/
├── config.yaml           # Global configuration
├── schemas/              # User schemas
├── templates/            # Template files
└── cache/               # Cached data

/usr/local/share/marketeer/
├── schemas/             # System schemas
└── templates/           # System templates
```

## Permissions

- **Read**: Schema files, template files, input files
- **Write**: Output directories, log files, created files
- **Execute**: Commands defined in actions (use with caution)

## Security Considerations

- Schemas can execute arbitrary commands - only run trusted schemas
- Variables are not sandboxed - validate inputs carefully
- File operations respect user permissions
- No automatic privilege escalation