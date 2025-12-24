# Lead Agency v2 - Multi-Agent Lead Generation

**Language:** Python
**Framework:** CrewAI
**API:** FastAPI
**Database:** PostgreSQL
**UI:** React + Tailwind
**LLM:** Ollama Cluster (100% local, zero cost)

---

## Architecture Overview

```
CoDriver (Rust coordinator)
    ↓ HTTP API
Lead Agency API (FastAPI)
    ↓
Agent Team (CrewAI)
    ├── Scout Agent      → Finds leads from free sources
    ├── Qualifier Agent  → Scores leads (0-100)
    ├── Researcher Agent → Enriches lead data
    └── Outreach Agent   → Drafts messages
    ↓
PostgreSQL Database
    ↓
Dashboard UI (React)
```

---

## Multi-Agent Team (CrewAI)

### 1. Scout Agent
**Role:** Lead Finder
**Goal:** Find $1k+ dev gigs from free sources
**Tools:**
- Reddit scraper (r/forhire, r/freelance_forhire)
- Indeed API (free tier)
- HackerNews scraper (Who's Hiring threads)
- Twitter/X search (#freelance #remotework #hiring)
- LinkedIn Jobs (public listings)

**Output:** Raw leads with basic info

### 2. Qualifier Agent
**Role:** Lead Scorer
**Goal:** Score leads 0-100 based on quality
**LLM:** Ollama (qwen2.5:14b on hostbox)
**Criteria:**
- Budget estimate (30 points)
- Description quality (20 points)
- Tech stack match (15 points)
- Client history (20 points)
- Timeline reasonableness (10 points)
- Response rate (5 points)

**Output:** Scored leads with qualification notes

### 3. Researcher Agent
**Role:** Lead Enricher
**Goal:** Add context and intelligence
**LLM:** Ollama (gemma3:12b on hostbox)
**Actions:**
- Research company/client
- Find similar past projects
- Estimate complexity
- Identify potential challenges

**Output:** Enriched lead with research

### 4. Outreach Agent
**Role:** Message Writer
**Goal:** Draft personalized outreach
**LLM:** Ollama (qwen2.5:14b on hostbox)
**Templates:**
- Cold outreach email
- Proposal draft
- Follow-up sequence

**Output:** Ready-to-send messages

---

## Database Schema

```sql
CREATE TABLE leads (
    id SERIAL PRIMARY KEY,
    source VARCHAR(50),              -- 'reddit', 'indeed', 'hackernews', etc.
    title TEXT,
    description TEXT,
    url TEXT,
    budget_min INTEGER,
    budget_max INTEGER,
    tech_stack TEXT[],
    company_name VARCHAR(255),
    contact_email VARCHAR(255),
    contact_name VARCHAR(255),

    -- Scoring
    score INTEGER,                   -- 0-100
    score_breakdown JSONB,           -- Detailed scoring
    qualified BOOLEAN DEFAULT false,

    -- Enrichment
    research_notes TEXT,
    similar_projects JSONB,
    estimated_hours INTEGER,

    -- Outreach
    outreach_draft TEXT,
    outreach_sent BOOLEAN DEFAULT false,

    -- Metadata
    found_at TIMESTAMP DEFAULT NOW(),
    qualified_at TIMESTAMP,
    status VARCHAR(50) DEFAULT 'new', -- new, qualified, reached_out, responded, won, lost

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_leads_score ON leads(score DESC);
CREATE INDEX idx_leads_qualified ON leads(qualified);
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_source ON leads(source);
```

---

## API Endpoints (FastAPI)

### POST /api/search
Start a lead search campaign

**Request:**
```json
{
  "categories": ["web_development", "mobile_development"],
  "min_budget": 1000,
  "max_budget": 10000,
  "sources": ["reddit", "indeed", "hackernews"],
  "min_score": 70
}
```

**Response:**
```json
{
  "search_id": "uuid",
  "status": "running",
  "sources_count": 3,
  "estimated_time": "5 minutes"
}
```

### GET /api/leads
Get qualified leads

**Query Params:**
- `min_score=70` - Minimum score
- `status=qualified` - Filter by status
- `source=reddit` - Filter by source
- `limit=50` - Max results

**Response:**
```json
{
  "leads": [
    {
      "id": 1,
      "title": "Need React developer for SaaS dashboard",
      "source": "reddit",
      "budget_min": 3000,
      "budget_max": 5000,
      "score": 85,
      "tech_stack": ["React", "TypeScript", "Tailwind"],
      "qualified": true,
      "status": "qualified",
      "found_at": "2025-11-20T10:30:00Z"
    }
  ],
  "total": 100,
  "page": 1
}
```

### GET /api/leads/{id}
Get full lead details with research and outreach

**Response:**
```json
{
  "id": 1,
  "title": "Need React developer for SaaS dashboard",
  "description": "Looking for experienced React dev...",
  "source": "reddit",
  "url": "https://reddit.com/r/forhire/...",
  "budget_min": 3000,
  "budget_max": 5000,
  "tech_stack": ["React", "TypeScript", "Tailwind"],
  "company_name": "TechStartup Inc",
  "contact_email": "founder@techstartup.com",

  "score": 85,
  "score_breakdown": {
    "budget": 28,
    "description_quality": 18,
    "tech_stack_match": 15,
    "client_history": 15,
    "timeline": 9
  },

  "research_notes": "Company is a 2-year-old SaaS startup...",
  "similar_projects": [
    {"title": "Similar dashboard project", "outcome": "successful"}
  ],
  "estimated_hours": 80,

  "outreach_draft": "Hi [Name],\n\nI saw your post about the React dashboard...",

  "status": "qualified",
  "found_at": "2025-11-20T10:30:00Z"
}
```

### POST /api/leads/{id}/outreach
Send outreach message (future)

---

## Agent Workflow

### 1. Search Initiated (by CoDriver)

```python
# CoDriver calls API
POST /api/search
{
  "categories": ["web_development"],
  "min_budget": 2000,
  "sources": ["reddit", "indeed"]
}
```

### 2. Scout Agent Activates

```python
class ScoutAgent:
    def search_reddit(self):
        # Scrape r/forhire, r/freelance_forhire
        # Filter for web dev, $2k+ budget
        # Return raw leads

    def search_indeed(self):
        # Use Indeed API (free tier)
        # Search for "React developer" etc.
        # Return raw leads
```

**Output:** 50 raw leads found

### 3. Qualifier Agent Processes

```python
class QualifierAgent:
    def score_lead(self, lead):
        # Build prompt for Ollama
        prompt = f"""
        Score this lead 0-100:

        Title: {lead.title}
        Description: {lead.description}
        Budget: ${lead.budget_min}-${lead.budget_max}
        Tech: {lead.tech_stack}

        Criteria:
        - Budget (30 points)
        - Description quality (20 points)
        - Tech match (15 points)
        - Client history (20 points)
        - Timeline (10 points)
        - Response rate (5 points)

        Return JSON: {{"score": X, "breakdown": {{...}}, "notes": "..."}}
        """

        # Query hostbox qwen2.5:14b
        response = ollama.generate(
            model="qwen2.5:14b",
            endpoint="http://192.168.12.106:11434",
            prompt=prompt
        )

        return parse_score(response)
```

**Output:** 15 leads scored ≥70

### 4. Researcher Agent Enriches

```python
class ResearcherAgent:
    def research_lead(self, lead):
        # Google search for company
        # Check similar projects
        # Estimate complexity

        prompt = f"""
        Research this lead:
        Company: {lead.company_name}
        Project: {lead.title}

        Provide:
        1. Company background
        2. Similar projects we could reference
        3. Estimated hours
        4. Potential challenges
        """

        # Query gemma3:12b
        research = ollama.generate(
            model="gemma3:12b",
            endpoint="http://192.168.12.106:11434",
            prompt=prompt
        )

        return research
```

**Output:** Enriched lead data

### 5. Outreach Agent Drafts

```python
class OutreachAgent:
    def draft_message(self, lead):
        prompt = f"""
        Draft a professional outreach email:

        Lead: {lead.title}
        Company: {lead.company_name}
        Budget: ${lead.budget_min}-${lead.budget_max}

        Tone: Professional, confident, concise
        Highlight: Our tech stack matches their needs
        Include: Portfolio link, availability
        Max: 200 words
        """

        # Query qwen2.5:14b
        draft = ollama.generate(
            model="qwen2.5:14b",
            endpoint="http://192.168.12.106:11434",
            prompt=prompt
        )

        return draft
```

**Output:** Ready-to-send email

### 6. Results Saved to Database

```python
# Save to PostgreSQL
db.save_lead({
    "source": "reddit",
    "title": "...",
    "score": 85,
    "qualified": True,
    "research_notes": "...",
    "outreach_draft": "...",
    "status": "qualified"
})
```

### 7. Dashboard Shows Results

React UI displays qualified leads in real-time

---

## Dashboard UI (React)

### Features

1. **Lead List View**
   - Table of qualified leads
   - Sort by score, budget, date
   - Filter by source, status
   - Color-coded by score (green=80+, yellow=70-79, gray=<70)

2. **Lead Detail View**
   - Full description
   - Score breakdown (pie chart)
   - Research notes
   - Outreach draft (editable)
   - Send button (future)

3. **Stats Dashboard**
   - Total leads found
   - Qualified leads (score ≥70)
   - Average score
   - Breakdown by source
   - Timeline chart

### Stack

- **Framework:** React + Vite
- **Styling:** Tailwind CSS
- **Components:** Shadcn UI
- **Charts:** Recharts
- **API Client:** Axios

---

## Docker Compose

```yaml
version: '3.8'

services:
  # PostgreSQL database
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: leads
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: lead_agency
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U leads"]
      interval: 10s
      timeout: 5s
      retries: 5

  # FastAPI backend
  api:
    build: ./backend
    environment:
      DATABASE_URL: postgresql://leads:${POSTGRES_PASSWORD}@postgres:5432/lead_agency
      OLLAMA_ENDPOINTS: http://192.168.12.106:11434,http://192.168.12.136:11434,http://192.168.12.66:11434,http://192.168.12.9:11434
    ports:
      - "8000:8000"
    depends_on:
      postgres:
        condition: service_healthy
    volumes:
      - ./backend:/app
    command: uvicorn main:app --host 0.0.0.0 --port 8000 --reload

  # React dashboard
  dashboard:
    build: ./frontend
    ports:
      - "3000:3000"
    environment:
      VITE_API_URL: http://localhost:8000
    volumes:
      - ./frontend:/app
      - /app/node_modules
    command: npm run dev

volumes:
  postgres-data:
```

---

## CrewAI Configuration

```python
from crewai import Agent, Task, Crew

# Define agents
scout = Agent(
    role='Lead Scout',
    goal='Find high-quality dev gigs from free sources',
    backstory='Expert at finding hidden opportunities',
    tools=[reddit_scraper, indeed_api, hn_scraper],
    verbose=True
)

qualifier = Agent(
    role='Lead Qualifier',
    goal='Score and filter leads',
    backstory='Experienced at evaluating project quality',
    llm=OllamaLLM(model='qwen2.5:14b', base_url='http://192.168.12.106:11434'),
    verbose=True
)

researcher = Agent(
    role='Lead Researcher',
    goal='Enrich leads with context and intelligence',
    backstory='Skilled researcher and analyst',
    llm=OllamaLLM(model='gemma3:12b', base_url='http://192.168.12.106:11434'),
    verbose=True
)

outreach = Agent(
    role='Outreach Specialist',
    goal='Draft compelling outreach messages',
    backstory='Experienced sales and marketing professional',
    llm=OllamaLLM(model='qwen2.5:14b', base_url='http://192.168.12.106:11434'),
    verbose=True
)

# Define tasks
task_find = Task(
    description='Find 50 leads from Reddit, Indeed, and HackerNews',
    agent=scout,
    expected_output='List of raw leads with basic info'
)

task_qualify = Task(
    description='Score leads and keep only those with score ≥70',
    agent=qualifier,
    expected_output='Scored and filtered leads'
)

task_research = Task(
    description='Research top 10 leads and add context',
    agent=researcher,
    expected_output='Enriched lead data'
)

task_outreach = Task(
    description='Draft outreach messages for qualified leads',
    agent=outreach,
    expected_output='Ready-to-send emails'
)

# Create crew
crew = Crew(
    agents=[scout, qualifier, researcher, outreach],
    tasks=[task_find, task_qualify, task_research, task_outreach],
    verbose=True
)

# Run crew
result = crew.kickoff()
```

---

## Free Lead Sources

### Reddit
- r/forhire
- r/freelance_forhire
- r/hiring
- r/slavelabour (low-budget gigs)

### Indeed
- Free job search API
- Filter: remote, $1k+ salary
- Keywords: "React developer", "web developer", "full stack"

### HackerNews
- Monthly "Who's Hiring" threads
- Parse comments for job posts
- Extract contact info

### Twitter/X
- Search: #freelance #hiring #remotework
- Filter: recent, has budget mention
- Extract leads from tweets

### LinkedIn
- Public job listings (no premium needed)
- Search by keywords
- Extract company and contact info

---

## Cost Analysis

**Total Cost:** $0/month

- **LLM:** Ollama cluster (local) - $0
- **Database:** PostgreSQL (Docker) - $0
- **Scraping:** All free sources - $0
- **API:** FastAPI (self-hosted) - $0
- **UI:** React (self-hosted) - $0

**vs Cloud:**
- OpenAI API: ~$50-200/month
- Anthropic Claude: ~$100-300/month
- Database hosting: ~$25/month
- Total cloud cost: $175-525/month

**Savings:** $175-525/month = $2,100-6,300/year

---

## Success Metrics

**Goal:** Find 10 qualified leads per day

**Qualified = Score ≥70:**
- Budget ≥$1,000
- Detailed description
- Tech stack match
- Reasonable timeline

**Expected Results:**
- 50 raw leads found/day
- 15 qualified leads/day (30% conversion)
- 10+ opportunities to pursue

**Revenue Potential:**
- 15 qualified leads/day × 30 days = 450 leads/month
- 5% conversion to gigs = 22 gigs/month
- Average $3k/gig = $66k/month potential

---

## Implementation Plan

### Phase 1: Core Infrastructure (Day 1)
- ✅ Docker Compose setup
- ✅ PostgreSQL schema
- ✅ FastAPI skeleton
- ✅ CrewAI agent structure

### Phase 2: Scout Agent (Day 2)
- ✅ Reddit scraper
- ✅ Indeed API integration
- ✅ HackerNews parser

### Phase 3: Qualifier Agent (Day 3)
- ✅ Ollama integration
- ✅ Scoring logic
- ✅ Database storage

### Phase 4: Researcher & Outreach (Day 4)
- ✅ Research agent
- ✅ Outreach agent
- ✅ Full pipeline test

### Phase 5: Dashboard (Day 5)
- ✅ React UI
- ✅ Lead list view
- ✅ Lead detail view
- ✅ Stats dashboard

---

**Built For:** Jesse E.E.W. Conley
**Mission:** Find paid dev work autonomously while building FED TMS
**Stack:** 100% Python, 100% local, 100% free, 100% autonomous

🚛💪 Let's find some gigs!
