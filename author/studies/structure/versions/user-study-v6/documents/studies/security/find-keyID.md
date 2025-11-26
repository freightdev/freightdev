## Finding Your Key ID

### 1. **List your keys to see the ID:**
```bash
gpg --list-keys
```

You'll see output like:
```
pub   rsa4096 2024-08-07 [SC]
      1234567890ABCDEF1234567890ABCDEF12345678
uid           [ultimate] Your Name <your-email@example.com>
sub   rsa4096 2024-08-07 [E]
```

### 2. **Get just the key IDs:**
```bash
gpg --list-keys --keyid-format LONG
```

## Different Ways to Specify Your Key

You can use any of these formats:

### 1. **Full Fingerprint** (most secure):
```bash
gpg --send-keys 1234567890ABCDEF1234567890ABCDEF12345678
```

### 2. **Long Key ID** (last 16 characters):
```bash
gpg --send-keys 90ABCDEF12345678
```

### 3. **Short Key ID** (last 8 characters):
```bash
gpg --send-keys 12345678
```

### 4. **Email Address**:
```bash
gpg --send-keys your-email@example.com
```

### 5. **Name**:
```bash
gpg --send-keys "Your Name"
```

## Quick Way to Get Your Key ID

Run this command to get just your key ID:
```bash
gpg --list-secret-keys --keyid-format LONG | grep sec
```

Or this one-liner to get the full fingerprint:
```bash
gpg --list-keys --fingerprint | grep -A 1 "pub"
```

## Examples with Real Commands

Let's say your key ID is `ABC123DEF456789`:

```bash
# Upload to keyserver
gpg --send-keys ABC123DEF456789

# Configure Git signing
git config --global user.signingkey ABC123DEF456789

# Export your public key
gpg --armor --export ABC123DEF456789
```

## Pro Tip: Use Email for Simplicity

For most commands, using your email address is easiest:
```bash
# These all do the same thing:
gpg --send-keys your-email@example.com
gpg --armor --export your-email@example.com
git config --global user.signingkey your-email@example.com
```

## Security Note

- **Long Key ID or fingerprint** = more secure (recommended for keyservers)
- **Email address** = convenient for daily use
- **Short Key ID** = avoid this, it's not unique enough

The email method works great for most everyday tasks, but use the full fingerprint when security matters most!