# How to Work With CoDriver on the Lead Agency v2 Project

## 📋 The Setup

CoDriver has been given the task to complete the Lead Agency v2 frontend and integrate it with the backend you built.

**CoDriver's Instructions:**
- ✅ ASK questions before building
- ✅ CONSULT other Ollama models for advice
- ✅ TEST after each build step
- ✅ WAIT for your feedback before continuing
- ❌ DO NOT just start building without asking

---

## 🔄 How to Communicate with CoDriver

### Watch CoDriver in Real-Time
```bash
tail -f ~/freightdev/openhwy/.ai/chats/codriver.txt
```

This shows you:
- CoDriver's questions
- CoDriver's decisions
- CoDriver's command outputs

### Send Messages to CoDriver
```bash
# Method 1: Quick message
echo 'user: "Your message here"' >> ~/freightdev/openhwy/.ai/chats/codriver.txt

# Method 2: Multi-line message
cat >> ~/freightdev/openhwy/.ai/chats/codriver.txt << 'EOF'
user: "Your longer message
can span multiple lines
like this"
EOF
```

---

## 🎯 Expected Workflow

### Step 1: CoDriver Asks Questions

CoDriver should ask you things like:
- What framework to use?
- Where to save the code?
- What features to build first?
- Should it consult other models?

### Step 2: You Answer

Example response:
```bash
cat >> ~/freightdev/openhwy/.ai/chats/codriver.txt << 'EOF'
user: "Great questions! Here are my answers:

1. Framework: Use React with Vite (fast, modern)
2. Location: Save to ~/freightdev/openhwy/.ai/lead-agency-v2/frontend/
3. Features: Build in this order:
   - Lead list view FIRST
   - Then filters
   - Then lead detail view
4. YES - consult HOSTBOX about React architecture

Build the lead list view first, then TEST it and wait for my feedback."
EOF
```

### Step 3: CoDriver May Consult Other Models

When CoDriver needs advice, it will call other Ollama models:

**HOSTBOX** (reasoning - qwen2.5:14b):
```bash
curl http://192.168.12.106:11434/api/generate -d '{
  "model":"qwen2.5:14b",
  "prompt":"How should I structure a React app with lead list, filters, and detail views?"
}'
```

**WORKBOX** (SQL/vision - llava-phi3:3.8b):
```bash
curl http://192.168.12.136:11434/api/generate -d '{
  "model":"llava-phi3:3.8b",
  "prompt":"What SQL query should I use to filter leads by score?"
}'
```

**CALLBOX** (quick answers - phi4-mini:3.8b):
```bash
curl http://192.168.12.9:11434/api/generate -d '{
  "model":"phi4-mini:3.8b",
  "prompt":"Should I use useState or useReducer for filters?"
}'
```

### Step 4: CoDriver Builds ONE Component

CoDriver will use `generate_component` to build code.

### Step 5: CoDriver Tests

CoDriver will:
- Check if backend is running
- Test the API connection
- Verify the component works

### Step 6: CoDriver Reports Back

CoDriver will tell you what it built and ask for feedback.

### Step 7: You Give Feedback

```bash
# If good:
echo 'user: "✅ Looks good! Move to the next step: build the filters component."' >> ~/freightdev/openhwy/.ai/chats/codriver.txt

# If needs changes:
echo 'user: "❌ Issue: The API endpoint is wrong. Use /api/leads not /leads. Fix and test again."' >> ~/freightdev/openhwy/.ai/chats/codriver.txt
```

---

## 🛠️ Monitoring CoDriver's Work

### Check What CoDriver Built

```bash
# List generated components
ls -la ~/freightdev/openhwy/.ai/projects/complete/

# View a component
cat ~/freightdev/openhwy/.ai/projects/complete/Component.tsx
```

### Check Backend Status

```bash
# Is backend running?
curl http://localhost:8000

# Check API endpoints
curl http://localhost:8000/api/leads
curl http://localhost:8000/api/stats
```

### Start Backend if Needed

```bash
cd ~/freightdev/openhwy/.ai/lead-agency-v2
docker compose up -d
docker compose logs -f api
```

---

## 💬 Example Conversation Flow

### Round 1: Questions

**CoDriver**:
```
"I read the backend docs. Questions:
1. What frontend framework? (React/Next.js/Vite?)
2. Where to save code?
3. Build full app or just components?
4. What's most important first?
5. Consult other models for architecture advice?"
```

