## The 3-2-1 Rule Breakdown:

### **3** - Keep 3 Copies of Important Data
- **1 original** (your working files)
- **2 backup copies** (separate from the original)

### **2** - Store Backups on 2 Different Media Types
Examples:
- Hard drive + cloud storage
- External SSD + DVD/Blu-ray
- Local NAS + external USB drive
- Cloud service A + cloud service B

### **1** - Keep 1 Copy Offsite
- Different physical location from your computer
- Cloud storage counts as offsite
- External drive at a friend's house
- Safety deposit box
- Different building/city

## Real-World Example for Your GPG Keys:

### **Copy 1 (Original):**
```bash
~/.gnupg/ on your main computer
```

### **Copy 2 (Local Backup):**
```bash
tar -czf gnupg-backup.tar.gz ~/.gnupg/
# Store on external USB drive
```

### **Copy 3 (Offsite):**
```bash
# Upload encrypted backup to cloud
gpg --symmetric --cipher-algo AES256 gnupg-backup.tar.gz
# Upload gnupg-backup.tar.gz.gpg to Google Drive/Dropbox/etc
```

## Why This Rule Works:

**Protects Against:**
- **Hardware failure** (drive crashes)
- **Theft/loss** (laptop stolen)
- **Natural disasters** (fire, flood, earthquake)
- **Ransomware** (encrypts local files)
- **Accidental deletion** (oops, wrong rm command)
- **Corruption** (one backup goes bad)

## Common Mistakes:
- ❌ Two copies on same computer (both lost if drive fails)
- ❌ Backup drive always connected (ransomware hits both)
- ❌ All copies in same building (fire/flood gets all)
- ❌ Only cloud backups (account gets hacked/deleted)

The 3-2-1 rule ensures that even if 2 of your 3 copies are destroyed, you still have your data!