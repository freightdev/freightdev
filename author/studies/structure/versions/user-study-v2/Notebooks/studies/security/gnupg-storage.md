## Where Your GPG Data is Stored:

### **Main Directory:**
```bash
~/.gnupg/
```

### **Key Files:**
- **`pubring.kbx`** - Your public keyring (contains public keys)
- **`private-keys-v1.d/`** - Directory containing your private keys
- **`trustdb.gpg`** - Trust database (who you trust)
- **`gpg.conf`** - Configuration file

### **What's in Those Files:**
- Your key ID (`A93F388938C20663`)
- Full fingerprint (`84B6CF87440B1900229E3FCCA93F388938C20663`)
- Your identity info (name, email)
- Key creation/expiration dates
- All imported public keys from others

## You Can See This Info Without Opening Files:

```bash
# List all your keys and their IDs
gpg --list-keys

# List secret keys specifically  
gpg --list-secret-keys

# Show fingerprints
gpg --fingerprint

# Show detailed key info
gpg --list-keys --with-subkey-fingerprints
```

## Important Security Note:
The **private keys** in `private-keys-v1.d/` are what make you "you" in GPG. If someone gets these files + your passphrase, they can impersonate you completely.

## Backup Your GPG Directory:
```bash
# Make a secure backup
tar -czf gnupg-backup.tar.gz ~/.gnupg/
```

So yes - your identifier, fingerprint, and everything about your GPG identity is stored in those `~/.gnupg/` files. GPG reads from there every time you run a command!

The `.asc` file you exported is just a text version of your public key extracted from that keyring for easy sharing.