# CoDriver Context Preservation & Iterative Editing

**Date:** 2025-11-20
**Status:** ✅ IMPLEMENTED
**Feature:** Helpbox context preservation with 5-minute timeout

---

## 🎯 What This Solves

Jesse's Request:
> "Can CoDriver edit the same file? Can it use the helpbox models context? Ollama should have context but has a timeout like 5 mins then it saves what it did in a log before it shuts down like a prompt to pull its context out."

**Solution:**
1. ✅ CoDriver can now **edit existing files** (not just create new ones)
2. ✅ Maintains **conversation context** with helpbox across multiple requests
3. ✅ **Saves context to JSON log** (`~/.ai/logs/helpbox_context.json`)
4. ✅ **5-minute timeout** - saves and clears context after idle
5. ✅ **Context restoration** - loads saved context on startup

---

## How It Works

### Context Tracking

CoDriver maintains a conversation history with helpbox:

```rust
struct HelpboxContext {
    messages: VecDeque<ContextMessage>,  // Last 20 messages
    last_file: Option<String>,            // File being worked on
    last_activity: String,                // Timestamp
}
```

**Saved to:** `~/.ai/logs/helpbox_context.json`

### Example Context File

```json
{
  "messages": [
    {
      "role": "user",
      "content": "create a LoadCard component with drag handle",
      "timestamp": "2025-11-20T01:38:47Z"
    },
    {
      "role": "assistant",
      "content": "import React from 'react'...",
      "timestamp": "2025-11-20T01:39:15Z"
    },
    {
      "role": "user",
      "content": "add a loading state",
      "timestamp": "2025-11-20T01:40:22Z"
    }
  ],
  "last_file": "/home/admin/freightdev/openhwy/.ai/projects/complete/LoadCard.tsx",
  "last_activity": "2025-11-20T01:40:22Z"
}
```

---

## Iterative Editing Workflow

### Step 1: Create Component

```bash
echo 'user: "create a LoadCard component"' >> ~/.ai/chats/codriver.txt
```

**CoDriver Actions:**
1. Detects no existing file
2. Generates new LoadCard.tsx
3. Saves file to `.ai/projects/complete/LoadCard.tsx`
4. **Adds to context:** task + generated code
5. **Remembers file:** `last_file = "LoadCard.tsx"`
6. **Saves context to JSON**

### Step 2: Edit Component (Within 5 Minutes)

```bash
echo 'user: "add a loading state to LoadCard"' >> ~/.ai/chats/codriver.txt
```

**CoDriver Actions:**
1. Detects "LoadCard" in task
2. **Finds existing file:** `.ai/projects/complete/LoadCard.tsx`
3. **Loads file content into context**
4. Sends to helpbox with context:
   ```
   Previous conversation:
   user: create a LoadCard component
   assistant: [previous code]

   Current file content:
   [existing LoadCard.tsx]

   New task: add a loading state
   ```
5. Helpbox generates **updated** code (not from scratch!)
6. **Overwrites file** with new version
7. **Updates context** with new task + new code
8. **Saves context**

### Step 3: Continue Editing

```bash
echo 'user: "add error handling"' >> ~/.ai/chats/codriver.txt
```

**Same process** - helpbox has full context of all previous changes!

---

## Context Timeout (5 Minutes)

### What Happens When Idle

```rust
const CONTEXT_TIMEOUT_SECS: u64 = 300; // 5 minutes

fn clear_helpbox_context_if_timeout(&mut self) {
    if last_activity.elapsed() > 5 minutes {
        println!("⏰ Helpbox context timed out, saving and clearing...");
        save_helpbox_context();   // Save to JSON
        messages.clear();          // Clear memory
        last_file = None;          // Reset file tracking
    }
}
```

**Timeline:**
- **0:00** - User creates LoadCard.tsx
- **0:30** - User edits LoadCard (adds loading state)
- **1:00** - User edits LoadCard (adds error handling)
- **5:00** - No activity for 5 minutes
- **5:01** - CoDriver saves context and clears memory
- **10:00** - User creates new component (fresh context)

**Why 5 minutes?**
- Ollama typically keeps model context for ~5 minutes of inactivity
- After that, the model unloads from memory anyway
- CoDriver matches this behavior

---

## Context Restoration on Restart

### When CoDriver Starts

