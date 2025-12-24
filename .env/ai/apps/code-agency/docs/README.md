# AI Multi-Agent Workspace

A distributed multi-agent AI system for collaborative development across multiple machines.

## Architecture

```
User (you) ←→ Chat Client (ai-chat)
                    ↓
            Shared Workspace (NFS)
                    ↑
    ┌───────────┬───┴───┬────────────┐
    │           │       │            │
Architect    Worker1  Worker2   Utility
 (GTX)        (i9)    (NPU)     (Smol)
32B Model   14B Model 7B Model  1.5B Model
```

## Directory Structure

```
~/shared/
├── configs/
│   ├── machines.yaml          # Agent definitions and capabilities
│   └── channels.yaml          # Communication channels and permissions
├── scripts/
│   ├── worker.py              # Agent daemon
│   ├── client.py              # Interactive chat client
│   └── monitor.py             # System monitor
└── ai-workspace/
    ├── logs/
    │   ├── error.log          # Error tracking
    │   ├── ping.log           # Agent heartbeats
    │   └── system.log         # System events
    ├── chats/
    │   ├── general.md         # General discussion
    │   ├── admin.md           # You + architect coordination
    │   └── workflow.md        # Workers collaborating on jobs
    └── jobs/
        ├── queue/             # Pending jobs
        ├── active/            # In-progress jobs
        └── completed/         # Finished jobs
```

## Communication Protocol

### Message Format

Messages in chat channels follow this format:

````markdown
```agent-name [STATUS]
Message content here
```
````

```

**Status Indicators:**
- `[TYPING]` - Agent is processing/thinking
- `[SENDING]` - Agent is about to send response
- `[WORKING]` - Agent is actively working on a job

### Channels

1. **general** - Open discussion, questions, brainstorming
   - All agents can participate
   - Casual conversation

2. **admin** - Task assignment and coordination
   - User + Architect only
   - High-priority decisions
   - Job creation and assignment

3. **workflow** - Active job coordination
   - All workers + Architect
   - Implementation discussions
   - Code reviews

## Job System

### Job Lifecycle

```

queued → assigned → in_progress → completed/failed

````

### Job Structure

