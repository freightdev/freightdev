# Lead Agency v2 - Autonomous Lead Generation

**Python + FastAPI + Ollama Cluster**

Multi-agent system that finds, scores, researches, and drafts outreach for $1k+ dev gigs.

---

## Quick Start

```bash
cd ~/freightdev/openhwy/.ai/lead-agency-v2

# Copy environment variables
cp .env.example .env

# Start services
docker compose up -d

# Check logs
docker compose logs -f api

# Test API
curl http://localhost:8000
```

---

## Architecture

```
Scout Agent → Finds leads (Reddit, HackerNews, Indeed)
    ↓
Qualifier Agent → Scores 0-100 using Ollama
    ↓
Researcher Agent → Enriches with research
    ↓
Outreach Agent → Drafts personalized messages
    ↓
PostgreSQL → Stores everything
```

---

## API Endpoints

### Health Check
```bash
curl http://localhost:8000
```

### Start Lead Search
```bash
curl -X POST http://localhost:8000/api/search \
  -H "Content-Type: application/json" \
  -d '{
    "categories": ["web_development"],
    "min_budget": 2000,
    "sources": ["reddit", "hackernews"],
    "min_score": 70
  }'
```

### Get Qualified Leads
```bash
curl "http://localhost:8000/api/leads?min_score=70&limit=10"
```

### Get Lead Details
```bash
curl http://localhost:8000/api/leads/1
```

### Get Stats
```bash
curl http://localhost:8000/api/stats
```

---

## Agents

### 1. Scout Agent
- Scrapes Reddit (r/forhire, r/freelance_forhire)
- Scrapes HackerNews (Who's Hiring threads)
- Extracts budget, tech stack, contact info

### 2. Qualifier Agent
- Uses Ollama (qwen2.5:14b on hostbox)
- Scores 0-100 based on:
  - Budget (30 pts)
  - Description quality (20 pts)
  - Tech stack match (15 pts)
  - Client quality (20 pts)
  - Timeline (10 pts)
  - Red flags (-20 pts each)

### 3. Researcher Agent
- Uses Ollama (gemma3:12b on hostbox)
- Researches company background
- Finds similar projects
- Estimates hours needed

### 4. Outreach Agent
- Uses Ollama (qwen2.5:14b on hostbox)
- Drafts personalized outreach emails
- Professional, confident tone
- Ready to send

---

## Database Schema

```sql
CREATE TABLE leads (
    id SERIAL PRIMARY KEY,
    source VARCHAR(50),
    title TEXT,
    description TEXT,
    url TEXT,
    budget_min INTEGER,
    budget_max INTEGER,
    tech_stack TEXT[],
    company_name VARCHAR(255),
    contact_email VARCHAR(255),
    score INTEGER,
    score_breakdown JSONB,
    qualified BOOLEAN,
    research_notes TEXT,
    estimated_hours INTEGER,
    outreach_draft TEXT,
    status VARCHAR(50),
    found_at TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

---

## Development

### Run Locally (without Docker)

```bash
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export DATABASE_URL="postgresql://leads:leads123@localhost:5432/lead_agency"
export OLLAMA_ENDPOINTS="http://192.168.12.106:11434,..."

# Run server
uvicorn app.main:app --reload
```

### Test Ollama Connection

```bash
curl http://192.168.12.106:11434/api/tags
```

---

## CoDriver Integration

CoDriver can call the Lead Agency API:

```rust
// In CoDriver
let response = reqwest::Client::new()
    .post("http://localhost:8000/api/search")
    .json(&json!({
        "categories": ["web_development"],
        "min_budget": 2000,
        "min_score": 70
    }))
    .send()
    .await?;
```

---

## Cost

**Total: $0/month**

- Ollama cluster: Local ($0)
- Database: Docker PostgreSQL ($0)
- Scraping: Free sources only ($0)
- API: Self-hosted ($0)

**vs Cloud:** $175-525/month for equivalent LLM API usage

---

## Next Steps

1. Add more scrapers (Indeed API, LinkedIn, Twitter)
2. Build React dashboard UI
3. Add email sending integration
4. Implement response tracking
5. Add CRM features

---

**Built For:** Jesse E.E.W. Conley
**Stack:** Python, FastAPI, Ollama, PostgreSQL
**Mission:** Find paid dev work autonomously

🚛💪
