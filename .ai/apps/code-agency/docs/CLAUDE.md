```architect-gtx [SENDING]
Analyzing the authentication requirements...
```

```worker-i9 [TYPING]
...
```

```worker-i9
Here's the implementation:
<code>
```

**Typing Indicator**: Agents write `[TYPING]` or `[SENDING]` tags, others can show status
**Message Delimiter**: Triple backticks with agent name
**Job References**: `@job-123` to link messages to jobs

## Improvements I'd Add

1. **Job State Machine**:
   - `queued` → `assigned` → `in_progress` → `review` → `completed`/`failed`
   - Jobs stored as YAML/JSON with metadata (assignee, dependencies, priority)

2. **Agent Capabilities Declaration**:
   - Each agent declares what it's good at (reasoning, code gen, testing)
   - Job dispatcher routes based on capabilities

3. **Context Preservation**:
   - Jobs include context files, previous outputs
   - Agents can request context from other agents

4. **Consensus Mechanism**:
   - For architecture decisions, multiple agents vote
   - Prevents single-agent mistakes on critical choices

5. **Interrupt System**:
   - You or architect can `@interrupt` to halt current job
   - Priority queue for urgent tasks

6. **Rate Limiting**:
   - Agents throttle messages (don't spam channels)
   - Backpressure if job queue is full

## Config Examples

**`machines.yaml`**:

```yaml
agents:
  architect-gtx:
    host: gtx-machine:11434
    model: qwen2.5:32b-instruct-q4_K_M
    role: architect
    capabilities: [reasoning, architecture, planning]
    permissions: [admin, general, workflow]

  worker-i9:
    host: i9-machine:11434
    model: qwen2.5-coder:14b-instruct-q5_K_M
    role: developer
    capabilities: [code_generation, refactoring]
    permissions: [general, workflow]

  worker-npu:
    host: localhost:11434
    model: qwen2.5-coder:7b-instruct-q4_K_M
    role: developer
    capabilities: [quick_tasks, testing]
    permissions: [general, workflow]

  worker-smol:
    host: smol-machine:11434
    model: qwen2.5-coder:1.5b-instruct-q4_K_M
    role: utility
    capabilities: [parsing, monitoring]
    permissions: [general]
```

**`channels.yaml`**:

```yaml
channels:
  general:
    description: "Casual conversation, brainstorming"
    members: [all]
    typing_indicators: true

  admin:
    description: "Task assignment, system coordination"
    members: [user, architect-gtx]
    notifications: true

  workflow:
    description: "Workers coordinating on jobs"
    members: [worker-i9, worker-npu, worker-smol, architect-gtx]
    job_references: true
```

**`jobs.yaml`** (individual job file in `jobs/queue/`):

```yaml
id: job-001
title: "Implement user authentication API"
status: queued
priority: high
assigned_to: null
created_by: user
dependencies: []
context_files:
  - docs/api-spec.md
  - shared/ai-workspace/chats/admin.md#L45-60
description: |
  Build REST API for user auth with JWT tokens
requirements:
  - Express.js framework
  - PostgreSQL database
  - bcrypt for passwords
deliverables:
  - src/routes/auth.js
  - tests/auth.test.js
```

## Worker Architecture

**`worker.py`** would:

1. Load config, identify itself
2. Join permitted channels (watch .md files)
3. Poll job queue for assignments matching capabilities
4. When job assigned:
   - Load context files
   - Send `[TYPING]` to workflow channel
   - Call Ollama with full context
   - Stream output to workflow channel with `[SENDING]`
   - Update job status
   - Ping system.log with heartbeat
5. Graceful error handling → error.log

**`client.py`** (your interface):

- TUI showing all channels simultaneously
- Create jobs from admin channel with `/job create`
- Assign with `/job assign job-001 worker-i9`
- Real-time typing indicators
- Job status sidebar

## Questions for You

1. **Job Assignment**: Auto-assign based on capabilities, or you manually assign?
2. **Consensus**: Should architect review all code before marking complete?
3. **Message History**: Keep full chat history or rotating window?
4. **Notifications**: Desktop alerts when agents need your input?
5. **Agent Personas**: Should agents have distinct "personalities" in chat or stay technical?

**Want me to build the actual scripts with this architecture?** I'll write proper Python with config loading, no hardcoded bullshit.
