## Ways to Use Your GPG Key

### 1. **Encrypt Messages/Files**
```bash
# Encrypt a file for someone else (you need their public key first)
gpg --encrypt --recipient their-email@example.com filename.txt

# Encrypt for yourself
gpg --encrypt --recipient your-email@example.com filename.txt
```

### 2. **Decrypt Messages/Files**
```bash
gpg --decrypt filename.txt.gpg
```

### 3. **Sign Messages/Files** (proves it came from you)
```bash
# Sign a file
gpg --sign filename.txt

# Create a detached signature (keeps original file separate)
gpg --detach-sign filename.txt

# Sign and encrypt together
gpg --sign --encrypt --recipient their-email@example.com filename.txt
```

### 4. **Sign Git Commits**
```bash
# Configure Git to use your key
git config --global user.signingkey YOUR_KEY_ID
git config --global commit.gpgsign true

# Now all your commits will be signed
git commit -m "My signed commit"
```

### 5. **Sign Emails**
Most email clients (Thunderbird, Outlook, Apple Mail) can integrate with GPG to automatically sign/encrypt emails.

## How Others Know It's Really Your Key

This is the **key distribution problem** - here are the solutions:

### 1. **Key Fingerprints**
Your key has a unique fingerprint. Share this through a different channel:
```bash
gpg --fingerprint your-email@example.com
```
Share this fingerprint on your website, business card, or tell people in person.

### 2. **Key Servers**
Upload your public key to key servers so others can find it:
```bash
# Upload to a keyserver
gpg --send-keys YOUR_KEY_ID

# Others can then download it
gpg --recv-keys YOUR_KEY_ID
```

### 3. **Web of Trust**
- Have people you know in person sign your key
- Sign other people's keys after verifying their identity
- This creates a network of trust

```bash
# Sign someone else's key (after verifying their identity!)
gpg --sign-key their-email@example.com
```

### 4. **Direct Sharing**
Share your public key directly:
```bash
# Export and share via email/website
gpg --armor --export your-email@example.com > my-key.asc
```

### 5. **Social Proof**
- Post your key fingerprint on social media
- Add it to your email signature
- Put it on your website or GitHub profile
- Include it in your business card

## Practical Example Workflow

Let's say you want to send an encrypted message to someone:

1. **Get their public key:**
   ```bash
   gpg --recv-keys THEIR_KEY_ID
   # or import from a file they sent you
   gpg --import their-key.asc
   ```

2. **Verify it's really theirs:**
   ```bash
   gpg --fingerprint their-email@example.com
   ```
   Compare this fingerprint with what they posted publicly or told you in person.

3. **Encrypt and sign your message:**
   ```bash
   gpg --encrypt --sign --recipient their-email@example.com message.txt
   ```

4. **They decrypt it:**
   ```bash
   gpg --decrypt message.txt.gpg
   ```
   GPG automatically verifies your signature too!

## Quick Commands to Remember

```bash
# List your keys
gpg --list-keys
gpg --list-secret-keys

# Show key fingerprint
gpg --fingerprint

# Export public key
gpg --armor --export your-email@example.com

# Import someone's public key
gpg --import their-key.asc

# Encrypt for someone
gpg -e -r their-email@example.com file.txt

# Sign a file
gpg -s file.txt
```

The key thing to remember: **anyone can create a key with your name/email**, so the fingerprint verification step is crucial for security. Always verify fingerprints through a separate, trusted channel!

Want me to show you how to set up any specific use case, like email encryption or Git signing?