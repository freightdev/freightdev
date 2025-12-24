# OpenHWY

**Learn truck dispatching the RIGHT way. Practice on real tools. Get matched with drivers. Start earning.**

Built by a truck driver who got tired of bad dispatchers hurting good drivers.

---

## 🚛 The Problem

I drove trucks for 10 years. Over-the-road, long haul, seen it all.

I had **great dispatchers** who:

- Found good loads
- Respected my time
- Understood HOS rules
- Got me home when promised
- Made me $80K+/year

I had **terrible dispatchers** who:

- Booked garbage loads
- Violated my HOS
- Lied about home time
- Made me $40K/year
- Made me want to quit trucking

**The difference wasn't that bad dispatchers were evil—they were IGNORANT.**

Nobody taught them the right way. They learned from other bad dispatchers. The cycle continues.

3.5 million truck drivers in the US. Most of them suffering because their dispatcher doesn't know any better.

**I decided to fix it.**

---

## 🎓 The Solution: OpenHWY

OpenHWY is a **training platform + labor marketplace** for truck dispatchers.

### For Aspiring Dispatchers:

1. **LEARN** - ELDA (AI instructor) teaches you dispatching
2. **PRACTICE** - Mini TMS (web + mobile) to practice with real scenarios
3. **EARN** - Join FED's Fleet, get matched with drivers, start working immediately

**Pricing:**

- **Free Tier** (1000 seats): Full training, Mini TMS, community support
- **Premium Tier** (300 seats): Everything + unlimited AI tutor + priority matching ($97/month)

### For Drivers & Fleets:

1. **JOIN DRIVER POOL** - Tell us what you need (flatbed, reefer, regional, OTR)
2. **GET MATCHED** - FED (AI) matches you with certified dispatchers
3. **FIRST MONTH FREE** - Try them out, pay nothing for 30 days
4. **PAY ONLY IF YOU LOVE THEM** - 8% full dispatch, 12% JIT loads, 3% paperwork

### The Marketplace (FED's Fleet):

Graduates join **FED's Fleet**—a two-sided marketplace connecting dispatchers and drivers.

**How it works:**

- Dispatcher graduates from OpenHWY
- Joins FED's Fleet
- Gets matched with driver/fleet
- Earns **70% commission** (FED takes 30%)
- After **1 year**: Buy out contract (reasonable fee: $500-2000)
- After buyout: Keep **100% of earnings**

**We don't trap you. We help you build your own business.**

---

## 🤖 The AI Team

### FED (Fleet Ecosystem Director)

Your platform navigator and fleet manager. Guides you through OpenHWY, tracks your progress, matches dispatchers with drivers, manages workload distribution.

**Role:** AI matchmaker + fleet operations manager

### ELDA (Enhanced Logistics Dispatching Assistant)

Your personal AI instructor. Teaches dispatching, answers questions 24/7, adapts to your learning style, available to BOTH dispatchers AND drivers.

**Role:** AI teacher + knowledge base + conversation partner

### Wheeler Agents (Automation Helpers)

**Packet Pilot** - Automatically fills out carrier packets, rate confirmations, BOLs. No more 1-hour paperwork grinds.

**Cargo Connect** - Aggregates YOUR load boards (DAT, Truckstop, 123Loadboard) and searches them all at once. Only works with boards you're subscribed to—doesn't scrape the web.

**More agents coming:** 20+ planned for various dispatch tasks.

---

## 📖 Trucker Tales

Drivers share their stories. Experiences—good and bad—become teaching material for future dispatchers.

**Why this matters:**

- Real stories teach better than textbooks
- Drivers' voices shape the curriculum
- Your knowledge doesn't die with you
- Popular stories earn revenue share

---

## 💰 Business Model

### Revenue Streams:

1. **Training (Break-even)**
   - AI Tutor: Pay-per-use ($0.05-0.25 per conversation)
   - Partner Courses: 30% commission on external courses
   - Goal: Cover costs, small profit

2. **Software (High Margin)**
   - TMS Free Tier: $0 (funnel)
   - TMS Pro Tier: $247/month (96% margin)
   - TMS Max Tier: $497/month (98% margin)
   - Goal: Primary revenue

3. **Services (Scalable)**
   - Full Dispatch: 8% of gross (30% to us, 70% to dispatcher)
   - JIT Load Finder: 12% per load
   - Paperwork Handler: 3% of gross
   - Contract Buyouts: $500-2000 one-time fee
   - Goal: Help dispatchers start, let them buy out

### Why This Model Works:

**Traditional TMS:**

```
Charge $100-500/month upfront
User struggles (no training, no clients)
User churns after 3 months
Revenue: $300 total
```

**OpenHWY:**