```rust
fn new() -> Self {
    // Try to load existing context
    let helpbox_context = load_helpbox_context()
        .unwrap_or_else(|_| HelpboxContext::new());

    println!("💾 Context: {} messages loaded", context.messages.len());

    Self { helpbox_context, ... }
}
```

**If context file exists:**
- Loads previous conversation
- Restores `last_file` tracking
- Continues where it left off

**If no context file:**
- Starts fresh with empty context

---

## Automatic File Detection

CoDriver intelligently decides **edit vs create**:

### Triggers for Editing Mode

1. **Task contains edit keywords:**
   - "edit"
   - "update"
   - "add to"
   - "modify"

2. **File already exists:**
   - CoDriver checks if `LoadCard.tsx` exists
   - If yes → edit mode
   - If no → create mode

3. **Same component name:**
   - User says: "add a loading state to LoadCard"
   - CoDriver extracts "LoadCard" from task
   - Finds existing `LoadCard.tsx`
   - Enters edit mode

### Code Logic

```rust
async fn generate_component(&mut self, task: &str) {
    let is_edit = task.contains("edit")
        || task.contains("update")
        || task.contains("add to");

    let filepath = if is_edit && self.helpbox_context.last_file.is_some() {
        // Use last file
        self.helpbox_context.last_file.clone().unwrap()
    } else {
        // Determine new filename
        self.extract_filename(task)
    };

    if Path::new(&filepath).exists() {
        // EDIT MODE
        let existing_content = fs::read_to_string(&filepath)?;
        self.add_to_helpbox_context("assistant", &existing_content);
        println!("📝 Editing existing file: {}", filepath);
    } else {
        // CREATE MODE
        println!("🔧 Generating new component...");
    }
}
```

---

## Context-Aware Prompting

### Without Context (First Request)

```
You are a senior React/TypeScript developer. Generate ONLY the code, no explanations.

Task: create a LoadCard component with drag handle

Requirements:
- Use TypeScript and React
- Use Tailwind CSS for styling
- Include proper types
- Use modern React patterns
- Make it production-ready

Generate the complete component code:
```

### With Context (Follow-up Request)

```
Previous conversation context:
user: create a LoadCard component with drag handle
assistant: import React from 'react';
import { useDrag } from 'react-dnd';

interface LoadCardProps {
  id: string;
  title: string;
}

const LoadCard: React.FC<LoadCardProps> = ({ id, title }) => {
  const [{ isDragging }, drag] = useDrag({
    item: { type: 'LOAD_CARD', id },
    collect: (monitor) => ({
      isDragging: !!monitor.isDragging(),
    }),
  });

  return (
    <div ref={drag} className={`p-4 border rounded shadow ${isDragging ? 'opacity-50' : ''}`}>
      {title}
    </div>
  );
};

export default LoadCard;

New task: add a loading state

You are a senior React/TypeScript developer. Generate ONLY the code, no explanations.

Requirements:
- Use TypeScript and React
- Use Tailwind CSS for styling
- Include proper types
- Use modern React patterns
- Make it production-ready

Generate the complete component code:
```

**Result:** helpbox knows the existing structure and adds loading state properly!

---

## Benefits

### 1. Iterative Development
- Build components incrementally
- "Add feature X" → "Now add feature Y" → "Now add feature Z"
- Each step builds on the previous

### 2. Context Awareness
- Helpbox remembers what it built
- No need to repeat requirements
- Maintains consistent coding style

### 3. Automatic Saving
- Context saved after every change
- Can restart CoDriver without losing progress
- JSON log provides audit trail

### 4. Memory Efficiency
- Only keeps last 20 messages
- Clears context after 5 min idle
- Prevents memory bloat

### 5. File Tracking
- Knows which file it's working on
- Can continue editing same file
- Supports "add to the last file" requests

---

## Usage Examples

### Example 1: Build Component Iteratively

```bash
# Step 1: Create base component
echo 'user: "create a UserProfile component"' >> ~/.ai/chats/codriver.txt
# → Creates UserProfile.tsx with basic structure

# Step 2: Add features (within 5 min)
echo 'user: "add an avatar image to UserProfile"' >> ~/.ai/chats/codriver.txt
# → Edits UserProfile.tsx, adds avatar

# Step 3: More features
echo 'user: "add a bio section"' >> ~/.ai/chats/codriver.txt
# → Edits UserProfile.tsx again, adds bio

# Step 4: Polish
echo 'user: "add loading and error states"' >> ~/.ai/chats/codriver.txt
# → Final edit with loading/error handling
```

