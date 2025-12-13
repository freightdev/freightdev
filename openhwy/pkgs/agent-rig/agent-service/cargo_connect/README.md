# 🔗 CargoConnect v0.0.1

## **"Connect your own freight. No middleman. No scraping games."**

---

## 🎯 **What This Is**

CargoConnect is **NOT** a load board.

It's a **bridge** to YOUR load boards.

**Your credentials. Your data. Your control.**

CargoConnect securely logs into the load boards YOU already pay for and brings YOUR freight data into YOUR dispatching interface.

**No middleman. No markup. No bullshit.**

---

## 💡 **Why This Exists**

### **The Problem**

You pay for DAT. You pay for Truckstop.com. You pay for 123Loadboard.

But you have to:
- Log in to 5 different sites
- Check each one manually
- Copy/paste loads
- Lose time switching between tabs
- Miss good loads because you didn't check fast enough

**That's stupid.**

### **The Solution**

CargoConnect connects to YOUR accounts and brings ALL your freight to ONE place.

✅ **One interface**  
✅ **All your load boards**  
✅ **Real-time data**  
✅ **Smart filtering**  
✅ **Automatic ranking**  

**Your load board subscriptions. Your data. Better interface.**

---

## 🔐 **Security First**

### **Your Credentials Are Safe**

- ✅ **AES-256 encryption** for stored passwords
- ✅ **Never stored in plaintext** - EVER
- ✅ **Secure vault storage** 
- ✅ **Per-user isolation**
- ✅ **Session management** with auto-expiry
- ✅ **Revoke access anytime**

### **What We DON'T Do**

- ❌ **Share your credentials** with anyone
- ❌ **Store your data** on our servers
- ❌ **Sell your search history**
- ❌ **Track your loads**
- ❌ **Charge per load**

**Your credentials stay encrypted. Your sessions stay private.**

---

## 🚀 **How It Works**

### **1. Connect Your Accounts**

```rust
// Connect to DAT
CargoConnect::connect_account(
    board_type: LoadBoardType::DAT,
    username: "your-dat-username",
    password: "your-dat-password",
)
```

**Supported Load Boards:**

- ✅ **DAT** (dat.com)
- ✅ **Truckstop.com**
- ✅ **123Loadboard** (J1 Freight)
- ✅ **Direct Freight**
- ✅ **Broker Direct** (CH Robinson, TQL, Coyote, etc.)
- ⏳ More coming soon!

### **2. Fetch YOUR Loads**

```rust
// Get loads from ALL connected accounts
let loads = CargoConnect::fetch_loads();

// Or fetch from specific accounts
let loads = CargoConnect::fetch_loads(
    account_ids: vec!["dat-account-id", "truckstop-account-id"]
);
```

**Returns:**
- 📦 All loads from YOUR accounts
- 🔄 Real-time data
- 📊 Standardized format

### **3. Filter Smart**

```rust
let filtered = CargoConnect::apply_filter(
    filter: LoadFilter {
        origin_states: Some(vec!["IL", "IN", "OH"]),
        destination_states: Some(vec!["TX", "OK"]),
        equipment_types: Some(vec!["Dry Van"]),
        min_rate: Some(2000.00),
        min_rate_per_mile: Some(2.00),
        min_distance: Some(500),
        max_distance: Some(1500),
    }
);
```

### **4. Rank Automatically**

```rust
let ranked = CargoConnect::rank_loads(
    loads,
    preferences: ScoringPreferences {
        preferred_lanes: vec![
            Lane {
                origin_state: "IL",
                destination_state: "TX",
                preference_score: 0.9,
            }
        ],
        rate_importance: 0.7,
        distance_importance: 0.5,
        deadhead_penalty: 0.3,
    }
);
```

**Smart ranking considers:**
- 💰 Rate vs market average
- 📏 Distance preferences
- 🛣️ Lane preferences
- 🚛 Equipment match
- ⏰ Pickup timing
- 📍 Deadhead miles

---

## 📊 **Load Data Structure**

Every load comes with complete data:

