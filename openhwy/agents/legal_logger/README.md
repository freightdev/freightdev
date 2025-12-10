# ⚖️ Legal Logger v0.0.1

## **"If it happened, he logged it. Legally."**

---

## 🎯 **What This Is**

Legal Logger is THE authoritative logging system for the Wheeler ecosystem.

He is the **ONLY agent** with write access to the OpenHWY ledger.

**His job is simple:**
1. Log what he's told to log
2. Sign it cryptographically
3. Store it immutably
4. Retrieve it on request

**That's it. Nothing more. Nothing less.**

---

## ⚠️ **Critical Principle: He Does NOT**

Legal Logger does **NOT**:
- ❌ Infer what to log
- ❌ Analyze content
- ❌ Make judgments
- ❌ Alter entries
- ❌ Delete anything
- ❌ Redact history

Legal Logger **ONLY**:
- ✅ Logs what agents tell him to log
- ✅ Signs everything with Ed25519
- ✅ Stores in append-only ledger
- ✅ Provides cryptographic proof
- ✅ Enables verification

**The ledger is immutable. Once written, it's permanent.**

---

## 📜 **The Ledger Architecture**

```
┌─────────────────────────────────────────────┐
│         OPENHWY IMMUTABLE LEDGER            │
├─────────────────────────────────────────────┤
│                                             │
│  Entry #1 ──→ Hash ──→ Signature           │
│       ↓                                     │
│  Entry #2 ──→ Hash ──→ Signature           │
│       ↓                                     │
│  Entry #3 ──→ Hash ──→ Signature           │
│       ↓                                     │
│  Entry #N ──→ Hash ──→ Signature           │
│                                             │
│  Each entry contains hash of previous       │
│  = Blockchain-style verification            │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 🔐 **Cryptographic Guarantees**

### **SHA-256 Content Hashing**
Every entry is hashed:
```
Content Hash = SHA256(
    entry_number +
    source_agent +
    event_type +
    event_data +
    timestamp +
    previous_hash
)
```

### **Ed25519 Digital Signatures**
Every entry is signed:
```
Signature = Sign(Content_Hash, Private_Key)
Verify = Verify(Content_Hash, Signature, Public_Key)
```

### **Chain Verification**
Each entry links to previous:
```
Entry[N].previous_hash == Entry[N-1].content_hash
```

**Result: Tamper-evident, cryptographically verifiable, immutable ledger**

---

## 📊 **What Gets Logged**

### **21 Event Types**

#### **Agent Actions**
- `AgentStarted` - Agent initialized
- `AgentStopped` - Agent shutdown
- `AgentAction` - Agent performed action
- `AgentError` - Agent error occurred

#### **User Actions**
- `UserLogin` - User logged in
- `UserLogout` - User logged out
- `UserAction` - User took action

#### **System Events**
- `SystemEvent` - System-level event
- `ConfigChange` - Configuration modified
- `SecurityEvent` - Security-related event

#### **Business Events**
- `LoadBooked` - Load was booked
- `LoadDelivered` - Load delivered
- `PaymentReceived` - Payment received
- `PaymentSent` - Payment sent
- `DocumentSigned` - Document signed

#### **Compliance**
- `DOTInspection` - DOT inspection occurred
- `HoursOfService` - HOS event
- `SafetyIncident` - Safety incident

#### **Legal**
- `ContractSigned` - Contract executed
- `DisputeFiled` - Dispute initiated
- `DisputeResolved` - Dispute resolved

#### **Audit**
- `AuditTrail` - Audit trail entry
- `DataAccess` - Data accessed
- `DataModification` - Data modified

#### **Communication**
- `MessageSent` - Message sent
- `MessageReceived` - Message received
- `CallRecorded` - Call recorded

#### **Custom**
- `Custom(String)` - Custom event type

---

## 🚀 **Usage Examples**

### **Log an Event**

```rust
let request = LogRequest {
    source_agent: "PacketPilot".to_string(),
    user_id: Some("driver-001".to_string()),
    session_id: Some(session_id),
    event_type: EventType::DocumentSigned,
    event_data: serde_json::json!({
        "document_type": "rate_confirmation",
        "broker": "XYZ Logistics",
        "rate": 2450.00,
        "load_id": "LOAD-12345"
    }),
    description: "Driver signed rate confirmation".to_string(),
    tags: vec!["signature", "rate_con"],
    metadata: Some(serde_json::json!({
        "ip_address": "192.168.1.100"
    })),
    encrypt: false,
};

let response = legal_logger.log_event(request).await?;
```

**Response:**
```json
{
  "success": true,
  "entry_id": "550e8400-e29b-41d4-a716-446655440000",
  "entry_number": 42,
  "timestamp": "2024-12-18T10:30:00Z",
  "signature": "base64-encoded-signature"
}
```

---

### **Retrieve an Entry**

```rust
let entry = legal_logger.get_entry(entry_id).await?;

println!("Entry #{}: {}", entry.entry_number, entry.description);
println!("Signed by: {}", entry.source_agent);
println!("Hash: {}", entry.content_hash);
println!("Signature: {}", entry.signature);
```

---

### **Query Logs**

```rust
// Get all logs for a user
let logs = legal_logger.get_user_history("driver-001", 100).await?;