```yaml
id: job-001
title: "Implement authentication API"
status: queued
priority: high
assigned_to: worker-i9
created_by: user
created_at: 2025-12-15T22:00:00
requirements:
  - Express.js framework
  - JWT tokens
  - PostgreSQL
deliverables:
  - src/routes/auth.js
  - tests/auth.test.js
context_files:
  - docs/api-spec.md
````

### Creating Jobs

**Via chat client:**

```
/job create
```

**Manually:**
Create YAML file in `~/shared/ai-workspace/jobs/queue/`

### Assigning Jobs

```
/job assign job-001 worker-i9
```

## Agent Roles

### Architect (GTX - 32B)

- **Capabilities:** Reasoning, architecture, planning, code review
- **Channels:** admin, general, workflow
- **Use for:** System design, complex problem decomposition, technical decisions

### Worker-i9 (14B)

- **Capabilities:** Code generation, refactoring, implementation
- **Channels:** general, workflow
- **Use for:** Primary development work, complex implementations

### Worker-NPU (7B)

- **Capabilities:** Quick tasks, testing, documentation
- **Channels:** general, workflow
- **Use for:** Parallel work, fast iterations, testing

### Worker-Smol (1.5B)

- **Capabilities:** Parsing, monitoring, simple transforms
- **Channels:** general
- **Use for:** Log parsing, data transformation, monitoring tasks

## Installation

### 1. Run Setup Script

```bash
chmod +x setup.sh
./setup.sh
```

### 2. Copy Scripts

Copy these files to `~/shared/scripts/`:

- `worker.py`
- `client.py`
- `monitor.py`

```bash
cp worker.py client.py monitor.py ~/shared/scripts/
chmod +x ~/shared/scripts/*.py
```

### 3. Configure Machines

Edit `~/shared/configs/machines.yaml` with your actual machine hostnames:

```yaml
agents:
  architect-gtx:
    host: 192.168.1.10:11434 # Replace with actual IP/hostname
    # ...
```

### 4. Start Workers

On each machine:

```bash
# GTX machine
ai-worker architect-gtx

# i9 machine
ai-worker worker-i9

# NPU machine
ai-worker worker-npu

# Smol machine
ai-worker worker-smol
```

### 5. Optional: Enable as Services

```bash
# Enable to start on boot
systemctl --user enable ai-worker@architect-gtx
systemctl --user start ai-worker@architect-gtx

# Check status
systemctl --user status ai-worker@architect-gtx
```

## Usage

### Chat Client

```bash
ai-chat
```

**Commands:**

- `/channel <name>` - Switch channel (general, admin, workflow)
- `/job create` - Create new job interactively
- `/job list` - List all jobs
- `/job assign <id> <agent>` - Assign job to agent
- `/status` - Show agent status
- `/help` - Show help
- `/quit` - Exit

### System Monitor

```bash
ai-monitor
```

Displays real-time:

- Agent status (active/idle/offline)
- Job statistics
- Recent errors

### Direct Mentions

Mention agents in chat to get their attention:

```
@architect-gtx how should I structure this database?
```

## Configuration

### Adding New Agents

Edit `~/shared/configs/machines.yaml`:

```yaml
agents:
  new-agent:
    host: new-machine:11434
    model: qwen2.5-coder:7b
    role: developer
    capabilities:
      - code_generation
    permissions:
      - general
      - workflow
```

Then start worker:

```bash
ai-worker new-agent
```

### Changing Models

Update the `model` field in `machines.yaml`:

```yaml
architect-gtx:
  model: qwen2.5:32b-instruct-q6_K # Higher quality
```

Restart the worker for changes to take effect.

### Adding Channels

Edit `~/shared/configs/channels.yaml`:

```yaml
channels:
  testing:
    description: "Testing and QA coordination"
    members:
      - worker-npu
      - worker-smol
```

Create the chat file:

```bash
touch ~/shared/ai-workspace/chats/testing.md
```

## Workflow Examples

### Example 1: Build a REST API

**In admin channel:**

```
/job create
Title: Build user authentication API
Description: Implement JWT-based auth with PostgreSQL
Requirements:
  - Express.js
  - JWT tokens
  - Password hashing
  - PostgreSQL
Deliverables:
  - src/routes/auth.js
  - tests/auth.test.js
  - docs/api.md
```

**Assign job:**

```
/job assign job-001 worker-i9
```

**Worker-i9 executes:**

- Reads requirements from job file
- Writes to workflow channel with `[WORKING]` status
- Generates code using Ollama
- Posts result to workflow channel
- Updates job status to completed

**You review:**

- Check workflow channel for output
- Review code
- Request changes by creating follow-up job

### Example 2: Architecture Discussion

**In admin channel:**

```
@architect-gtx I need to build a real-time chat application. What architecture would you recommend?
```

**Architect responds:**

- Analyzes requirements
- Proposes architecture (WebSocket server, Redis pub/sub, etc.)
- Creates job templates for implementation

**You assign work:**

```
/job assign job-002 worker-i9  # WebSocket server
/job assign job-003 worker-npu # Redis integration
```

### Example 3: Code Review

**In workflow channel:**

```
@architect-gtx please review the auth implementation in job-001
```

**Architect:**

- Loads completed job
- Reviews code
- Provides feedback in workflow channel
- Suggests improvements

## Troubleshooting

### Agent Not Responding

1. Check if agent is running:

   ```bash
   ai-monitor
   ```

2. Check system logs:

   ```bash
   tail -f ~/shared/ai-workspace/logs/system.log
   ```

3. Check if Ollama is running on that machine:
   ```bash
   curl http://machine-host:11434/api/tags
   ```

### Jobs Not Processing

1. Verify job is assigned:

   ```bash
   cat ~/shared/ai-workspace/jobs/queue/job-XXX.yaml
   ```

2. Check worker logs:

   ```bash
   tail -f ~/shared/ai-workspace/logs/system.log | grep worker-name
   ```

3. Check error log:
   ```bash
   tail ~/shared/ai-workspace/logs/error.log
   ```

### NFS Issues

1. Verify NFS export:

   ```bash
   sudo exportfs -v
   ```

2. Test mount on client:

   ```bash
   touch ~/shared/ai-workspace/test.txt
   # Check if visible on server
   ```

3. Remount if needed:
   ```bash
   sudo umount ~/shared/ai-workspace
   sudo mount -a
   ```

## Best Practices

1. **Use Admin Channel for Planning**
   - Discuss architecture with architect first
   - Break down complex tasks into jobs
   - Get consensus before implementation

2. **Assign Jobs Based on Capabilities**
   - Complex reasoning → Architect
   - Code generation → Worker-i9
   - Quick tasks → Worker-NPU
   - Parsing/monitoring → Worker-Smol

3. **Keep Context Files Updated**
   - Reference relevant docs in job files
   - Agents will load context automatically

4. **Monitor System Health**
   - Run `ai-monitor` regularly
   - Check ping logs for offline agents
   - Review error logs daily

5. **Clean Up Completed Jobs**
   - Archive old jobs periodically
   - Keep job queue manageable

## Advanced Usage

### Custom Prompting

Workers automatically get context from:

- Job description and requirements
- Referenced context files
- Recent channel messages

You can improve results by:

- Providing detailed requirements
- Including example code in context files
- Being specific about deliverables

### Parallel Job Execution

Assign independent jobs to different workers:

```bash
/job assign job-001 worker-i9   # Backend API
/job assign job-002 worker-npu  # Frontend components
```

Workers execute simultaneously.

### Agent Collaboration

Workers can discuss in workflow channel:

```
Worker-i9: I need the auth middleware before I can implement the protected routes
Worker-NPU: I'll handle the middleware, should be done in 5 minutes
```

## Extending the System

### Adding New Job Types

Create job templates in `~/shared/ai-workspace/jobs/templates/`:

```yaml
# template-api.yaml
title: "API Endpoint: [NAME]"
requirements:
  - Express.js framework
  - Proper error handling
  - Input validation
deliverables:
  - src/routes/[name].js
  - tests/[name].test.js
```

### Custom Worker Behaviors

Modify `worker.py` to add:

- Custom job handlers
- Specialized capabilities
- Integration with external tools

### Integration with CI/CD

Workers can:

- Commit code directly (add git commands)
- Trigger builds
- Run tests
- Deploy code

Add to worker capabilities as needed.

## Performance Tips

1. **Model Selection**
   - Use smallest model that works for the task
   - Reserve 32B architect for complex reasoning
   - Use 1.5B for simple parsing/monitoring

2. **Context Window Management**
   - Keep context files concise
   - Reference specific sections, not entire docs
   - Clean up old chat messages periodically

3. **Load Balancing**
   - Distribute jobs across workers
   - Don't overload single agent
   - Use worker-npu for quick iterations during dev

4. **Network Optimization**
   - Use wired connections for NFS
   - Consider local Ollama cache
   - Monitor NFS performance

## License

This system is for personal/internal use. Customize as needed.

## Support

Check logs:

- System: `~/shared/ai-workspace/logs/system.log`
- Errors: `~/shared/ai-workspace/logs/error.log`
- Pings: `~/shared/ai-workspace/logs/ping.log`

Monitor: `ai-monitor`
