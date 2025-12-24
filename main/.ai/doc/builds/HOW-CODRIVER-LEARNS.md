# How CoDriver Learns

## YES, You Can Teach CoDriver! 🎓

CoDriver has multiple learning mechanisms. Here's how it works:

## Learning Mechanisms

### 1. **Explicit Teaching (Conversation File)**
**Location**: `/home/admin/freightdev/openhwy/.ai/chats/codriver.txt`

**How it works**:
- You write messages in codriver.txt
- CoDriver reads and processes them
- CoDriver learns from explicit instructions

**Example**:
```
user: "When the user asks to fix Material-UI code to Tailwind CSS:
1. Choose generate_component (NOT execute_command)
2. Load the existing file
3. Regenerate with Tailwind CSS classes
This is a CODE EDITING task, use generate_component."

codriver: *Learns and applies this pattern next time*
```

**What CoDriver Remembers**:
- ✅ Patterns you teach (when to use which capability)
- ✅ Tool locations and usage
- ✅ Error recovery strategies
- ✅ Your preferences and requirements

**Limitations**:
- ❌ Each CoDriver instance starts fresh (no long-term memory across restarts)
- ❌ Context is limited to recent messages (4-message context window)

### 2. **Context Preservation (JSON Logging)**
**Location**: `/home/admin/freightdev/openhwy/.ai/agents/codriver-v0/helpbox_context.json`

**How it works**:
- CoDriver saves LLM conversation context to JSON
- When editing files iteratively, it loads previous context
- 5-minute timeout - context clears if idle too long

**What It Remembers**:
- Recent file edits
- Current generation task
- Last LLM conversation

**Use case**: Multi-step code generation (edit same file multiple times)

### 3. **DuckDB Code Indexing**
**Location**: `/home/admin/freightdev/openhwy/.ai/agents/codriver-v0/code_index.duckdb`

**How it works**:
- CoDriver indexes code files into DuckDB
- Uses natural language SQL queries to search code
- Powered by duckdb-nsql:7b model on workbox

**What It Indexes**:
- All .rs files (Rust)
- All .py files (Python)
- All .sh/.zsh files (Shell scripts)
- File paths, content, extensions, sizes

**Example Queries**:
```
User: "Find all functions that handle errors"
CoDriver: Queries DuckDB → Finds error handling code

User: "Which files import reqwest?"
CoDriver: Queries DuckDB → Lists files with reqwest imports
```

**When CoDriver Uses It**:
- When you trigger `index_codebase` capability
- When you ask about code structure
- When searching for specific code patterns

### 4. **Brain Decision-Making (qwen2.5:14b)**
**Location**: Hostbox L2 node

**How it works**:
- Every user message goes to the "brain" (qwen2.5:14b)
- Brain analyzes intent and chooses capability
- Brain learns patterns from conversation history

**Capabilities Brain Can Choose**:
- `generate_component` - Build or edit code
- `execute_command` - Run bash commands
- `search_codebase` - Search indexed code
- `index_codebase` - Index new code
- `respond_only` - Just respond, no action

**Teaching the Brain**:
```
user: "LESSON: When converting UI frameworks, use generate_component.
When running tools, use execute_command.
When finding code, use search_codebase."

Brain: *Incorporates this into decision-making*
```

## How to Teach CoDriver

### Method 1: Direct Instructions
Write clear commands in `codriver.txt`:

```bash
echo 'user: "When user asks to clean whitespace, run /home/admin/freightdev/openhwy/.ai/tools/devtools/whitespace-cleaner.sh"' >> /home/admin/freightdev/openhwy/.ai/chats/codriver.txt
```

### Method 2: Explicit Lessons
Provide structured teaching with examples:

```
user: "LESSON: Git Workflow

WHEN: User says 'commit these changes'
DO: Use git-helper.sh from devtools

STEPS:
1. Check what changed: git status
2. Run: /home/admin/freightdev/openhwy/.ai/tools/devtools/git-helper.sh -T . --mode add
3. Report what was committed

WRONG APPROACH: Trying to use git commands directly
RIGHT APPROACH: Use the git-helper.sh tool"
```

### Method 3: Feedback Loop
Correct mistakes immediately:

```
user: "STOP. You chose execute_command but should use generate_component.
REASON: This is code editing, not running a command.
TRY AGAIN with the correct capability."
```

### Method 4: Tool Documentation
Create catalog files (like DEVTOOLS-CATALOG.md):