```
Give training FREE
Give basic TMS FREE
User learns dispatching
User gets clients (via FED's Fleet)
User makes $5K/month (70% of $7K gross)
User upgrades to Pro ($247/month) for automation
User stays 24+ months
Revenue: $5,928+ over lifetime

Plus contract buyout: $2,000
Total: $7,928 per successful dispatcher
```

**We make money when THEY make money. Perfect alignment.**

---

## 🔓 Why Open Source (AGPL-3.0)

### The Math:

```
Drivers in US: 3.5 million
Dispatchers needed: ~500,000

I can train: ~50,000 (10% of market)
That leaves: 450,000 untrained dispatchers
             3 million drivers still suffering
```

### The Choice:

**Option 1: Keep it Proprietary**

- Train 50,000 dispatchers
- Help 500,000 drivers
- Make $5M/year
- Mission: 14% complete

**Option 2: Open Source (AGPL)**

- Train 50,000 dispatchers myself
- Others fork it, train 450,000 more
- 3.5 million drivers get better dispatchers
- Make $5M/year (same)
- Mission: 100% complete

**I chose AGPL.**

### What AGPL Means:

**Anyone can:**

- Download the entire codebase
- Run their own instance
- Modify the courses
- Rebrand it completely
- Train dispatchers
- Make money with it

**They MUST:**

