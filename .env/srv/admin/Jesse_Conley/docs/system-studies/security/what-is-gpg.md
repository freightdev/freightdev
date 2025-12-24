## 🧩 What is GPG?

GPG = **GNU Privacy Guard**

It lets you:

* 🔒 **Encrypt** files/messages (only the intended recipient can read them)
* ✍️ **Sign** files/messages (prove you wrote them)
* 🔍 **Verify** signatures (prove someone else wrote something)
* 🔐 **Manage keys** (public/private key pairs for identity & trust)

---

## 🧪 Step-by-Step: Getting Started with GPG

### ✅ 1. Check if it’s installed

```bash
gpg --version
```

If not:

* **Arch Linux**: `sudo pacman -S gnupg`
* **Debian/Ubuntu**: `sudo apt install gnupg`

---

### ✅ 2. Generate your first GPG key

```bash
gpg --full-generate-key
```

You'll be prompted for:

* **Key type** → Choose the default (RSA and RSA)
* **Key size** → 4096 is strong and recommended
* **Expiration** → You can choose "0" for no expiration
* **Name & Email** → Used for identity (used by Git too)
* **Passphrase** → Used to unlock your key

🔐 This generates a **public/private keypair**.

---

### ✅ 3. List your keys

```bash
gpg --list-keys       # shows public keys
gpg --list-secret-keys  # shows private keys
```

You’ll see something like:

```
/home/you/.gnupg/pubring.kbx
---------------------------------
pub   rsa4096 2025-08-07 [SC]
      ABCD1234EFGH5678...
uid           [ultimate] Jesse Conley <jesse@example.com>
```

That long string (e.g. `ABCD1234...`) is your **key ID or fingerprint**.

---

### ✅ 4. Use your key to sign a file

```bash
echo "hello world" > message.txt
gpg --sign message.txt
```

It creates `message.txt.gpg` (binary format) or `message.txt.sig` if using `--detach-sign`.

You can also do:

```bash
gpg --clearsign message.txt
```

This signs the message in a readable format.

---

### ✅ 5. Encrypt a message for someone

If you have their **public key**:

```bash
gpg --encrypt --recipient someone@example.com secret.txt
```

Only they (with the matching **private key**) can decrypt it.

---

### ✅ 6. Decrypt a message

```bash
gpg --decrypt secret.txt.gpg
```

If the file was encrypted **to you**, GPG will ask for your passphrase and show the message.

---

### ✅ 7. Export your public key (for others to trust)

```bash
gpg --armor --export your@email.com
```

That outputs your public key in readable form so you can share it (e.g. on GitHub, keyservers, etc.)

---

## 🚀 What You Can Do With GPG

* 🔐 Secure messages with anyone using public keys
* ✅ Sign Git commits to prove authorship (`git config --global commit.gpgsign true`)
* 📦 Sign software releases (common in open source)
* 🧾 Verify downloaded packages (`gpg --verify file.sig`)
* 🔄 Use with `pass`, `git-crypt`, `age-plugin-gpg`, and other tools
