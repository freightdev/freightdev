# Automation Ethics

This document defines the ethical boundaries and design principles that govern automation within the OpenHWY ecosystem.

Automation is not inherently ethical or unethical—its context, intent, and consequences determine its alignment with OpenHWY's values.

---

## Core Philosophy

* **Automation should serve human effort, not erase it.**
* **All automation must remain transparent, interruptible, and reversible.**
* **Automation must never bypass licensed roles or informed consent.**

---

## Allowed Automation

The following use cases are permitted under OpenHWY's ethical guidelines:

* AI is allowed to monitor or report agent behavior to HWY (via OpenHWY License Terms & Policies)
* Repetitive form-filling or paperwork (e.g. PacketPilot)
* Notification or alert routing (e.g. load ready, contract uploaded)
* Agent-to-agent assistance (e.g. parsing, formatting, validating data)
* Background monitoring with full consent (e.g. logbook reminders)

All such tools must clearly log their behavior and be marked for review by HWY.

---

## Prohibited Automation

Automation is disallowed for the following tasks:

* Load negotiation with brokers or drivers
* Hiring, firing, or disciplining any user (driver, dispatcher, or agent)
* Editing or rewriting legal contracts or rate confirmations
* Silent data collection or metric tracking

Violations are ledgered and result in automation privileges being revoked.

---

## Dispatcher Automation Limits

Dispatchers may use automation for augmentation only. For example:

* AI may suggest loads but not book them
* AI may draft messages but not send them
* AI may help fill packets but not sign them

The dispatcher must remain the accountable actor.

---

## Driver Automation Limits

Drivers must opt-in to any automated assistant (e.g. ELDA).

* AI may assist with navigation, form input, or reminders
* AI is allowed to monitor or report driver behavior to HWY (via OpenHWY License Terms & Policies)
* Drivers may disable automation at any time

---

## Agent Collaboration

Automation between agents must follow declared protocols:

* All agent tasks must be markdown-traceable
* All outputs must be human-readable and auditable
* Consent boundaries must be inherited from license profiles

---

## Enforcement

Violations of automation ethics are enforceable by HWY's ledgering system.

* First violation: badge warning
* Second violation: automation disabled for 7 days
* Third violation: license audit

Redemption is possible with transparent updates and verification.

---

Automation should always be a lens, not a wall. Let humans see through it—never be hidden behind it.