**You respond**:
```bash
echo 'user: "Use React with Vite. Save to ~/freightdev/openhwy/.ai/lead-agency-v2/frontend/. Build full app. Most important: lead list view. YES consult HOSTBOX about architecture."' >> ~/freightdev/openhwy/.ai/chats/codriver.txt
```

### Round 2: Consulting Other Models

**CoDriver**:
```
"Consulting HOSTBOX about React architecture..."
(runs curl to HOSTBOX)
"HOSTBOX suggests: Use React Query for data fetching, separate components for list/detail/filters. Should I proceed?"
```

**You respond**:
```bash
echo 'user: "✅ Yes, proceed with React Query. Build the lead list component first."' >> ~/freightdev/openhwy/.ai/chats/codriver.txt
```

### Round 3: Building

**CoDriver**:
```
"Building LeadList component with React Query..."
(generates code)
"✅ Built: ~/freightdev/openhwy/.ai/lead-agency-v2/frontend/src/components/LeadList.tsx
Testing API connection..."
```

### Round 4: Testing

**CoDriver**:
```
"Test results:
✅ Backend is running
✅ API responds at /api/leads
❌ Getting CORS error

Should I add CORS configuration to the backend?"
```

**You respond**:
```bash
echo 'user: "Yes, add CORS. Use execute_command to edit the backend main.py and add FastAPI CORS middleware."' >> ~/freightdev/openhwy/.ai/chats/codriver.txt
```

### Round 5: Fixing and Re-testing

**CoDriver**:
```
"Added CORS middleware to backend/app/main.py
Restarted backend
Testing again...
✅ All tests pass!
Lead list displays 10 sample leads.

Ready for next step. What should I build next?"
```

**You respond**:
```bash
echo 'user: "Perfect! Next: build the filter component for min_score and status filters."' >> ~/freightdev/openhwy/.ai/chats/codriver.txt
```

---

## 🎨 Teaching CoDriver During the Process

If CoDriver makes a mistake, teach it:

```bash
cat >> ~/freightdev/openhwy/.ai/chats/codriver.txt << 'EOF'
user: "LESSON: API Testing

WRONG: Assuming API works without testing
RIGHT:
1. Check if backend is running first
2. Test API with curl
3. Verify response format
4. Then build the frontend component

Always test APIs before building UI!"
EOF
```

---

## 🚦 Testing the Backend

### Quick Backend Tests

```bash
# Health check
curl http://localhost:8000

# Get leads
curl http://localhost:8000/api/leads

# Get stats
curl http://localhost:8000/api/stats

# Start a search (may take time)
curl -X POST http://localhost:8000/api/search \
  -H "Content-Type: application/json" \
  -d '{
    "categories": ["web_development"],
    "min_budget": 2000,
    "min_score": 70
  }'
```

---

## 📊 CoDriver's Decision Log

Every message shows CoDriver's decision:

```
📥 User task: Build the lead list component
🧠 Autonomous decision: generate_component
🔧 Generating component...
✓ Complete
```

Possible decisions:
- `generate_component` - Building/editing code
- `execute_command` - Running tools/commands
- `search_codebase` - Finding code patterns
- `index_codebase` - Indexing files
- `respond_only` - Just answering

---

## 🆘 If CoDriver Gets Stuck

### CoDriver Should Ask You

If CoDriver can't figure something out, it should ask:

```
"I'm stuck on X. Here's what I've tried:
1. ...
2. ...

Questions:
- Should I try Y instead?
- Do you want me to consult HOSTBOX?
- Or would you prefer to give me specific instructions?"
```

### You Can Guide CoDriver

```bash
echo 'user: "Here\'s how to fix it: [step-by-step instructions]. Try this and report back."' >> ~/freightdev/openhwy/.ai/chats/codriver.txt
```

---

## 🎯 Success Criteria

CoDriver has successfully completed the project when:

✅ Frontend displays leads from backend API
✅ Filters work (min_score, status)
✅ Lead detail view shows full lead info
✅ All tests pass
✅ No console errors
✅ Backend integration works

---

## 🚀 Quick Start Commands

### Monitor CoDriver
```bash
tail -f ~/freightdev/openhwy/.ai/chats/codriver.txt
```

### Answer CoDriver
```bash
echo 'user: "Your answer here"' >> ~/freightdev/openhwy/.ai/chats/codriver.txt
```

### Check What CoDriver Built
```bash
ls -la ~/freightdev/openhwy/.ai/lead-agency-v2/frontend/
```

### Test the Backend
```bash
curl http://localhost:8000/api/leads
```

---

**You're now ready to work with CoDriver autonomously! CoDriver will ask questions, and you guide it step by step.** 🚛💪
