# OpenHWY Terminology Reference

### Core Systems

* **OpenHWY** – Main orchestration and API platform. Hosts the agent runtime and controls ledger logic.
* **HWY** – Short for *Highway Watch Yard*. Acts as the ledger overseer and authority. Every agent, tool, and model reports to HWY.
* **ELDA** – *Ethical Logistics Driver Assistant*. AI guardian for drivers. Only system allowed to interface directly with drivers.
* **FED** – *Fleet Eco Director*. AI dispatcher platform. Only system allowed to communicate with dispatchers.
* **ECO** – *Elastic Cargo Orchestrator*. Sidecar to FED that handles broker/shipper/cargo communications.

### File Types

* `*.mstp` – Markdown Storytelling Pathfinder: defines an agent's complete path, including all `.mark`, `.marker`, and `.rib` references.
* `*.mark` – A single executable tool, pointer, or task.
* `*.marker` – A connected flow of `.mark` steps (like a pipeline).
* `*.rib` – Cached output or execution trail of a `.marker` flow.
* `*.md(x)` – Documentation, stories, or context files.

### Platforms

* `open-hwy.com` – Official site and SDK/API platform. Hosts HWY and agent logic.
* `fedispatching.com` – SaaS platform for dispatchers. Home of FED + ECO.
* `8teenwheelers.com` – Community and safety hub for drivers. Home of ELDA.

### Philosophical Terms

* **“Build the system before the system builds us.”** – Core belief that we must shape AI infrastructure with ethics and transparency before it’s done to us.
* **“The road remembers.”** – An expression of accountability; actions are logged, visible, and owned across all platforms.

### Community Roles

* **Driver** – End-user of freight transport, interfacing through ELDA.
* **Dispatcher** – Coordinator of freight movement, interfacing through FED.
* **Broker/Shipper** – External stakeholders interfaced with via ECO.
* **Agent** – Any autonomous system executing tasks through MARK and the OpenHWY runtime.

This list evolves with the platform.
