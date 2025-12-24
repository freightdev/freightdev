# 🚀 Lead Generation Engine - Complete Deployment Guide

## What You Just Got

A fully autonomous AI-powered lead generation agency that:
- ✅ Scrapes leads from multiple sources (web, LinkedIn, CSV)
- ✅ AI qualifies every lead (0-100 score)
- ✅ Auto-responds to email replies
- ✅ Books calls automatically
- ✅ Load balances across your 4 Ollama instances
- ✅ Falls back to Claude if Ollama is down
- ✅ Dashboard to monitor everything
- ✅ Fully configurable via `config.toml`

---

## 📁 Directory Structure

Create this structure:

```
lead-agency/
├── docker-compose.yml
├── .env
├── config.toml
├── init-db/
│   └── 001-schema.sql
├── lead-engine/
│   ├── Dockerfile
│   ├── package.json
│   ├── src/
│   │   └── index.js
│   └── scrapers/
│       ├── web_scraper.js
│       ├── linkedin.js
│       └── csv_import.js
├── api-server/
│   ├── Dockerfile
│   ├── package.json
│   └── src/
│       └── server.js
├── dashboard/
│   ├── Dockerfile
│   ├── package.json
│   ├── public/
│   └── src/
│       ├── App.jsx
│       ├── App.css
│       └── index.js
├── workflows/
│   └── ai-response-handler.json
└── data/
    └── custom_leads.csv (optional)
```

---

## ⚡ Quick Start (5 Minutes)

### 1. Clone/Create Project

```bash
mkdir -p lead-agency/{init-db,lead-engine/src,lead-engine/scrapers,api-server/src,dashboard/src,workflows,data}
cd lead-agency
```

### 2. Copy All Files

Copy each artifact from this conversation into the correct location:
- Docker Compose → `docker-compose.yml`
- Database Schema → `init-db/001-schema.sql`
- Config → `config.toml`
- Lead Engine → `lead-engine/src/index.js`
- Scrapers → `lead-engine/scrapers/*.js`
- API Server → `api-server/src/server.js`
- Dashboard → `dashboard/src/App.jsx` & `App.css`
- N8N Workflow → `workflows/ai-response-handler.json`
- Package.json files for each service
- Dockerfiles for each service

### 3. Configure Environment

Create `.env` file:

```bash
# PostgreSQL
POSTGRES_USER=lead_admin
POSTGRES_PASSWORD=$(openssl rand -base64 24)
POSTGRES_PORT=5432

# Redis
REDIS_PASSWORD=$(openssl rand -base64 24)

# N8N
N8N_USER=admin
N8N_PASSWORD=$(openssl rand -base64 16)

# Ollama (UPDATE WITH YOUR IPS!)
OLLAMA_BASE_URLS=http://192.168.1.100:11434,http://192.168.1.101:11434,http://192.168.1.102:11434,http://192.168.1.103:11434

# Open-WebUI
WEBUI_SECRET_KEY=$(openssl rand -base64 32)

# Optional: Cloud fallback
# CLOUD_API_KEY=your_anthropic_key_here
```

### 4. Update config.toml

**CRITICAL:** Edit `config.toml` and update:

1. **Ollama endpoints** (lines 16-21) - your actual laptop IPs
2. **Personal info** (lines 250-260) - your name, email, skills
3. **Email SMTP** (lines 300-310) - your email provider settings

### 5. Launch Everything

```bash
# Build and start all services
docker-compose up -d --build

# Check logs
docker-compose logs -f

# Verify all services healthy
docker-compose ps
```

### 6. Access Your Services

- **Dashboard:** http://localhost:8888
- **Open-WebUI:** http://localhost:3000
- **N8N:** http://localhost:5678 (user/pass from `.env`)
- **API:** http://localhost:3001/health

---

## 🎯 First Campaign Setup

### Option 1: Web Scraping (Easiest to Test)

1. Edit `config.toml` and add some trucking websites:

```toml
[[sources]]
name = "trucking_websites"
type = "web_scraper"
enabled = true
target_urls = [
    "https://truckerdirectory.com",
    "https://example-trucking.com/contact"
]
```

2. The engine will auto-scrape every hour

3. Check dashboard for new leads

### Option 2: CSV Import (Manual Control)

1. Create `data/custom_leads.csv`:

```csv
email,first_name,last_name,company_name,phone,website
john@acmetrucking.com,John,Doe,Acme Trucking,555-1234,https://acmetrucking.com
```

