# 🐻 Big Bear - The Road Watcher

## "The road has eyes. Big Bear sees them all."

Big Bear is a passive road monitoring agent that watches:
- 🚓 Law enforcement & speed traps  
- ⚖️ Weigh station status (OPEN/CLOSED)
- 💥 Accidents & traffic incidents
- 🚧 Hazards & construction
- 🅿️ Truck parking availability

## 17 Alert Types

### Law Enforcement
- Bear Sighting 🚓
- Speed Trap 📡  
- DOT Inspection 🔍

### Weigh Stations
- Scale Open ⚖️
- Scale Closed ✅

### Hazards
- Accident 💥
- Road Closure 🚧
- Construction 👷
- Weather Hazard ⚠️
- Debris 🪨

### Traffic  
- Heavy Traffic 🐌
- Slowdown ⏰
- Backup 🚗🚗🚗

### Services
- Parking Available 🅿️
- Parking Full 🚫
- Fuel Price ⛽
- Rest Area 🛏️

## How It Works

1. **Community Reports** - Drivers submit real-time sightings
2. **Verification** - Multiple reports increase confidence
3. **Expiration** - Old alerts automatically expire
4. **Dashboard** - Live view of all active alerts

## Usage

```rust
// Submit a report
big_bear.submit_report(UserReport {
    alert_type: AlertType::BearSighting,
    location: GeoLocation {
        road: "I-80",
        mile_marker: 155.5,
        direction: "Eastbound",
    },
    description: "State trooper with radar",
}).await?;

// Check your route
let alerts = big_bear.get_alerts_on_route(my_route, 10.0).await;
```

## Privacy

- Anonymous reporting allowed
- No personal data stored
- Alerts expire automatically
- Location data deleted with alerts

## Built by Fast & Easy Dispatching LLC

Stay safe. Stay informed. 🐻
