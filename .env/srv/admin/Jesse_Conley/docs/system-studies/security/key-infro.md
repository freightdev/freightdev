## Your Key Information:
- **Full Fingerprint:** `84B6CF87440B1900229E3FCCA93F388938C20663`
- **Long Key ID:** `A93F388938C20663`
- **Email:** `jesse.freightdev@gmail.com`

## Practical Commands for Your Key:

### Upload to Keyserver:
```bash
gpg --send-keys A93F388938C20663
```

### Export Your Public Key:
```bash
gpg --armor --export A93F388938C20663 > jesse-public-key.asc
```

### Configure Git Signing:
```bash
git config --global user.signingkey A93F388938C20663
git config --global commit.gpgsign true
```

### Show Your Fingerprint (for sharing with others):
```bash
gpg --fingerprint A93F388938C20663
```

## Using Email Address (Easier):
You can also use your email for most commands:
```bash
# These work the same way:
gpg --send-keys jesse.freightdev@gmail.com
gpg --armor --export jesse.freightdev@gmail.com
git config --global user.signingkey jesse.freightdev@gmail.com
```

## Important Notes About Your Key:
- Your key expires on **2026-08-07** (good security practice!)
- You have both signing/certification (`[SC]`) and encryption (`[E]`) capabilities
- The `[ultimate]` trust level means it's your own key

Want to try uploading it to a keyserver or setting up Git signing? Just use `A93F388938C20663` as your key ID in any of the commands!