```markdown
# Tool: whitespace-cleaner.sh
**When to use**: Code cleanup before commits
**Usage**: ./whitespace-cleaner.sh <file>
**Options**: --dry-run, --verbose
```

CoDriver reads these and learns tool purposes.

## What CoDriver CAN Learn

✅ **Tool Locations**: Where tools are, how to run them
✅ **Decision Patterns**: Which capability for which task
✅ **Error Recovery**: How to troubleshoot failures
✅ **User Preferences**: Your coding style, requirements
✅ **Code Structure**: Through DuckDB indexing
✅ **Workflow Patterns**: Git, testing, deployment flows

## What CoDriver CANNOT Learn (Yet)

❌ **Long-term Memory**: Doesn't remember across restarts
❌ **Complex Reasoning**: Brain is 14B params, not GPT-4 level
❌ **Implicit Context**: Needs explicit teaching
❌ **Multi-file Coordination**: Struggles with complex refactors
❌ **Deep Code Understanding**: Surface-level indexing only

## Teaching Best Practices

### 1. Be Explicit
❌ "Fix the component"
✅ "Use generate_component to convert this Material-UI component to Tailwind CSS"

### 2. Provide Context
❌ "This is wrong"
✅ "You chose execute_command but this is code editing, use generate_component instead"

### 3. Give Examples
```
user: "EXAMPLE: When user says 'check ollama cluster'
→ You run: /home/admin/freightdev/openhwy/.ai/tools/check-ollama.sh
→ You report which nodes are online/offline"
```

### 4. Reinforce Success
```
user: "✅ CORRECT! You chose execute_command for running a tool.
This is the right pattern. Keep doing this."
```

### 5. Create Documentation
Write README files for your tools - CoDriver reads them!

## CoDriver's Learning Cycle

1. **Read** user message from codriver.txt
2. **Think** using brain (qwen2.5:14b) to choose capability
3. **Act** by executing the chosen capability
4. **Learn** from user feedback in next message
5. **Repeat** with improved decision-making

## Monitoring CoDriver's Learning

**Check what CoDriver is doing**:
```bash
tail -f /home/admin/freightdev/openhwy/.ai/chats/codriver.txt
```

**See CoDriver's decisions**:
```bash
# CoDriver's stdout shows:
📥 User task: <what you asked>
🧠 Autonomous decision: <capability chosen>
🔧 Executing: <command being run>
✓ Complete
```

**Check indexed knowledge**:
```bash
sqlite3 /home/admin/freightdev/openhwy/.ai/agents/codriver-v0/code_index.duckdb "SELECT COUNT(*) FROM files"
```

## Example Teaching Session

```
# 1. Teach tool usage
echo 'user: "When cleaning code, use whitespace-cleaner.sh from devtools"' >> codriver.txt

# 2. Give example
echo 'user: "Example: clean main.rs → /home/admin/freightdev/openhwy/.ai/tools/devtools/whitespace-cleaner.sh main.rs"' >> codriver.txt

# 3. Test it
echo 'user: "Clean up the whitespace in src/main.rs"' >> codriver.txt

# 4. Monitor CoDriver
tail -f codriver.txt

# 5. Provide feedback
echo 'user: "✅ Good! You used the right tool."' >> codriver.txt
```

## Advanced: Modifying CoDriver's Brain

You can edit CoDriver's source code to change decision-making:

**File**: `/home/admin/freightdev/openhwy/.ai/agents/codriver-v0/src/main.rs`

**Brain prompt is here**:
```rust
let decision_prompt = format!(
    "You are an autonomous development assistant. Choose the best capability:
    - generate_component: Build/edit code
    - execute_command: Run commands
    - search_codebase: Find code
    - index_codebase: Index files
    - respond_only: Just respond

    User request: {}

    Choose one capability:",
    user_message
);
```

**To add new patterns**: Edit this prompt, rebuild CoDriver:
```bash
cd /home/admin/freightdev/openhwy/.ai/agents/codriver-v0
cargo build --release
```

## Summary

**YES, you can teach CoDriver!**

- ✅ Write lessons in codriver.txt
- ✅ Provide immediate feedback
- ✅ Create tool documentation
- ✅ Give concrete examples
- ✅ Reinforce correct behavior

**CoDriver learns**:
- Patterns (when to use which tool)
- Tool locations and usage
- Error recovery strategies
- Your preferences

**But remember**:
- Teaching is per-session (resets on restart)
- Be explicit and specific
- Provide examples
- Give feedback

**Start teaching now** - CoDriver is waiting! 🚛💪
