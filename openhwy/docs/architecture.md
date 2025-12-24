# Architecture

OpenHWY operates as a modular AI-native freight infrastructure built on a layered model design:

## 🧠 Core AI Models

* **OpenHWY (Master Model)**: Governs and validates all other model actions. Lives at `open-hwy.com`.
* **HWY – Highway Watch Yard**: Ledger/Authority layer. Handles licenses, agent trust, access permissions.
* **FED – Fleet Eco Director**: Dispatcher-side AI. Manages load planning, driver assignments, documents.
* **ECO – Elastic Cargo Orchestrator**: Communicates with brokers/shippers/overseas boards. Works alongside FED.
* **ELDA – Ethical Logistics Driver Assistant**: Only AI model permitted to talk to drivers. Offers safety, training, job help.

---

## 🏗️ Platform Breakdown

### 1. `open-hwy.com`

* Master SDK + Ledger (HWY)
* Hosts licensing, agent verification, training system
* Offers developer SDK for AI tool and agent orchestration
* Runs on **Vite Monorepo + Rust API**

### 2. `fedispatching.com`

* SaaS TMS platform for dispatchers
* Features: Driver CRM, Load Board Sync, PacketPilot, CargoConnect
* AI Access through OpenHWY
* Runs on **Next.js + Solito + Rust API**

### 3. `8teenwheelers.com`

* Driver social network, learning hub
* First ethical load-sharing network
* Driver chat, rate transparency, ELDA training
* Built for community empowerment, not surveillance

---

## 📦 Architecture Layers

```text
+-----------------------------+
|       www websites         |
+-----------------------------+
|       Platform SDKs        |
+-----------------------------+
|       Agent APIs           |
+-----------------------------+
|     Core AI Models         |
+-----------------------------+
|  Memory / Vault / Storage  |
+-----------------------------+
```

* Websites: Public-facing frontend portals (React / Expo / Web)
* Platform SDKs: Interfaces for building apps, training agents, and tooling
* Agent APIs: Expose model abilities, flows, and contracts
* Core AI Models: Each model governs a domain (Dispatching, Driving, Brokering, Oversight)
* Memory/Vault: All persistent knowledge, licensing, documents, model outputs

---

## ⛓️ Communication Rules

* Agents must report up to HWY
* Only ELDA may communicate with drivers
* Only FED (with ECO) may manage broker/shipper interactions
* All models are evaluated by OpenHWY runtime

