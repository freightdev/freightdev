# CoDriver Adaptation Plan

**Date:** 2025-11-20
**Status:** 📋 Planning Phase
**Goal:** Adapt existing autonomous coordinator to OpenHWY agency architecture

---

## 🎯 WHAT WE HAVE (Existing Code)

### Current CoDriver (from ai-agency project)

**Location:** `~/freightdev/openhwy/.ai/agents/codriver/`

**Capabilities:**
- ✅ Autonomous agent with decision-making loop
- ✅ Tool system (bash, file ops, git, search)
- ✅ LLM abstraction (Anthropic, OpenAI, Local/Ollama)
- ✅ Failover management
- ✅ Health checking
- ✅ Well-structured Rust codebase

**Technology Stack:**
- Rust (Tokio async runtime)
- Axum (HTTP framework)
- Tonic (gRPC framework)
- reqwest (HTTP client)
- Quality error handling

**Code Quality:** ⭐ Excellent
- Clean trait-based design
- Proper error handling
- Async/await patterns
- Type-safe

---

## ❌ WHAT DOESN'T FIT OpenHWY

### Issues with Current Implementation:

1. **Autonomous Loop Problem:**
   - Current: Runs 2-minute decision loops autonomously
   - Need: Wait for tasks from chat file, execute on demand

2. **No Chat Communication:**
   - Current: No chat file monitoring
   - Need: Read from `.ai/chats/codriver.txt`, write responses

3. **No Cluster Orchestration:**
   - Current: Assumes single Ollama endpoint (localhost:11435)
   - Need: SSH to L1-L4 based on task type

4. **No Task Routing:**
   - Current: Generic LLM requests
   - Need: Route Vision→L1, Code→L3, Reasoning→L2, Quick→L4

5. **No Gemini Integration:**
   - Current: Only Anthropic/OpenAI/Local
   - Need: Google Gemini Pro integration

6. **Wrong Paths:**
   - Current: References old project paths
   - Need: Update to OpenHWY structure

---

## ✅ WHAT STAYS THE SAME

### Keep These Components:

1. **`lib.rs` - Coordinator trait system** ✅
   - Excellent abstraction
   - Failover manager works great
   - Just add Gemini implementation

2. **`tools.rs` - Tool system** ✅
   - Bash, file ops, git already work
   - Keep as-is, maybe add SSH tool

3. **Error handling** ✅
   - thiserror patterns are solid
   - Keep the same approach

4. **Cargo.toml dependencies** ✅
   - All good libraries
   - Maybe add: `ssh2` for cluster access

---

## 🔄 WHAT NEEDS TO CHANGE

### 1. Replace Autonomous Loop with Chat Monitoring

**Current (`main.rs`):**
```rust
loop {
    // Autonomous decision making every 2 minutes
    let decision = self.make_decision(&context).await?;
    sleep(Duration::from_secs(120)).await;
}
```

**New Architecture:**
```rust
loop {
    // Monitor chat file for new tasks
    let new_messages = chat_monitor.check_for_new_messages().await?;

    for message in new_messages {
        // Process task
        let result = self.process_task(message).await?;

        // Write response to chat
        chat_writer.append_message("codriver", result).await?;
    }

    // Short sleep (don't poll too fast)
    sleep(Duration::from_millis(500)).await;
}
```

### 2. Add Chat File System

**New Files Needed:**
```
src/chat/
├── mod.rs          - Chat module
├── monitor.rs      - Watch .ai/chats/*.txt files
├── parser.rs       - Parse "agent: message" format
└── writer.rs       - Append to chat files
```

**Features:**
- Watch `.ai/chats/codriver.txt` for new lines
- Parse format: `user: "message"`
- Track last processed line (cursor)
- Append responses: `codriver: "message"`

### 3. Add Cluster Orchestration

**New Files:**
```
src/cluster/
├── mod.rs          - Cluster module
├── node.rs         - Node struct (L1-L4 config)
├── router.rs       - Task routing logic
├── executor.rs     - SSH + ollama command execution
└── health.rs       - Cluster health monitoring
```

**Node Configuration:**
```rust
struct OllamaNode {
    name: String,              // "L1", "L2", "L3", "L4"
    hostname: String,          // "workbox", "hostbox", "helpbox", "callbox"
    ip: String,                // "192.168.12.136", etc
    specialization: NodeType,  // Vision, Reasoning, Code, Quick
    models: Vec<String>,       // ["llava-phi3:3.8b", ...]
}

enum NodeType {
    Vision,      // L1
    Reasoning,   // L2
    Code,        // L3
    Quick,       // L4
}
```