**All in one file, all contextually aware!**

### Example 2: Edit Existing File Explicitly

```bash
echo 'user: "edit LoadCard to add a badge showing load status"' >> ~/.ai/chats/codriver.txt
# CoDriver detects "edit", loads LoadCard.tsx, adds badge
```

### Example 3: Continue After Timeout

```bash
# 10 minutes ago: created LoadCard
# Context timed out and was saved

# Now: restart CoDriver
cd ~/freightdev/openhwy/.ai/agents/codriver-v0
./target/release/codriver

# Output shows:
# 💾 Context: 4 messages loaded

# Continue working:
echo 'user: "add animation to LoadCard"' >> ~/.ai/chats/codriver.txt
# CoDriver loads context from JSON, continues editing
```

---

## Context Storage

### Location
```
~/.ai/logs/helpbox_context.json
```

### Format
```json
{
  "messages": [
    {"role": "user", "content": "...", "timestamp": "..."},
    {"role": "assistant", "content": "...", "timestamp": "..."}
  ],
  "last_file": "/path/to/last/file.tsx",
  "last_activity": "2025-11-20T01:40:22Z"
}
```

### Max Size
- **20 messages** maximum (keeps memory usage low)
- Oldest messages removed when limit reached
- Context saved after every change

---

## Constants

```rust
const CONTEXT_TIMEOUT_SECS: u64 = 300;        // 5 minutes
const MAX_CONTEXT_MESSAGES: usize = 20;       // Keep last 20 messages
const HELPBOX_CONTEXT_FILE: &str = ".ai/logs/helpbox_context.json";
```

---

## What's Different from v0.1

### v0.1 (Basic Code Generation)
- ❌ Always creates new files
- ❌ No context between requests
- ❌ Can't edit existing components
- ❌ Helpbox forgets previous work

### v0.2 (Context Preservation)
- ✅ Detects and edits existing files
- ✅ Maintains conversation context
- ✅ Remembers what it built
- ✅ Saves context to JSON
- ✅ 5-minute timeout with auto-save
- ✅ Context restoration on restart

---

## Implementation Details

### Key Files Changed
- `src/main.rs` - Added context management
- `Cargo.toml` - Added chrono and serde dependencies

### New Structs
```rust
struct ContextMessage {
    role: String,
    content: String,
    timestamp: String,
}

struct HelpboxContext {
    messages: VecDeque<ContextMessage>,
    last_file: Option<String>,
    last_activity: String,
}

struct CoDriver {
    helpbox_context: HelpboxContext,
    last_helpbox_activity: Instant,
    // ...
}
```

### New Methods
- `load_helpbox_context()` - Load from JSON
- `save_helpbox_context()` - Save to JSON
- `add_to_helpbox_context()` - Add message
- `clear_helpbox_context_if_timeout()` - Timeout handling
- `build_helpbox_prompt_with_context()` - Context-aware prompts
- `extract_filename()` - Extract component name from task

---

## Future Enhancements

### Possible Improvements

1. **Multi-File Context**
   - Track context for multiple files simultaneously
   - "Switch to UserProfile component" → loads different context

2. **Context Search**
   - "What did I build yesterday?"
   - Search through saved context logs

3. **Context Summarization**
   - After 20 messages, summarize older context
   - Keep more history without memory bloat

4. **Smart File Detection**
   - Better filename extraction from natural language
   - "Add loading to the profile page" → finds UserProfile.tsx

5. **Diff Tracking**
   - Show what changed between edits
   - "Undo last change"

---

## Status

**Current Version:** CoDriver v0.2
**Context Preservation:** ✅ Working
**File Editing:** ✅ Working
**Timeout Handling:** ✅ Working
**Context Saving:** ✅ Working
**Context Restoration:** ✅ Working

**Ready for:** Iterative component development with full context awareness!

---

**Built By:** Claude (Anthropic AI)
**For:** Jesse E.E.W. Conley
**Mission:** Enable iterative, context-aware autonomous code generation

🚛💪 Ship fast, iterate faster.
