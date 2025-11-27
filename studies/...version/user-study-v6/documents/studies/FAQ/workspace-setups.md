# How to Use It (no fluff, straight steps)

## 1) Put this script in your repo

```
your-repo/
├─ env-bootstrap.sh
├─ dotfiles/
│  ├─ <your config dirs/files>
│  └─ map.txt        # optional: lines like "nvim  ~/.config/nvim"
├─ tools/
│  └─ <tool-name>/
│     └─ install.sh  # executable; called with --non-interactive
└─ secrets/
   └─ (encrypted .gpg files will live here)
```

* `dotfiles/map.txt` format (whitespace-separated):

```
nvim    ~/.config/nvim
bashrc  ~/.bashrc
kitty   ~/.config/kitty
```

If `map.txt` is missing, directories under `dotfiles/` go to `~/.config/<name>` and files go to `~/.<name>`.

## 2) Make it executable

```bash
chmod +x env-bootstrap.sh
```

## 3) One-line install on a new machine

* If installing from a remote repo:

```bash
GPG_ID="you@example.com" \
REPO_URL="https://github.com/you/your-repo.git" \
REPO_BRANCH="main" \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/you/your-repo/main/env-bootstrap.sh)" -- install
```

* If you already cloned the repo locally:

```bash
GPG_ID="you@example.com" ./env-bootstrap.sh install
```

> If you need to import your private key on a fresh box:

```bash
export GPG_ID="you@example.com"
export GPG_PRIVATE_KEY_FILE="$HOME/.keys/you.asc"
export GPG_PASSPHRASE_FILE="$HOME/.keys/you.pass"   # optional
./env-bootstrap.sh install
```

## 4) Add/lock a secret (so only your GPG key can open it)

```bash
# Encrypt a plaintext file into repo/secrets/*.gpg:
GPG_ID="you@example.com" ./env-bootstrap.sh lock ~/.ssh/id_ed25519
# Commit the .gpg file; delete the plaintext from the repo/workspace.
```

## 5) Update later (pull & re-apply)

```bash
./env-bootstrap.sh update
```

## 6) Uninstall (tracked artifacts only; safe default)

```bash
./env-bootstrap.sh uninstall
```

* If you *also* want to remove packages the installer added:

```bash
PURGE_PACKAGES_ON_UNINSTALL=1 ./env-bootstrap.sh uninstall
```

## 7) Dry-run (show what would happen)

```bash
DRY_RUN=1 ./env-bootstrap.sh install
```
## 8) Quick health check

```bash
./env-bootstrap.sh doctor
```

---

# Notes that matter (still no fluff)

* **Security**: Secrets are kept encrypted as `secrets/*.gpg`. Decryption requires your private key and passphrase. Decrypted copies are tracked and can be shredded on uninstall.
* **Ownership & perms**: Sensitive dirs (`~/.secrets`, `~/.ssh`, `~/.local/bin`) get restrictive permissions.
* **Idempotent**: Re-running `install` or `update` won’t duplicate work. Existing files are backed up into `~/.env-bootstrap/backups/<timestamp>/…`.
* **Manifest-backed uninstall**: We only remove what we installed and tracked.
* **Tools**: Any `tools/*/install.sh` gets executed automatically; ensure they’re non-interactive where possible.

This is a complete, pro-grade baseline. Put it in your repo, wire your dotfiles and installers, and you’ve got a portable, secure “bam—it’s my environment” on any box.
