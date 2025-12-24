# Teaching CoDriver - Quick Reference Card

## ✅ YES, You Can Teach CoDriver!

CoDriver learns from **explicit instructions** in the chat file.

## Quick Commands

### Teach a New Tool
```bash
echo 'user: "When <scenario>, run <tool_path>"' >> ~/freightdev/openhwy/.ai/chats/codriver.txt
```

### Give Immediate Feedback
```bash
# When wrong
echo 'user: "STOP. Wrong choice. Use <correct_capability> instead."' >> ~/freightdev/openhwy/.ai/chats/codriver.txt

# When correct
echo 'user: "✅ CORRECT! Keep doing this."' >> ~/freightdev/openhwy/.ai/chats/codriver.txt
```

### Watch CoDriver Learn
```bash
tail -f ~/freightdev/openhwy/.ai/chats/codriver.txt
```

## Teaching Template

```bash
cat >> ~/freightdev/openhwy/.ai/chats/codriver.txt << 'EOF'
user: "LESSON: <Topic Name>

WHEN: <User says this>
DO: <Use this capability>
TOOL: <Full path to tool>
OPTIONS: <Important flags>

EXAMPLE:
User: '<example request>'
You: <capability> → <exact command>

WRONG: <what NOT to do>
RIGHT: <what TO do>"
EOF
```

## What CoDriver Can Learn

✅ Tool locations and usage
✅ When to use which capability
✅ Error recovery strategies
✅ Your workflow preferences
✅ Code patterns (via DuckDB indexing)

❌ Long-term memory (resets on restart)
❌ Implicit context (needs explicit teaching)

## The 5 Capabilities

| Capability | When to Use | Example |
|-----------|-------------|---------|
| `generate_component` | Build/edit UI code | "Create React component" |
| `execute_command` | Run tools/commands | "Clean whitespace" |
| `search_codebase` | Find code patterns | "Find error handlers" |
| `index_codebase` | Index files to DuckDB | "Index the project" |
| `respond_only` | Just answer | "What is X?" |

## Real Example: Teaching Whitespace Cleanup

```bash
# Step 1: Teach the tool
echo 'user: "LESSON: Whitespace Cleanup

WHEN: User says clean whitespace, fix formatting
TOOL: /home/admin/freightdev/openhwy/.ai/tools/devtools/whitespace-cleaner.sh
CAPABILITY: execute_command

STEPS:
1. Use --dry-run first to preview
2. Run without --dry-run to apply
3. Report what changed

EXAMPLE:
User: clean src/main.rs
You: execute_command → /home/admin/freightdev/openhwy/.ai/tools/devtools/whitespace-cleaner.sh src/main.rs --dry-run
(review output)
You: execute_command → /home/admin/freightdev/openhwy/.ai/tools/devtools/whitespace-cleaner.sh src/main.rs"' >> ~/freightdev/openhwy/.ai/chats/codriver.txt

# Step 2: Test it
echo 'user: "Clean up the whitespace in main.rs"' >> ~/freightdev/openhwy/.ai/chats/codriver.txt

# Step 3: Watch CoDriver
tail -f ~/freightdev/openhwy/.ai/chats/codriver.txt

# Step 4: Give feedback
# If correct:
echo 'user: "✅ Perfect! You used the whitespace-cleaner tool correctly."' >> ~/freightdev/openhwy/.ai/chats/codriver.txt
# If wrong:
echo 'user: "STOP. You should use execute_command with whitespace-cleaner.sh, not generate_component."' >> ~/freightdev/openhwy/.ai/chats/codriver.txt
```

## Pro Tips

### 1. Be Specific
❌ "Use the tool"
✅ "Use execute_command with /full/path/to/tool.sh"

### 2. Show Examples
```
EXAMPLE:
User: "clean main.rs"
You: execute_command → ./whitespace-cleaner.sh main.rs
```

### 3. Explain Why
```
REASON: This is file cleanup, not code generation
THEREFORE: Use execute_command, not generate_component
```

### 4. Test and Iterate
```
1. Teach → 2. Test → 3. Observe → 4. Correct → 5. Reinforce
```

### 5. Create Documentation
Write README files in tool directories - CoDriver reads them!

## Monitoring CoDriver

### See What CoDriver Is Thinking
```bash
# Real-time monitoring
tail -f ~/freightdev/openhwy/.ai/chats/codriver.txt

# Recent decisions
tail -20 ~/freightdev/openhwy/.ai/chats/codriver.txt | grep "Decision:"
```

### Check If CoDriver Is Running
```bash
ps aux | grep codriver
```

### View Full Output
```bash
# Find the CoDriver instance
ps aux | grep "target/release/codriver"

# Check logs in the session
# (output is captured in your terminal or background bash)
```

## Common Teaching Scenarios

### Teach Tool Usage
```bash
echo 'user: "When <task>, use /path/to/tool.sh with execute_command"' >> ~/freightdev/openhwy/.ai/chats/codriver.txt
```

### Teach Workflow Pattern
```bash
echo 'user: "WORKFLOW: Before pushing code:
1. Clean whitespace
2. Run tests
3. Commit with git-helper
4. Push"' >> ~/freightdev/openhwy/.ai/chats/codriver.txt
```

### Teach Error Recovery
```bash
echo 'user: "When helpbox connection fails:
1. Run check-ollama.sh to diagnose
2. Wait 15 seconds if BUSY
3. Retry the generation"' >> ~/freightdev/openhwy/.ai/chats/codriver.txt
```

### Teach Preferences
```bash
echo 'user: "PREFERENCE: Always use Tailwind CSS, never Material-UI
PREFERENCE: Always run --dry-run before destructive operations
PREFERENCE: Create detailed commit messages"' >> ~/freightdev/openhwy/.ai/chats/codriver.txt
```

## Devtools Quick Reference

**Most Useful Tools** (all in `/home/admin/freightdev/openhwy/.ai/tools/devtools/`):

1. **whitespace-cleaner.sh** - Fix code formatting
2. **ollama-cluster.py** - Manage LLM cluster
3. **git-helper.sh** - Automate git workflows
4. **api-extractor.sh** - Extract C/C++ APIs
5. **check-ollama.sh** - Check cluster status

**Full catalog**: `~/freightdev/openhwy/.ai/tools/devtools/DEVTOOLS-CATALOG.md`

## Learning Resources

- **Full Learning Guide**: `~/freightdev/openhwy/.ai/HOW-CODRIVER-LEARNS.md`
- **Devtools Catalog**: `~/freightdev/openhwy/.ai/tools/devtools/DEVTOOLS-CATALOG.md`
- **This Quick Ref**: `~/freightdev/openhwy/.ai/TEACH-CODRIVER-QUICK-REF.md`

## Summary

**CoDriver learns from you through explicit teaching.**

- Write lessons in `codriver.txt`
- Give immediate feedback
- Show concrete examples
- Reinforce correct behavior

**Start teaching now!** 🚛💪