2. Update `config.toml`:

```toml
[[sources]]
name = "custom_list"
type = "csv_import"
enabled = true
csv_path = "/data/custom_leads.csv"
```

3. Leads imported on next cycle

### Option 3: LinkedIn (Requires Integration)

See LinkedIn scraper comments in code. Options:
- PhantomBuster API
- Apify
- Manual CSV export from LinkedIn Sales Navigator

---

## 🤖 AI Response Handler Setup

### Import N8N Workflow

1. Open N8N: http://localhost:5678
2. Login (credentials from `.env`)
3. Click "Import" → Upload `workflows/ai-response-handler.json`
4. Configure PostgreSQL credentials
5. Configure SMTP credentials
6. **Activate the workflow**

### How It Works

1. Every 5 minutes, checks for new email replies
2. AI reads the reply and generates response
3. If confidence is high → auto-sends
4. If confidence is low → notifies you for review
5. All logged to database

---

## 📊 Dashboard Usage

### Overview Tab
- Total leads, hot leads, responses, calls
- Real-time stats update every 30 seconds

### Leads Tab
- All leads with scores
- Filter by campaign, status, score
- Click for full details

### Hot Leads Tab
- Score ≥ 70
- Ready for calls
- Quick action buttons

### Calls Tab
- All scheduled calls
- Update status after calls

### Campaigns Tab
- Performance metrics
- Response rates
- Average scores

---

## 🔧 Configuration Deep Dive

### Daily Limits

```toml
[engine]
max_leads_per_day = 100        # Total leads to find
max_outreach_per_day = 50      # Total emails to send
scrape_interval_minutes = 60   # How often to run
```

### Ollama Models

```toml
[ollama.models]
lead_qualification = "llama3.2:13b"  # Best model for qualification
email_writing = "llama3.2:13b"       # Email generation
linkedin_messages = "llama3.2:7b"    # Faster for short content
```

### Campaign Configuration

Each campaign has:
- `name` - Unique identifier
- `enabled` - Turn on/off
- `target_sources` - Which scrapers to use
- `prompt_template` - Which AI prompts to use
- `channels` - email, linkedin, sms
- `follow_up_enabled` - Auto follow-ups

### Prompt Templates

Edit prompts in `config.toml`:

```toml
[prompts.trucking_pitch]
system = "Your AI's personality..."
initial_email_subject = "Subject line..."
initial_email_body = "Email template with {{VARIABLES}}..."
```

Variables available:
- `{{COMPANY_NAME}}`
- `{{FIRST_NAME}}`
- `{{YOUR_NAME}}`
- `{{YOUR_CONTACT}}`
- etc.

---

## 🐛 Troubleshooting

### Ollama Not Reachable

```bash
# Test from your machine
curl http://192.168.1.100:11434/api/tags

# Test from lead-engine container
docker exec -it lead_engine curl http://192.168.1.100:11434/api/tags

# Check firewall on Ollama machines
sudo ufw allow 11434/tcp

# Make sure Ollama is listening on all interfaces
OLLAMA_HOST=0.0.0.0 ollama serve
```

### Database Connection Issues

```bash
# Check PostgreSQL is running
docker-compose ps postgres

# Test connection
docker exec -it lead_postgres psql -U lead_admin -d lead_agency -c "SELECT 1;"

# View logs
docker-compose logs postgres
```

### No Leads Being Found

```bash
# Check lead engine logs
docker-compose logs lead_engine

# Verify config is loaded
docker exec -it lead_engine cat /app/config.toml

# Check scraping jobs table
docker exec -it lead_postgres psql -U lead_admin -d lead_agency -c "SELECT * FROM scraping_jobs ORDER BY created_at DESC LIMIT 10;"
```

### AI Not Responding to Emails

```bash
# Check N8N workflow is active
# Visit http://localhost:5678

# Check for new replies in database
docker exec -it lead_postgres psql -U lead_admin -d lead_agency -c "SELECT * FROM outreach WHERE replied = true AND ai_response_sent = false;"

# Check N8N logs
docker-compose logs n8n
```

---

## 📈 Scaling Tips

### Add More Ollama Instances

Just add to `config.toml`:

```toml
primary_endpoints = [
    "http://192.168.1.100:11434",
    "http://192.168.1.101:11434",
    "http://192.168.1.102:11434",
    "http://192.168.1.103:11434",
    "http://192.168.1.105:11434"  # New one
]
```