```rust
FreightLoad {
    // Identification
    id: "load-uuid",
    source_board: LoadBoardType::DAT,
    external_id: "DAT-12345",
    
    // Origin & Destination
    origin_city: "Chicago",
    origin_state: "IL",
    destination_city: "Dallas",
    destination_state: "TX",
    
    // Equipment
    equipment_type: "Dry Van",
    length_feet: 53.0,
    weight_lbs: 42000,
    
    // Financial
    rate: 2450.00,
    rate_per_mile: 2.65,
    distance_miles: 925,
    
    // Details
    commodity: "General Freight",
    broker: "XYZ Logistics",
    contact: "John Smith",
    phone: "+1-555-0100",
    special_requirements: ["Team"],
    
    // Metadata
    posted_at: "2024-12-18T10:30:00Z",
    fetched_at: "2024-12-18T12:45:00Z",
    score: 87.5, // Ranked score
}
```

---

## 🎯 **Use Cases**

### **1. Multi-Board Monitoring**

**Before:** Check 5 sites manually  
**After:** One feed, all boards

### **2. Smart Filtering**

**Before:** Scroll through 1000+ loads  
**After:** See only what matches YOUR criteria

### **3. Lane Preferences**

**Before:** Guess which loads are good  
**After:** Automatically ranked by YOUR preferences

### **4. Real-Time Alerts**

**Before:** Refresh pages every 5 minutes  
**After:** Push notifications for matching loads

### **5. Team Coordination**

**Before:** "Did you check DAT?" "Did you check Truckstop?"  
**After:** Everyone sees the same feed

---

## 🔧 **Technical Details**

### **Architecture**

```
User Interface (FED Dashboard)
        ↓
   CargoConnect
        ↓
┌───────────────────────┐
│  Credential Vault     │ ← AES-256 encrypted
│  Session Manager      │ ← Active sessions
│  Load Fetcher         │ ← Board connectors
│  Filter Engine        │ ← Smart filtering
│  Score Ranker         │ ← Preference-based ranking
└───────────────────────┘
        ↓
┌──────────────────────────────────┐
│  Load Board APIs/Sessions        │
│  - DAT                           │
│  - Truckstop.com                 │
│  - 123Loadboard                  │
│  - Direct Freight                │
│  - Broker Portals                │
└──────────────────────────────────┘
```

### **Security Stack**

- **Encryption**: AES-256-GCM
- **Hashing**: SHA-256
- **Transport**: TLS 1.3
- **Storage**: Encrypted vault
- **Sessions**: Auto-expiring tokens

### **Rate Limiting**

- 60 queries per hour per user
- Automatic throttling
- Respects load board ToS

---

## 📡 **API Endpoints**

### **Connect Account**

```json
POST /api/cargoconnect/connect
{
  "action": {
    "type": "connect_account",
    "board_type": "DAT",
    "username": "your-username",
    "password": "your-password"
  },
  "user_id": "user-123"
}
```

### **Fetch Loads**

```json
POST /api/cargoconnect/fetch
{
  "action": {
    "type": "fetch_loads",
    "account_ids": ["account-1", "account-2"]
  },
  "user_id": "user-123"
}
```

### **Apply Filter**

```json
POST /api/cargoconnect/filter
{
  "action": {
    "type": "apply_filter",
    "filter": {
      "origin_states": ["IL", "IN"],
      "min_rate": 2000,
      "min_rate_per_mile": 2.0
    }
  },
  "user_id": "user-123"
}
```

---

## 🎨 **Example Workflow**

```rust
// 1. Connect accounts (one time)
CargoConnect::connect_account("DAT", "user", "pass");
CargoConnect::connect_account("Truckstop", "user", "pass");

// 2. Fetch loads (every 5 minutes)
let all_loads = CargoConnect::fetch_loads();
// Returns: 247 loads from DAT, 189 from Truckstop

// 3. Apply filter
let filtered = CargoConnect::apply_filter(
    origin_states: ["IL", "IN", "OH"],
    destination_states: ["TX"],
    min_rate: 2000,
);
// Returns: 23 loads matching criteria

// 4. Rank by preferences
let ranked = CargoConnect::rank_loads(filtered, preferences);
// Returns: Sorted by YOUR preferences

// 5. Display top 10
for load in ranked.take(10) {
    display_load(load);
}
```

