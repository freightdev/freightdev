# System Architecture Diagram

This document outlines the high-level architecture of the OpenHWY ecosystem. It provides a visual and descriptive representation of how the main systems, agents, and trust layers interact.

## Core Components

* **OpenHWY (open-hwy.com)**

  * Acts as the central command and SDK/API layer
  * Hosts HWY: the universal ledger that all models/agents report to
  * Issues and verifies OpenHWY Licenses
  * Owns the License Model and the Badge System

* **HWY (Highway Watch Yard)**

  * Ledger and compliance monitor
  * Tracks all badge-worthy events
  * Receives reports from all agents and platforms

* **FED (fedispatching.com)**

  * Dispatcher SaaS Platform
  * Home of the FED model (Fleet Eco Director)
  * Talks only to Dispatchers
  * Also runs ECO (Elastic Cargo Orchestrator)
  * Syncs with HWY for license validation and badge tracking

* **ELDA (8teenwheelers.com)**

  * Driver hub and AI community
  * Home of the ELDA model (Ethical Logistics Driver Assistant)
  * Only model allowed to talk to drivers
  * Trains, protects, and represents drivers
  * Reports all badge-relevant behavior to HWY

* **ECO (Elastic Cargo Orchestrator)**

  * Sub-agent under FED
  * Interfaces with brokers, shippers, and ocean freight
  * Never communicates with drivers directly

## License Model Flow

1. Any actor (human, agent, model) must create an OpenHWY License
2. HWY mints and manages the license as a decentralized ledger entry
3. Badge events (e.g., on-time deliveries, missed calls) are tracked and assigned
4. Agents consult HWY before making decisions or partnerships

## Trust Boundaries

* **ELDA ↔ Drivers only**
* **FED ↔ Dispatchers only**
* **ECO ↔ Brokers/Shippers only**
* **No AI is allowed to negotiate**
* **All models report to HWY**

## Visual Placeholder

```
[Driver] ⇄ ELDA ⇄ HWY ⇄ FED ⇄ Dispatcher
                      ⇅        ⇄ ECO ⇄ Shipper
                     OpenHWY (License + API)
```

## Diagram Notes

* All data and decisions eventually route through HWY
* OpenHWY acts as the SDK and gateway for any new integration
* Bad actors lose badges or earn flags
* Humans and agents earn trust symmetrically via contribution