Restart: `docker-compose restart lead-engine`

### Increase Daily Limits

```toml
max_leads_per_day = 500      # Up from 100
max_outreach_per_day = 200   # Up from 50
```

### Add More Scrapers

Create new scraper in `scrapers/your_scraper.js`:

```javascript
class YourScraper {
  constructor(engine) {
    this.engine = engine;
    this.name = 'your_scraper';
  }
  
  async scrape(source, campaign) {
    // Your scraping logic
    return leads;
  }
}

module.exports = YourScraper;
```

### Enable Redis Queue Mode

Uncomment in `docker-compose.yml`:

```yaml
- EXECUTIONS_MODE=queue
```

---

## 🔐 Security Checklist

- [ ] Changed all default passwords in `.env`
- [ ] `.env` in `.gitignore` (NEVER commit)
- [ ] Strong SMTP password (app-specific for Gmail)
- [ ] PostgreSQL not exposed to public internet
- [ ] N8N behind VPN or firewall
- [ ] Regular backups enabled
- [ ] API rate limiting configured
- [ ] Ollama instances on private network

---

## 💾 Backup Strategy

```bash
# Manual backup
docker exec lead_postgres pg_dump -U lead_admin lead_agency > backup_$(date +%Y%m%d).sql

# Enable auto-backup (already in docker-compose)
docker-compose --profile with-backup up -d

# Restore from backup
cat backup_20240101.sql | docker exec -i lead_postgres psql -U lead_admin lead_agency
```

---

## 🎓 Next Steps

### Week 1: Test & Tune
1. Import 10-20 test leads via CSV
2. Watch AI qualification scores
3. Adjust prompts in `config.toml`
4. Test email responses

### Week 2: First Real Campaign
1. Enable web scraper for trucking sites
2. Review leads daily in dashboard
3. Take calls with qualified leads
4. Refine your pitch based on feedback

### Week 3: Scale Up
1. Add more sources
2. Increase daily limits
3. Enable auto-responses
4. Add follow-up sequences

### Month 2+
1. Build custom scrapers for your niche
2. Create client-specific campaigns
3. Integrate with your CRM
4. Add SMS/LinkedIn automation

---

## 📞 Getting Your First Client

### The Manual Bootstrapping Method

While AI is finding leads, do this TODAY:

1. **Post on LinkedIn:**
   ```
   After 10 years in trucking, I switched to building software. 
   Now I help trucking companies automate their dispatch, load boards, 
   and driver management. 
   
   If you're still using spreadsheets for dispatch, let's chat.
   ```

2. **Email 10 Trucking Companies:**
   Use the AI-generated emails from your config.toml templates

3. **Join Trucking Facebook Groups:**
   Answer questions, offer free advice, mention your services

4. **Reddit r/trucking:**
   Be helpful, don't spam, DM interested people

### The AI Method

Let the system run for 2-3 weeks:
- It finds leads
- AI qualifies them
- AI reaches out
- AI books calls
- You close deals

---

## 🚨 Common Mistakes to Avoid

1. **Don't over-promise** - Start with small projects, deliver fast
2. **Don't skip qualification** - Bad leads waste your time
3. **Don't send too much outreach** - Quality > quantity
4. **Don't ignore replies** - Respond within 24 hours
5. **Don't forget follow-ups** - Most deals happen on 3rd+ contact

---

## ✅ System Health Checks

Run daily:

```bash
# All services running?
docker-compose ps

# Any errors in logs?
docker-compose logs --tail=100 | grep ERROR

# Database healthy?
docker exec lead_postgres psql -U lead_admin -d lead_agency -c "SELECT COUNT(*) FROM leads;"

# Ollama instances working?
curl http://192.168.1.100:11434/api/tags

# Today's stats
curl http://localhost:3001/api/dashboard/stats
```

---

## 📚 Additional Resources

- [N8N Documentation](https://docs.n8n.io/)
- [Ollama API Docs](https://github.com/ollama/ollama/blob/main/docs/api.md)
- [PostgreSQL Tuning](https://pgtune.leopard.in.ua/)

---

## 🎉 You're Ready!

Start the system, watch the dashboard, and close your first deal.

**Your AI employees are ready to work 24/7.**

Questions? Check the logs. Still stuck? Re-read this guide.

Now go get some clients! 🚀