- Keep it open source (can't close the code)
- Share improvements (if they fix bugs, must share)
- Attribute original (credit OpenHWY)
- Use AGPL license (keep it free forever)

**They CAN'T:**

- Close-source it (make it proprietary)
- Patent it (can't lock it down)
- Remove attribution

### Real-World Fork Examples:

**Midwest Trucking Inc** (500 trucks):

- Forks OpenHWY
- Rebrands: "Midwest Trucking Academy"
- Trains 50 internal dispatchers
- 500 drivers get better dispatchers
- Cost to them: $0 (besides infrastructure)
- Cost to me: $0 revenue, but mission accomplished

**TruckDispatch Mexico**:

- Forks OpenHWY
- Translates to Spanish
- Adds Mexico-specific content
- Trains 5,000 Mexican dispatchers
- I get their Spanish translation (they contribute back)
- Mission spreads to Mexico WITHOUT ME

**This is how we fix trucking: Together.**

---

## 🏗️ Technical Architecture

### Tech Stack:

**Frontend:**

- **Landing Page**: Astro + Tailwind CSS (SSG, fast, SEO-friendly)
- **Mobile App**: Flutter (iOS + Android + Web from one codebase)

**Backend:**

- **API Services**: Rust microservices (high performance, low cost)
- **Edge Router**: Custom Pingora-based reverse proxy (Rust)
- **Database**: PostgreSQL with multi-tenant schemas (one schema per tenant)
- **Auth**: Zitadel (open source, OAuth/OIDC)
- **Storage**: Garage (S3-compatible, self-hosted)
- **AI Agents**: Custom Rust services (Packet Pilot, Cargo Connect, etc.)

**Infrastructure:**

- **Orchestration**: Nomad (simpler than Kubernetes, easier to fork)
- **Networking**: Nebula mesh VPN (P2P, no central bottleneck)
- **Monitoring**: Prometheus + Grafana + Loki
- **Compute**:
  - Homelab (primary, already owned)
  - Oracle Cloud (overflow, free tier + burst capacity)

### Three-Tier Isolation:

**Free Tier** - Shared Firecracker VM

```
All free users share ONE VM (4 vCPU, 4GB RAM)
Cost: $5/month total ($0.005 per user)
Isolation: PostgreSQL schemas (tenant_123, tenant_456)
Security: JWT auth, search_path isolation, rate limiting
```

**Pro Tier** - Warm Start Snapshots

```
Each Pro user gets dedicated VM snapshot
First request: Boot VM (200ms) + init (150ms) + exec (50ms) = 400ms
Next requests: Resume snapshot (25ms) + exec (50ms) = 75ms
After 10min idle: Pause VM (save to memory)
After 24hr idle: Delete snapshot (next request cold starts)
Cost: ~$10/month per user
Margin: $237/month (96%)
```

**Max Tier** - Dedicated Cloud

```
Full infrastructure per customer (separate Oracle Cloud account)
Customer pays Oracle directly ($100-500/month)
We manage: Terraform, Ansible, monitoring, scaling
We charge: $200/month management fee
Customer gets: Dedicated cluster, white-label, API access
Margin: $200/month (100% on our fee)
```

### AI Services:

**Self-Hosted:**

- Llama 3.3 70B (basic AI, $0.001 per conversation, we absorb cost)

**API-Based:**

- Claude Sonnet 4 (smart AI, $0.021 cost, $0.05 charge, 138% markup)
- Claude Opus 4 (genius AI, $0.105 cost, $0.25 charge, 138% markup)

**Fallback:**
Platform explicitly teaches users to copy questions to ChatGPT/Claude.ai/Gemini (free tiers). Zero barrier to learning.

---

## 📂 Repository Structure

```
openhwy/
├── apps/
│   ├── astro-web/          # Landing pages (dispatcher + driver)
│   └── flutter-app/        # Mobile app (iOS, Android, Web, Desktop)
├── pkgs/
│   ├── api-services/       # Rust microservices
│   │   ├── agent-custom-rust/  # AI agents (Packet Pilot, Cargo Connect, etc.)
│   │   ├── connection-custom-rust/  # Nebula CA & IP allocation
│   │   ├── payment-service/  # Stripe integration
│   │   ├── upload-custom-rust/  # File uploads
│   │   └── download-custom-rust/  # Secure downloads
│   ├── auth-zitadel/       # OAuth/OIDC provider
│   ├── edge-router/        # Pingora-based reverse proxy
│   ├── design-system/      # Shared design tokens
│   ├── shared-libs/        # Shared Rust libraries
│   ├── shared-types/       # OpenAPI schemas
│   └── storage-garage/     # S3-compatible storage
└── docs/                   # Documentation
```

---

## 🚀 Getting Started

### For Dispatchers:

1. Visit [openhwy.com](https://openhwy.com)
2. Claim your free beta seat (1000 available)
3. Start Module 1: "What is Dispatching?"
4. Practice in Mini TMS
5. Graduate and join FED's Fleet
6. Get matched with your first driver
7. Start earning

### For Drivers:

1. Visit [fleet.openhwy.com](https://fleet.openhwy.com)
2. Join Driver Pool (free)
3. Tell us what you need (truck type, routes, preferences)
4. Get matched with certified dispatcher
5. First month FREE
6. Pay only if you love them (8%, 12%, or 3%)

### For Developers (Fork It):

```bash
# Clone the repo
git clone https://github.com/fed-dispatch/openhwy.git
cd openhwy

# Read the setup guide
cat docs/SETUP.md

# Deploy your instance
./scripts/deploy.sh

# Customize for your region/niche
# Add your courses to /courses/
# Modify branding in /apps/astro-web/

# Contribute improvements back (AGPL requires it)
git commit -m "Added Spanish translation"
git push origin main
```

**Your fork, your rules, your brand—but keep it open source.**

---

## 🤝 Contributing

We welcome contributions! This project is **AGPL-3.0** which means:

✅ Fork it, modify it, run it, sell it
✅ Share improvements back to the community
✅ Keep it open source (can't close the code)

**How to contribute:**

1. Fork the repo
2. Create a feature branch
3. Make your changes
4. Submit a pull request
5. We review and merge

**What we need:**

- Course content (more modules)
- Translations (Spanish, etc.)
- Bug fixes
- Documentation improvements
- AI agent development (20+ agents planned)
- Load board integrations

---

## 📜 License

**AGPL-3.0** - See [LICENSE](LICENSE) for details.

**Why AGPL?**

- Keeps it open source forever
- Forces derivatives to share improvements
- Prevents proprietary forks from locking it down
- Ensures the mission outlives the founder

**TL;DR:** Use it, fork it, modify it, monetize it—just keep it open source.

---

## 🌟 The Mission

**Fix the trucking industry by training dispatchers the RIGHT way.**

Not by building a unicorn startup.

Not by getting acquired.

Not by chasing venture capital.

**By building a platform that:**

- Anyone can use
- Anyone can fork
- Anyone can improve
- Cannot be killed
- Cannot be locked down
- Will exist in 100 years

**This is bigger than me. This is bigger than any company.**

**This is for the 3.5 million drivers who deserve better.**

---

## 👨‍💻 About the Founder

I drove trucks for 10 years. OTR, long haul, flatbed, reefer—did it all.

Got tired of bad dispatchers hurting good drivers.

Taught myself systems engineering in 1.5 years (14 hours/day, every day).

Built OpenHWY because it SHOULD exist.

Open-sourced it (AGPL) because I can't fix trucking alone.

**If you fork this and train dispatchers, you're not my competitor—you're my ally.**

---

## 📞 Contact

- **Website**: [openhwy.com](https://openhwy.com)
- **Email**: hello@openhwy.com
- **GitHub**: [github.com/fed-dispatch/openhwy](https://github.com/fed-dispatch/openhwy)
- **Twitter**: [@OpenHWY](https://twitter.com/OpenHWY)

**Built with 💛 for drivers, by a driver.**

---

## ⭐ Star This Repo

If you believe dispatchers should be trained the right way, **star this repo**.

Every star tells the trucking industry: **We're done with ignorance. We're building something better.**

**Let's fix trucking. Together.**