**Task Routing:**
```rust
fn route_task(task: &str) -> (OllamaNode, String) {
    if task.contains("component") || task.contains("code") {
        (L3, "codestral:22b")
    } else if task.contains("image") || task.contains("OCR") {
        (L1, "llava-llama3:8b")
    } else if task.contains("plan") || task.contains("strategy") {
        (L2, "qwen2.5:14b")
    } else {
        (L4, "phi4-mini:3.8b")
    }
}
```

### 4. Add Gemini Integration

**Update `lib.rs`:**
```rust
pub struct GeminiCoordinator {
    api_key: String,
    model: String,
    client: reqwest::Client,
}

impl GeminiCoordinator {
    pub fn new(api_key: String) -> Self {
        Self {
            api_key,
            model: "gemini-pro".to_string(),
            client: reqwest::Client::new(),
        }
    }
}

#[async_trait]
impl Coordinator for GeminiCoordinator {
    async fn generate(&self, request: GenerationRequest) -> Result<GenerationResponse> {
        // Google AI API call
        // ...
    }
}
```

### 5. Update File Paths

**Find and replace:**
- Old project paths → OpenHWY paths
- `/path/to/old/project` → `~/freightdev/openhwy`
- Update all hardcoded paths

---

## 📋 IMPLEMENTATION PLAN

### Phase 1: Chat Communication (Day 1)

**Tasks:**
1. Create `src/chat/` module
2. Implement file monitoring
3. Implement message parsing
4. Implement message writing
5. Test: Write to `codriver.txt`, CoDriver responds

**Success Criteria:**
```bash
# Terminal 1
echo 'user: "hello codriver"' >> .ai/chats/codriver.txt

# Terminal 2 (CoDriver running)
# Detects new message
# Responds: codriver: "Hello! Ready for tasks."

# Verify
cat .ai/chats/codriver.txt
# user: "hello codriver"
# codriver: "Hello! Ready for tasks."
```

### Phase 2: Cluster Orchestration (Day 2-3)

**Tasks:**
1. Create `src/cluster/` module
2. Define node configurations (L1-L4)
3. Implement SSH execution
4. Implement task routing
5. Test: Route simple task to L3

**Success Criteria:**
```bash
echo 'user: "generate a button component"' >> .ai/chats/codriver.txt

# CoDriver:
# - Detects "component" → Routes to L3
# - SSHs to helpbox
# - Runs: ollama run codestral:22b < prompt
# - Returns result
# - Writes to chat

cat .ai/chats/codriver.txt
# codriver: "Task routed to L3 (codestral:22b)"
# codriver: "Component generated. 45 lines. Ready."
```

### Phase 3: Gemini Integration (Day 4)

**Tasks:**
1. Add Gemini coordinator to `lib.rs`
2. Get API key from Jesse
3. Test Gemini calls
4. Add to failover chain

**Success Criteria:**
```bash
echo 'user: "refactor this file: path/to/file.tsx"' >> .ai/chats/codriver.txt

# CoDriver:
# - Detects complex task → Routes to Gemini
# - Calls Gemini API
# - Returns result

cat .ai/chats/gemini.txt
# gemini: "Refactoring complete. 234 lines changed."
```

### Phase 4: Integration & Testing (Day 5)

**Tasks:**
1. Full workflow test (User → CoDriver → Cluster → Result)
2. Error handling (node down, model busy)
3. Load balancing (fallback models)
4. Health monitoring

**Success Criteria:**
- CoDriver handles multiple tasks
- Properly routes based on task type
- Recovers from failures
- Reports status clearly

---

## 🔧 CODE CHANGES BREAKDOWN

### Files to CREATE:

```
.ai/agents/codriver/src/
├── chat/
│   ├── mod.rs       - NEW
│   ├── monitor.rs   - NEW
│   ├── parser.rs    - NEW
│   └── writer.rs    - NEW
│
└── cluster/
    ├── mod.rs       - NEW
    ├── node.rs      - NEW
    ├── router.rs    - NEW
    ├── executor.rs  - NEW
    └── health.rs    - NEW
```

### Files to MODIFY:

```
├── main.rs          - Replace autonomous loop with chat monitoring
├── lib.rs           - Add GeminiCoordinator
├── Cargo.toml       - Add ssh2, notify (file watching)
└── agent.rs         - Simplify (remove decision loop)
```

### Files to KEEP AS-IS:

