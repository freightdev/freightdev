Gotcha! You want to **combine compression + tar + encryption with GPG (using your key)** in the best way possible for your workflow.

---

# How to combine `tar + compression + GPG encryption with your key`

---

## 1. General flow

1. Create tar archive (compressed or not) — output to stdout
2. Pipe that output into GPG **encrypting with your public key** (asymmetric encryption)
3. Output encrypted file

---

## 2. Encrypt with **your GPG public key** (so only you or whoever has your private key can decrypt)

---

### Example with **gzip + GPG encrypt**

**Compress and encrypt:**

```bash
tar -czf - ~/...me | gpg --encrypt --recipient your_email@example.com --output ...me-backups-$(date +%Y%m%d).tar.gz.gpg
```

* `--encrypt` — encrypt with public key
* `--recipient your_email@example.com` — specify whose key to use (your GPG key email or ID)
* `--output` — output filename

**Decrypt and decompress:**

```bash
gpg --decrypt ...me-backups-YYYYMMDD.tar.gz.gpg | tar -xzf -
```

---

## 3. Replace gzip with other compressors

Example with **zstd + GPG encrypt**:

**Compress and encrypt:**

```bash
tar --zstd -cf - ~/...me | gpg --encrypt --recipient your_email@example.com --output ...me-backups-$(date +%Y%m%d).tar.zst.gpg
```

**Decrypt and decompress:**

```bash
gpg --decrypt ...me-backups-YYYYMMDD.tar.zst.gpg | tar --zstd -xf -
```

---

## 4. Example for each level from before, with encryption

| Level        | Compression command with encryption | Decompression command                                       |                                    |                    |
| ------------ | ----------------------------------- | ----------------------------------------------------------- | ---------------------------------- | ------------------ |
| 1. lz4       | \`tar --lz4 -cf - \~/...me          | gpg --encrypt --recipient you --output backup.tar.lz4.gpg\` | \`gpg --decrypt backup.tar.lz4.gpg | tar --lz4 -xf -\`  |
| 2. gzip fast | \`GZIP=-1 tar -czf - \~/...me       | gpg --encrypt --recipient you --output backup.tar.gz.gpg\`  | \`gpg --decrypt backup.tar.gz.gpg  | tar -xzf -\`       |
| 3. gzip best | \`GZIP=-9 tar -czf - \~/...me       | gpg --encrypt --recipient you --output backup.tar.gz.gpg\`  | \`gpg --decrypt backup.tar.gz.gpg  | tar -xzf -\`       |
| 4. zstd      | \`tar --zstd -cf - \~/...me         | gpg --encrypt --recipient you --output backup.tar.zst.gpg\` | \`gpg --decrypt backup.tar.zst.gpg | tar --zstd -xf -\` |
| 5. xz        | \`tar -cJf - \~/...me               | gpg --encrypt --recipient you --output backup.tar.xz.gpg\`  | \`gpg --decrypt backup.tar.xz.gpg  | tar -xJf -\`       |

---

## 5. Important notes

* **You must have your public key imported** locally to encrypt.
* When decrypting, GPG will prompt for your **private key passphrase**.
* Using **asymmetric encryption** (public/private key) is the best for backups you want to keep secure.
* If you want to use **symmetric encryption** (passphrase only), replace `--encrypt --recipient` with `--symmetric`.

---

## 6. Symmetric encryption example (if you want passphrase only)

**Compress and encrypt:**

```bash
tar -czf - ~/...me | gpg --symmetric --cipher-algo AES256 --output backup.tar.gz.gpg
```

**Decrypt and decompress:**

```bash
gpg --decrypt backup.tar.gz.gpg | tar -xzf -
```

---

If you want, I can help you write a full **backup script** that does compression + GPG encryption with your key, with options for levels and automation!
