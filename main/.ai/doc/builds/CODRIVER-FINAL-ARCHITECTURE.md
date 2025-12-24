# CoDriver Final Architecture

**Date:** 2025-11-20
**Status:** 🎯 FINAL DESIGN - Ready to Build
**Jesse's Corrections Applied:** ✅

---

## 🧠 CODRIVER'S BRAIN

### CoDriver thinks using: **hostbox qwen2.5:14b (L2)**

**NOT:**
- ❌ Claude API
- ❌ Gemini API
- ❌ OpenAI API
- ❌ Any cloud service

**YES:**
- ✅ Local Ollama on hostbox
- ✅ qwen2.5:14b for decision-making
- ✅ 100% offline operation
- ✅ Zero API costs
- ✅ No rate limits

**How it works:**
```rust
// CoDriver asks itself: "What should I do?"
let decision = llama_controller
    .query_node("hostbox", "qwen2.5:14b", &context)
    .await?;

// CoDriver executes the decision using the cluster
match decision.action {
    "generate_component" => cluster.route_to_l3(task),
    "find_leads" => lead_scraper.search_and_qualify(),
    "analyze_image" => cluster.route_to_l1(task),
    _ => // ... handle
}
```

---

## 🏗️ CODRIVER AS COORDINATOR

CoDriver **doesn't rebuild** what exists.
CoDriver **uses** the 20 crates Jesse already built.

### Architecture:

```
CoDriver (Coordinator)
    ↓
Uses existing crates as dependencies:
├── llama-controller     → Talk to Ollama cluster
├── chat-manager         → Monitor .ai/chats/*.txt
├── message-handler      → MessagePack for fast agent comm
├── prompt-manager       → Save/load best prompts
├── lead-scraper         → Find trucking leads
├── lead-analyzer        → Score leads (0-100)
├── lead-manager         → Store in .ai/leads/*.md
├── web-search           → Google/Bing search
├── web-scraper          → Extract data from pages
├── data-collector       → Aggregate data
├── database-manager     → SurrealDB + DuckDB
├── file-operation       → Read/write files
├── pdf-handler          → Process PDFs
├── vision-handler       → Route vision tasks to L1
├── code-assistant       → Route code tasks to L3
├── service-manager      → Manage services
├── api-gateway          → HTTP/gRPC endpoints
├── audit-manager        → Log all actions
└── screen-handler       → UI automation (future)
```

---

## 📦 CODRIVER CARGO.TOML

```toml
[package]
name = "codriver"
version = "0.1.0"
edition = "2021"

[dependencies]
tokio = { version = "1.35", features = ["full"] }
anyhow = "1.0"
thiserror = "1.0"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
tracing = "0.1"
tracing-subscriber = "0.3"

# Use existing crates (relative paths)
llama-controller = { path = "../../crates/llama-controller" }
chat-manager = { path = "../../crates/chat-manager" }
message-handler = { path = "../../crates/message-handler" }
prompt-manager = { path = "../../crates/prompt-manager" }
lead-scraper = { path = "../../crates/lead-scraper" }
lead-analyzer = { path = "../../crates/lead-analyzer" }
lead-manager = { path = "../../crates/lead-manager" }
web-search = { path = "../../crates/web-search" }
web-scraper = { path = "../../crates/web-scraper" }
data-collector = { path = "../../crates/data-collector" }
database-manager = { path = "../../crates/database-manager" }
file-operation = { path = "../../crates/file-operation" }
pdf-handler = { path = "../../crates/pdf-handler" }
vision-handler = { path = "../../crates/vision-handler" }
code-assistant = { path = "../../crates/code-assistant" }
service-manager = { path = "../../crates/service-manager" }
api-gateway = { path = "../../crates/api-gateway" }
audit-manager = { path = "../../crates/audit-manager" }
```

---

## 🔄 CODRIVER MAIN LOOP