```
├── tools.rs         - ✅ No changes needed
├── llm.rs           - ✅ Maybe minor tweaks
├── system.rs        - ✅ Probably fine
└── services/        - ✅ Keep for future HTTP/gRPC API
```

---

## 🧪 TESTING STRATEGY

### Unit Tests:

```rust
#[cfg(test)]
mod tests {
    #[tokio::test]
    async fn test_chat_parsing() {
        let line = "user: \"hello codriver\"";
        let msg = parse_message(line);
        assert_eq!(msg.agent, "user");
        assert_eq!(msg.content, "hello codriver");
    }

    #[tokio::test]
    async fn test_task_routing() {
        let task = "generate a React component";
        let (node, model) = route_task(task);
        assert_eq!(node.name, "L3");
        assert_eq!(model, "codestral:22b");
    }
}
```

### Integration Tests:

```bash
# Test 1: Simple echo
echo 'user: "ping"' >> .ai/chats/codriver.txt
# Expect: codriver: "pong"

# Test 2: Code generation
echo 'user: "create button component"' >> .ai/chats/codriver.txt
# Expect: Routes to L3, generates code

# Test 3: Vision task
echo 'user: "OCR this image: path.png"' >> .ai/chats/codriver.txt
# Expect: Routes to L1, processes with llava

# Test 4: Cluster health
echo 'user: "cluster status"' >> .ai/chats/codriver.txt
# Expect: Reports L1-L4 health
```

---

## 📊 TIMELINE ESTIMATE

**Total Time:** 5-7 days

- Day 1: Chat communication (4-6 hours)
- Day 2-3: Cluster orchestration (8-12 hours)
- Day 4: Gemini integration (4-6 hours)
- Day 5: Testing & polish (4-8 hours)

**With Claude helping:** Could compress to 2-3 days

---

## 🚨 RISKS & MITIGATIONS

### Risk 1: SSH Permissions
**Problem:** SSH might fail if keys not set up correctly
**Mitigation:** Test SSH manually first, verify all nodes accessible

### Risk 2: Ollama Port Conflicts
**Problem:** Each node might use different ports
**Mitigation:** Detect ports dynamically, make configurable

### Risk 3: Chat File Corruption
**Problem:** Multiple writers could corrupt chat files
**Mitigation:** Append-only, use file locking

### Risk 4: Task Routing Errors
**Problem:** Might route to wrong node
**Mitigation:** Explicit routing rules, add keywords

---

## ✅ SUCCESS CRITERIA

### CoDriver v1.0 is DONE when:

1. ✅ Monitors `.ai/chats/codriver.txt` for new messages
2. ✅ Parses and responds to user messages
3. ✅ Routes tasks to correct Ollama node (L1-L4)
4. ✅ Executes tasks via SSH
5. ✅ Handles failures gracefully
6. ✅ Reports status to chat
7. ✅ Can coordinate with Gemini
8. ✅ Works without Claude present

### Final Test:

```bash
# Jesse writes task
echo 'user: "create LoadCard component with drag handle"' >> .ai/chats/codriver.txt

# CoDriver (autonomous):
# 1. Detects message
# 2. Determines: Code generation task
# 3. Routes to: L3 (helpbox, codestral:22b)
# 4. Generates component
# 5. Saves to: .ai/projects/complete/LoadCard.tsx
# 6. Reports: "Task complete"

# Result
cat .ai/chats/codriver.txt
# codriver: "Received: LoadCard component request"
# codriver: "Routing to: L3 (codestral:22b)"
# codriver: "Generation complete: 127 lines"
# codriver: "Saved to: .ai/projects/complete/LoadCard.tsx"
# codriver: "Status: ✅ Ready for review"
```

**If this works, CoDriver v1.0 is SHIPPED.** 🚀

---

## 🎯 NEXT STEPS

### Immediate (Jesse to decide):

1. **Review this plan** - Does the architecture make sense?
2. **Confirm approach** - Chat files vs HTTP API vs gRPC?
3. **Get Gemini API key** - If we're integrating Gemini
4. **Approve build** - Ready for Claude to start coding?

### Once Approved:

1. Claude builds Phase 1 (chat communication)
2. Test with simple tasks
3. Build Phase 2 (cluster orchestration)
4. Test with real Ollama tasks
5. Iterate until CoDriver replaces Claude

---

**Created By:** Claude (Anthropic AI)
**For:** Jesse E.E.W. Conley
**Date:** 2025-11-20
**Status:** 📋 Awaiting approval to build

🚛💪