// Get all logs from an agent
let logs = legal_logger.get_agent_logs("PacketPilot", 50).await?;

// Custom query
let query = LogQuery {
    user_id: Some("driver-001".to_string()),
    event_type: Some(EventType::DocumentSigned),
    start_time: Some(last_week),
    limit: Some(10),
    ..Default::default()
};

let logs = legal_logger.query_entries(query).await?;
```

---

### **Verify an Entry**

```rust
let verified = legal_logger.verify_entry(entry_id).await?;

if verified {
    println!("✅ Entry verified - authentic and unmodified");
} else {
    println!("❌ Entry verification FAILED - tampering detected");
}
```

---

### **Verify the Chain**

```rust
// Verify entries 1-100 form valid chain
let chain_valid = legal_logger.verify_chain(1, 100).await?;

if chain_valid {
    println!("✅ Chain integrity verified");
} else {
    println!("❌ Chain broken - tampering detected");
}
```

---

## 🔒 **Security Features**

### **Encryption** (Optional)

```rust
LogRequest {
    encrypt: true,  // Event data will be AES-256 encrypted
    // ...
}
```

Encrypted data is only readable by Legal Logger with the encryption key.

### **Signatures** (Always)

Every entry is signed with Ed25519:
- 256-bit security
- Quantum-resistant
- Fast verification

### **Immutability**

Once written:
- Cannot be modified
- Cannot be deleted
- Cannot be reordered

**The ledger is append-only. History is permanent.**

---

## 📈 **Log Entry Structure**

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "entry_number": 42,
  "source_agent": "PacketPilot",
  "user_id": "driver-001",
  "session_id": "session-xyz",
  "event_type": "DocumentSigned",
  "event_data": {
    "document_type": "rate_confirmation",
    "broker": "XYZ Logistics",
    "rate": 2450.00
  },
  "description": "Driver signed rate confirmation",
  "tags": ["signature", "rate_con"],
  "metadata": {},
  "timestamp": "2024-12-18T10:30:00Z",
  "timezone": "UTC",
  "content_hash": "a1b2c3...",
  "signature": "d4e5f6...",
  "previous_hash": "g7h8i9...",
  "encrypted": false,
  "verified": true,
  "immutable": true
}
```

---

## ⚖️ **Legal & Compliance**

### **What Legal Logger Enables**

✅ **Audit Trails** - Complete history of all actions  
✅ **Compliance** - DOT, FMCSA, regulatory requirements  
✅ **Dispute Resolution** - Cryptographic proof of events  
✅ **Chain of Custody** - Who did what, when  
✅ **Non-repudiation** - Signed records can't be denied  

### **Consent & Authorization**

Legal Logger only logs:
- Events agents are authorized to log
- Data users have consented to record
- Activities within scope of service

**No unauthorized logging. Ever.**

### **Data Retention**

- Logs retained per legal requirements
- Minimum: 90 days
- Default: 7 years (IRS, DOT standards)
- Can be configured per compliance needs

---

## 🎯 **Integration Examples**

### **PacketPilot Logs Signature**

```rust
legal_logger.log_event(LogRequest {
    source_agent: "PacketPilot",
    event_type: EventType::DocumentSigned,
    event_data: packet_data,
    description: "Carrier packet signed",
    // ...
}).await?;
```

### **Big Bear Logs Report**

```rust
legal_logger.log_event(LogRequest {
    source_agent: "BigBear",
    event_type: EventType::UserAction,
    event_data: report_data,
    description: "Driver reported bear sighting",
    // ...
}).await?;
```

### **CargoConnect Logs Auth**

```rust
legal_logger.log_event(LogRequest {
    source_agent: "CargoConnect",
    event_type: EventType::UserLogin,
    event_data: auth_data,
    description: "User connected load board account",
    // ...
}).await?;
```

---

## 📊 **Statistics**

```rust
let stats = legal_logger.get_stats().await;

println!("Total Entries: {}", stats.total_entries);
println!("Ledger Size: {} MB", stats.ledger_size_bytes / 1_000_000);
```

---

## 🔮 **Future Features**

### **Phase 2: Distributed Ledger**
- IPFS storage
- Multi-node replication
- Consensus mechanisms

### **Phase 3: Smart Contracts**
- Automated verification
- Conditional logging
- Dispute resolution protocols

### **Phase 4: Advanced Crypto**
- Zero-knowledge proofs
- Homomorphic encryption
- Multi-party computation

---

## 🙏 **The Foundation**

Legal Logger is the foundation of trust in the Wheeler ecosystem.

Every other agent depends on him:
- PacketPilot logs signatures
- Big Bear logs reports
- Whisper Witness logs detections
- CargoConnect logs connections

**Without Legal Logger, there's no proof.**  
**With Legal Logger, there's permanent truth.**

---

## ⚖️ **The Oath**

Legal Logger takes an oath:

*"I log what I'm told to log.  
I sign what I log.  
I store it immutably.  
I never alter history.  
I am the keeper of truth."*

---

**Built with ⚖️ by OpenHWY Foundation**

*"If it happened, he logged it. Legally."*

The ledger is permanent. The signatures are proof. The truth is immutable.
