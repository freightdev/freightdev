## Installation

First, you'll need to install GPG:

**On Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install gnupg
```

**On macOS:**
```bash
brew install gnupg
```

**On Windows:**
Download and install GPG4Win from https://www.gpg4win.org/

## Creating Your First GPG Key

1. **Start the key generation process:**
   ```bash
   gpg --full-generate-key
   ```

2. **Choose the key type:**
   You'll be prompted to select what kind of key you want. For most users, choose option 1 (RSA and RSA) by pressing Enter.

3. **Set the key size:**
   When asked for keysize, choose 4096 bits for better security (type `4096` and press Enter).

4. **Set expiration:**
   Choose how long the key should be valid. For beginners, `0` (never expires) is fine, but setting an expiration like `1y` (1 year) is more secure practice.

5. **Provide your information:**
   - **Real name:** Enter your full name
   - **Email address:** Use an email you actually check
   - **Comment:** Optional description (you can leave blank)

6. **Create a passphrase:**
   Choose a strong passphrase to protect your private key. This is crucial - without it, anyone with access to your key file could impersonate you.

## Verification

After creation, verify your key was generated:
```bash
gpg --list-keys
```

You should see your new key listed with your name and email.

## Export Your Public Key

To share your public key with others:
```bash
gpg --armor --export your-email@example.com > my-public-key.asc
```

## Important Security Notes

- **Back up your keys:** Store a secure backup of your entire `.gnupg` directory
- **Keep your private key safe:** Never share your private key
- **Remember your passphrase:** Without it, your key is useless
- **Consider key servers:** You can upload your public key to keyservers so others can find it

## Quick Test

To test your key works, try signing a simple message:
```bash
echo "Hello, GPG!" | gpg --clearsign
```

This creates a signed version of your message that others can verify came from you.