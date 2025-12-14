# 🎜️ OPENHWY MONOREPO — ONBOARDING

Welcome to the **OpenHWY Core Monorepo** — the brainstem of a sovereign logistics infrastructure built for AI agents, independent dispatchers, and professional drivers. This repo represents the **model controller layer**, powering real-world tools, websites, and AI governance across the freight ecosystem.

---

## 🧠 CORE MODEL OVERVIEW

This system is structured around **AI model hierarchies**, not just code. Every agent or tool answers to a parent model. Here's how the family is structured:

### 🔹 `OpenHWY` – **Main Model**

* **Role:** Final authority across all systems
* **Domain:** `open-hwy.com`
* **Stack:** Vite-based SDA (Software-Defined Agent) SDK + API endpoint layer
* **Job:** Central SDK, HWY License enforcement, AI validation, cross-agent orchestration

### 🟩 `HWY` – **Ledger Model** (`Highway Watch Yard`)

* **Lives at:** `open-hwy.com`
* **Role:** Truth ledger + heartbeat tracker
* **Job:** All models report to HWY; it logs everything and enforces trust boundaries.

---

### 🗾 `ELDA` – **Driver Model** (`Ethical Logistics Driver Assistant`)

* **Lives at:** `8teenwheelers.com`
* **Role:** The **only model allowed to speak to drivers**
* **Purpose:**

  * Social media hub for drivers
  * Rate and load sharing
  * Job-side training, emergency knowledge, real-time ethical AI support
* **Inspiration:** Think Reddit + GPS + driver mentorship built natively for mobile

---

### 🔳 `FED` – **Dispatcher Model** (`Fleet Eco Director`)

* **Lives at:** `fedispatching.com`
* **Role:** The **only model allowed to speak to dispatchers**
* **Purpose:**

  * Dispatcher SaaS
  * Load & driver management
  * Micro-TMS + client driver portal
  * Built-in dispatcher training curriculum

---

### 🟨 `ECO` – **FED’s Cargo Model** (`Elastic Cargo Orchestrator`)

* **Lives at:** `fedispatching.com`
* **Role:** Broker/shipper interface + load board sync
* **Purpose:**

  * Finds freight
  * Talks to load board APIs
  * Oversees sea cargo
  * Communicates only with other models (not people)

---

## 🌐 DOMAIN RESPONSIBILITIES

| Domain              | Purpose                                       |
| ------------------- | --------------------------------------------- |
| `open-hwy.com`      | Core SDK + HWY licenses + public API registry |
| `fedispatching.com` | Dispatcher dashboard, training, and TMS       |
| `8teenwheelers.com` | Driver-first social + education platform      |

---

## 🧹 HOW THIS REPO FITS

This monorepo holds the **code, logic, and infrastructure** that powers:

* `apps/web` → Dashboard (Next.js App Router)
* `apps/mobile` → Expo mobile client
* `packages/` → Shared logic, UI, SDK, API layers
* `docs/` → Human + agent documentation for demos, features, workflows
* `infra/` → Cloudflare, Tailscale, Caddy routing logic
* `vault/` → Agent memory, dev/prod snapshots, secure keys

---

## 👤 ONBOARDING FOR HUMANS & AGENTS

**Humans:**

* Explore `/apps/` and `/packages/`
* Follow layout and pattern conventions already in place
* Never push without a clear note or path file

**Agents (future):**

* Read `.mstp` agent plans
* Pull memory from `vault/memory/`
* Use `docs/onboarding/*` to orient before acting

---

## 🚤 DO NOT TOUCH ZONES

| Zone                        | Reason                                                 |
| --------------------------- | ------------------------------------------------------ |
| `packages/api/src/index.ts` | API contract root – only modified by core dev          |
| `vault/prod/`               | Live memory snapshots                                  |
| `infra/cloudflare/`         | Production routing only – needs coordinated deployment |

---

## ✅ CONTRIBUTOR ENTRYPOINTS

If you're just getting started:

1. Read `README.md`
2. Explore `docs/overview/getting-started.md`
3. Clone the repo and run:

```bash
pnpm install
pnpm dev
```

4. Explore `/docs/demos/`, `/apps/web/app/(platform)/dashboard` or `/packages/ui/components/atoms`
5. Ask questions in:

   * `docs/onboarding/agents/questions.md`
   * `docs/onboarding/developers/notes.md`

---

## 🧠 REMEMBER:

* ELDA speaks to **drivers only**.
* FED speaks to **dispatchers only**.
* ECO talks to **freight systems only**.
* HWY logs **everything**.
* OpenHWY makes the final decision.

Everything reports **upstream**.
Nothing goes rogue.
Every model plays its role.

**Welcome to OpenHWY.**