```rust
#[tokio::main]
async fn main() -> Result<()> {
    // Initialize CoDriver
    let codriver = CoDriver::new().await?;

    println!("🤖 CoDriver v0.1 Online");
    println!("🧠 Brain: hostbox qwen2.5:14b");
    println!("📂 Monitoring: .ai/chats/codriver.txt");
    println!();

    loop {
        // 1. Check for user tasks in chat file
        if let Some(task) = codriver.chat_manager.check_new_messages().await? {
            codriver.handle_task(task).await?;
        }

        // 2. If idle, do autonomous work (lead generation)
        else if codriver.is_idle().await {
            codriver.autonomous_work().await?;
        }

        // 3. Sleep briefly (don't burn CPU)
        tokio::time::sleep(Duration::from_millis(500)).await;
    }
}
```

---

## 🎯 CODRIVER METHODS

### handle_task()

```rust
async fn handle_task(&self, task: ChatMessage) -> Result<()> {
    // Log to audit
    self.audit_manager.log("task_received", &task).await?;

    // Ask own brain: What should I do?
    let context = format!(
        "User task: {}\nAvailable actions: generate_component, find_leads, analyze_image, execute_code, search_web, process_pdf",
        task.content
    );

    let decision = self.llama_controller
        .query_node("hostbox", "qwen2.5:14b", &context)
        .await?;

    // Execute based on decision
    match decision.extract_action() {
        "generate_component" => self.generate_component(task).await?,
        "find_leads" => self.find_leads(task).await?,
        "analyze_image" => self.analyze_image(task).await?,
        "search_web" => self.search_web(task).await?,
        _ => self.respond("Unknown task type").await?,
    }

    Ok(())
}
```

### generate_component()

```rust
async fn generate_component(&self, task: ChatMessage) -> Result<()> {
    // Update chat
    self.chat_manager.append("codriver", "Generating component...").await?;

    // Build prompt using prompt-manager
    let prompt = self.prompt_manager.build_component_prompt(&task)?;

    // Route to L3 (code generation)
    let code = self.llama_controller
        .query_node("helpbox", "codestral:22b", &prompt)
        .await?;

    // Save to projects/complete
    self.file_operation
        .write(".ai/projects/complete/Component.tsx", &code)
        .await?;

    // Report completion
    self.chat_manager
        .append("codriver", "✅ Component ready: .ai/projects/complete/Component.tsx")
        .await?;

    Ok(())
}
```

### autonomous_work() - Lead Generation

```rust
async fn autonomous_work(&self) -> Result<()> {
    // Ask brain: Should I look for leads?
    let should_search = self.llama_controller
        .query_node("hostbox", "qwen2.5:14b",
            "Should I search for new leads right now? Consider: time of day, last search time, lead pipeline status")
        .await?;

    if !should_search.contains("yes") {
        return Ok(());
    }

    // Search for leads
    let queries = vec![
        "trucking company needs TMS software",
        "fleet management software implementation hiring",
        "dispatch software for trucking company"
    ];

    for query in queries {
        // Use web-search crate
        let results = self.web_search.search(query).await?;

        // Use web-scraper to extract details
        for result in results {
            let details = self.web_scraper.extract(&result.url).await?;

            // Use lead-analyzer to score (0-100)
            let score = self.lead_analyzer.score(&details).await?;

            if score >= 70 {
                // Use lead-manager to save
                self.lead_manager.save_qualified(&details, score).await?;

                // Log to chat
                self.chat_manager
                    .append("codriver", &format!("🎯 Found lead (score: {}): {}", score, details.company))
                    .await?;
            }
        }
    }

    Ok(())
}
```

---

## 🗄️ DATABASE: SURREALDB + DUCKDB

### Use database-manager crate

```rust
// SurrealDB for operational data
self.database_manager
    .surreal()
    .store_lead(&lead)
    .await?;

// DuckDB for analytics
self.database_manager
    .duckdb()
    .query("SELECT COUNT(*) FROM leads WHERE score > 80")
    .await?;
```

**NOT PostgreSQL** - Jesse clarified: SurrealDB + DuckDB only.

---

## 📡 COMMUNICATION LAYERS

### 1. User ↔ CoDriver (Text Files)

**File:** `.ai/chats/codriver.txt`

```
user: "create LoadCard component"
codriver: "Received. Generating..."
codriver: "✅ Complete: .ai/projects/complete/LoadCard.tsx"
```

