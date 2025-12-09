# 🚛 Wheeler Agents - Complete Collection

## 📦 What's Included

This bundle contains all 6 Wheeler agents for the FED trucking ecosystem:

### 1. **PacketPilot** 📋
*"If it sets the load, PacketPilot handles it."*
- Automated carrier packet handling
- Broker protocol detection (CH Robinson, TQL, Coyote, etc.)
- PDF auto-fill
- Rate confirmation signing
- Email monitoring with CoDriver v0.2

**Location**: `packetpilot_agent/`

---

### 2. **Trucker's Tales** 📖
*"Tell your tale. The road will remember."*
- Voice-to-text storytelling
- Emotion analysis (joy, fear, anger, sadness, pride)
- Story structuring (5-part arc)
- Multi-format export (Markdown, PDF, EPUB, JSON)
- Publishing integration (Owlusive Treasures, OpenHWY Archive)

**Location**: `truckers_tales/`

---

### 3. **CargoConnect** 🔗
*"Connect your own freight. No middleman."*
- Load board aggregator (DAT, Truckstop, 123Loadboard, etc.)
- Secure credential vault (AES-256-GCM encryption)
- Session management
- Smart filtering & preference-based ranking
- No per-load fees

**Location**: `cargoconnect/`

---

### 4. **Whisper Witness** 👂
*"She whispers the truth and witnesses the trap."*
- Broker manipulation detector (14 tactics)
- Real-time conversation analysis
- Whispered warnings during calls
- Conversation summaries with recommendations
- Privacy-first (local processing)

**Location**: `whisperwitness/`

---

### 5. **Big Bear** 🐻
*"The road has eyes. Big Bear sees them all."*
- Road monitoring (law enforcement, weigh stations, accidents, hazards)
- 17 alert types with severity levels
- Crowdsourced verification system
- Geospatial queries (alerts on route, stations on route)
- Anonymous reporting

**Location**: `bigbear/`

---

### 6. **Legal Logger** ⚖️
*"If it happened, he logged it. Legally."*
- **THE FOUNDATION** - Only agent with write access to OpenHWY ledger
- Immutable logging with cryptographic signatures (Ed25519)
- Blockchain-style verification
- 21+ event types for compliance
- Audit trail for disputes

**Location**: `legallogger/`

---

## 🏗️ Tech Stack

**Language**: Rust (all agents)  
**Runtime**: Tokio async  
**Web Framework**: Axum  
**Encryption**: AES-256-GCM, Ed25519  
**Serialization**: Serde JSON  

---

## 🚀 Quick Start

### Extract the Archive

```bash
# Extract complete bundle
tar -xzf wheeler-agents-complete.tar.gz

# Or extract individual agents
tar -xzf packetpilot.tar.gz
tar -xzf truckers-tales.tar.gz
tar -xzf cargoconnect.tar.gz
tar -xzf whisperwitness.tar.gz
tar -xzf bigbear.tar.gz
tar -xzf legallogger.tar.gz
```

### Build an Agent

```bash
cd packetpilot_agent
cargo build --release
cargo run
```

### Run Tests

```bash
cargo test
```

---

## 📊 Agent Integration Flow

```
┌──────────────────────────────────────────┐
│         OPENHWY LEDGER                   │
│       (Immutable Truth)                  │
└──────────────┬───────────────────────────┘
               │
               │ ONLY Legal Logger can write
               │
    ┌──────────▼───────────┐
    │   LEGAL LOGGER ⚖️    │
    │  (Foundation)         │
    └──────────┬────────────┘
               │
               │ All agents log to Legal Logger
               │
    ┌──────────┼──────────────────┐
    │          │                  │
┌───▼────┐ ┌──▼─────┐ ┌─────▼─────┐
│Packet  │ │Big Bear│ │Cargo      │
│Pilot📋 │ │   🐻   │ │Connect 🔗 │
└────────┘ └────────┘ └───────────┘
    │          │                  │
┌───▼────┐ ┌──▼─────┐
│Whisper │ │Tales   │
│Witness │ │   📖   │
└────────┘ └────────┘
```

---

## 🔐 Security Features

### **Legal Logger**
- Ed25519 digital signatures
- SHA-256 content hashing
- Blockchain-style chain verification
- Append-only ledger

### **CargoConnect**
- AES-256-GCM credential encryption
- Never stores plaintext passwords
- Session-based authentication (24hr expiry)
- Per-user credential isolation

### **Whisper Witness**
- Local audio processing
- Encrypted conversation storage
- No audio leaves device without permission
- Explicit consent required

### **Big Bear**
- Anonymous reporting allowed
- Location data auto-expires with alerts
- No personal data storage
- Community verification system

---

## 📖 Documentation

Each agent includes:
- ✅ Complete README with usage examples
- ✅ API specifications
- ✅ Integration guides
- ✅ Privacy policies
- ✅ Roadmap for future features

---

## 🎯 What Each Agent Does

| Agent | Purpose | Revenue Model |
|-------|---------|---------------|
| PacketPilot | Automates carrier packets | $4/packet after 5 free |
| Trucker's Tales | Cultural preservation | Free (storytelling) |
| CargoConnect | Direct load board access | Free (no middleman) |
| Whisper Witness | Protects from manipulation | Free (driver protection) |
| Big Bear | Road intelligence | Free (community safety) |
| Legal Logger | Immutable audit trail | Foundation (compliance) |

---

## 🔮 Roadmap

### Phase 1: Core Complete ✅
- All 6 agents spec'd and implemented
- Mock data for testing
- Comprehensive documentation

### Phase 2: Production Ready
- Real API integrations
- Live data connections
- Dashboard integration
- Mobile app support

### Phase 3: Intelligence
- Machine learning for load matching
- Predictive analytics
- Market trend analysis
- Route optimization

### Phase 4: Ecosystem
- Third-party integrations
- Open API for developers
- Plugin system
- White-label options

---

## 🤝 Integration with FED TMS

All agents integrate seamlessly with the FED TMS platform:

- **PacketPilot**: Handles all carrier paperwork automatically
- **Trucker's Tales**: Preserves driver stories and training data
- **CargoConnect**: Aggregates loads from multiple boards
- **Whisper Witness**: Detects broker manipulation in real-time
- **Big Bear**: Provides road intelligence for route planning
- **Legal Logger**: Logs all actions for compliance and disputes

---

## 📞 Support

For questions or issues:
- Check individual agent README files
- Review API documentation
- See integration guides

---

## ⚖️ License

**Legal Logger**: Proprietary (OpenHWY Foundation)  
**All Others**: Check individual LICENSE files

---

## 🙏 Built With

- ❤️ For truck drivers
- 🔧 By someone who understands the industry
- 🚛 To make trucking better for everyone

---

**"Drivers are the most important and valuable asset in the trucking industry."**

Built with ⚖️ by OpenHWY Foundation