---

## 💰 **Pricing**

**CargoConnect is FREE.**

You already pay for:
- DAT subscription: $150/month
- Truckstop.com: $120/month
- 123Loadboard: $80/month

**Total: $350/month**

CargoConnect doesn't add to that.  
It just makes your existing subscriptions more useful.

**No per-load fees. No markup. No hidden costs.**

---

## 🚀 **Run It**

### **Build**

```bash
cd cargoconnect
cargo build --release
```

### **Configure**

```env
VAULT_KEY=your-encryption-key-32-bytes-minimum!
```

### **Run**

```bash
cargo run
```

---

## 📊 **Metrics**

CargoConnect tracks:

- ✅ Loads fetched per board
- ✅ Fetch latency
- ✅ Filter performance
- ✅ Ranking effectiveness
- ✅ Session health

**All metrics are private. Never shared.**

---

## 🔒 **Privacy Policy**

### **What We Store**

- ✅ Encrypted credentials
- ✅ Session tokens (temporary)
- ✅ User preferences

### **What We DON'T Store**

- ❌ Plaintext passwords
- ❌ Load search history
- ❌ Broker contact info
- ❌ Your freight data

### **Data Retention**

- **Sessions**: Auto-expire after 24 hours
- **Credentials**: Deleted when you disconnect
- **Logs**: 7 days retention, then purged

---

## ⚠️ **Legal**

### **Terms of Service Compliance**

CargoConnect:
- ✅ Uses official APIs where available
- ✅ Respects rate limits
- ✅ Doesn't automate bookings
- ✅ Doesn't modify load data
- ✅ Doesn't scrape without authentication

**You provide YOUR credentials.**  
**We access YOUR data.**  
**Same as you logging in manually.**

### **Liability**

- CargoConnect is a tool
- You authorize access to YOUR accounts
- Load board subscriptions are YOUR responsibility
- Load data accuracy depends on source boards

---

## 🎯 **Roadmap**

### **Phase 1: Core** ✅
- Multi-board connection
- Secure credential storage
- Load fetching
- Basic filtering

### **Phase 2: Intelligence** ⏳
- Smart ranking
- Lane preferences
- Market rate analysis
- Historical trends

### **Phase 3: Automation** ⏳
- Real-time alerts
- Auto-refresh
- Push notifications
- Slack/email integration

### **Phase 4: Analytics** ⏳
- Load volume trends
- Rate analysis
- Board comparison
- Performance metrics

---

## 💡 **Why This is Better**

### **vs. Manual Checking**

| Manual | CargoConnect |
|--------|--------------|
| Check 5 sites | Check 1 feed |
| 15 minutes | 30 seconds |
| Miss good loads | See everything |
| No filtering | Smart filtering |
| No ranking | Auto-ranked |

### **vs. Load Board Aggregators**

| Aggregators | CargoConnect |
|-------------|--------------|
| $500+/month | FREE |
| Per-load fees | No fees |
| Limited boards | YOUR boards |
| Delayed data | Real-time |
| No control | Full control |

---

## 🙏 **Acknowledgments**

To every dispatcher who has:
- Opened 10 browser tabs to check loads
- Missed a good load because they were on the wrong board
- Paid multiple subscriptions but couldn't use them efficiently
- Wanted their freight data without the middleman

**This is for you.**

---

## 📞 **Support**

Questions? Issues? Suggestions?

- **FED Support**: support@fedispatching.com
- **CargoConnect**: cargoconnect@fedispatching.com
- **GitHub**: github.com/fedispatching/cargoconnect

---

**Built with 🔗 by Fast & Easy Dispatching LLC**

*"Connect your own freight. No middleman. No scraping games."*

---

## 🔥 **Get Started Today**

1. Connect your load board accounts
2. Set your preferences
3. See all your freight in one place
4. Dispatch faster

**Your subscriptions. Your data. Better interface.**

**That's CargoConnect.** 🚛