**Implementation:** Use `chat-manager` crate

### 2. CoDriver ↔ Agents (MessagePack)

**Fast, binary, internal only**

```rust
// Send task to agent
self.message_handler
    .send_messagepack("cluster", &task)
    .await?;

// Receive response
let response = self.message_handler
    .receive_messagepack::<ClusterResponse>()
    .await?;
```

**User never sees this** - it's internal coordination

---

## 🔧 OLLAMA STATUS

### Current State:

```bash
# workbox (L1)
admin      1224  ollama serve  # Running

# hostbox (L2)
admin      1158  ollama serve  # Running (CoDriver's brain)
```

**Not systemd services** - running as standalone processes.

**Action:** Can create systemd services later if needed, but not required for v0.1.

---

## 📋 BUILD PHASES

### Phase 1: Basic Chat (TODAY)

**Goal:** CoDriver responds to chat

```bash
echo 'user: "ping"' >> .ai/chats/codriver.txt
# CoDriver: "pong" (using hostbox brain)
```

**Files:**
```
src/main.rs         - Main loop
src/lib.rs          - CoDriver struct
Cargo.toml          - All crate dependencies
```

**Implementation:**
- Use `chat-manager` to monitor file
- Use `llama-controller` to query hostbox
- Use `chat-manager` to respond

### Phase 2: Cluster Routing (DAY 2)

**Goal:** Route tasks to correct nodes

```bash
echo 'user: "create button component"' >> .ai/chats/codriver.txt
# CoDriver routes to L3, generates code
```

**Implementation:**
- Use `code-assistant` crate for routing
- Use `llama-controller` to execute on L3
- Use `file-operation` to save output

### Phase 3: Lead Generation (DAY 3)

**Goal:** Find leads when idle

**Implementation:**
- Use `lead-scraper` for web scraping
- Use `lead-analyzer` for scoring
- Use `lead-manager` for storage
- Use `database-manager` for SurrealDB storage

---

## ✅ SUCCESS CRITERIA

### CoDriver v0.1 Complete:

1. ✅ Reads `.ai/chats/codriver.txt`
2. ✅ Uses hostbox qwen2.5:14b as brain (NO cloud)
3. ✅ Responds to simple commands
4. ✅ Routes code tasks to L3
5. ✅ Saves output to `.ai/projects/complete/`
6. ✅ Runs continuously
7. ✅ Uses ALL 20 existing crates

### Jesse can then:

```bash
echo 'user: "find me 10 qualified trucking leads"' >> .ai/chats/codriver.txt

# CoDriver autonomously:
# 1. Searches web (web-search)
# 2. Scrapes sites (web-scraper)
# 3. Scores leads (lead-analyzer)
# 4. Stores in SurrealDB (database-manager)
# 5. Saves to .ai/leads/qualified/*.md (lead-manager)
# 6. Reports: "Found 10 leads. Ready for review."
```

---

## 🚨 CRITICAL REMINDERS

### What CoDriver IS:

- ✅ Coordinator using existing crates
- ✅ Brain = hostbox Ollama (offline)
- ✅ Uses MessagePack for speed
- ✅ Uses SurrealDB + DuckDB
- ✅ 100% autonomous

### What CoDriver IS NOT:

- ❌ Rebuilding infrastructure from scratch
- ❌ Using cloud APIs
- ❌ Using PostgreSQL
- ❌ Dependent on Claude/Gemini

### Jesse's Goal:

> "I just want to talk to codriver after to make sure he is doing what I want"

**Translation:** Ship CoDriver v0.1 TODAY so Jesse can test it.

---

## 🚀 NEXT: BUILD IT

**Immediate action:**

1. Update `Cargo.toml` with all crate dependencies
2. Build minimal `main.rs` using crates
3. Test with hostbox brain
4. Ship v0.1

**Timeline:** 2-3 hours (not days)

---

**Built By:** Claude (Anthropic AI)
**For:** Jesse E.E.W. Conley
**Mission:** Ship CoDriver TODAY so Jesse can start using it

🚛💪
