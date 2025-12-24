Nice — you’re asking for the *real* professional approach: create an ephemeral, namespaced execution environment on someone else’s machine (no Docker unless you want it), run everything inside that, and be able to completely remove it afterward. Below I give:

* a short architecture overview and threat/consent model,
* the practical options (containerd/nerdctl rootless, systemd-nspawn, user namespaces with `unshare`, and lightweight sandboxes like `bubblewrap`),
* concrete commands & small scripts you can run to create fully namespaced, easily-cleaned-up sessions, and
* hard security caveats + cleanup tips.

I also cite primary docs and good references so you can dig deeper. ([rootlesscontaine.rs][1], [GitHub][2], [ArchWiki][3], [blog.quarkslab.com][4])

---

# 1) High-level approach & threat model (short)

Goal: run your work inside a strongly-isolated environment such that:

* processes have separate PID/IPC/NET/MNT/UTS/user namespaces,
* any mounts you make are confined to that namespace,
* resource control via cgroups (if required),
* everything you bring can be removed when the container/sandbox exits,
* your private keys never leak to the host disk unless you explicitly write them there.

Rules:

* Always get explicit owner consent before modifying system services or installing runtimes.
* Prefer **rootless** techniques (user namespaces, rootless containerd/nerdctl, bubblewrap, tmate) — they lower blast radius. ([rootlesscontaine.rs][1], [GitHub][5])

---

# 2) Options (tradeoffs + when to use)

1. **containerd + nerdctl (rootless)** — closest to “real containerd” and production container behavior. Use when you need full OCI runtime, image pulls, and consistent container lifecycle. Requires installing containerd rootless mode and `nerdctl`. Good for reproducible environments. ([GitHub][2], [rootlesscontaine.rs][1])

2. **systemd-nspawn** — “chroot on steroids.” Useful when you can prepare a minimal rootfs and need stronger isolation than chroot but simpler than full OCI. Requires systemd and often root or delegated privileges. Great for running whole distros as lightweight containers. ([ArchWiki][3])

3. **unshare + pivot\_root / mount + prog + mount --bind** — lowest-level approach: manually create user/pid/mount/net namespaces with `unshare`. Extremely flexible and useful for doing one-shot isolations without installing container runtimes. Good for quick ephemeral sandboxes. See example below. ([blog.quarkslab.com][4], [Red Hat][6])

4. **bubblewrap (bwrap)** or **Firejail** — lightweight, unprivileged sandboxing that builds a namespaced environment with sane defaults. Best when you want to sandbox a single program quickly, with less complexity. But be aware of caveats/escape vectors; don’t assume perfect confinement. ([GitHub][5], [Julia Evans][7])

---

# 3) Practical examples — commands and minimal scripts

Below are ready-to-run examples you can adapt. Each example assumes you run it on the *target machine* (owner must consent).

### A — Quick, low-level ephemeral namespace using `unshare`

This creates new user, mount, PID, network, IPC namespaces, gives you a PID=1 shell inside, mounts `/proc`, binds a working folder, and isolates mounts.

```bash
# create an isolated shell (non-root-friendly if user namespaces disallowed)
sudo unshare --fork --pid --mount --uts --net --ipc --user --map-root-user \
  bash -c '
    set -e
    # mount a private /proc in the new PID namespace
    mount -t proc proc /proc
    # bind your workspace into the namespace (read-only or read-write)
    mkdir -p /tmp/work
    mount --bind /home/you/your-work /tmp/work
    cd /tmp/work
    echo "Inside namespaced shell: PID $$ (PID 1 inside new namespace is the shell parent)."
    exec bash
  '
```

Notes:

* `--map-root-user` maps your unprivileged user to root in the user namespace, letting you do mounts inside the user namespace. Not all kernels/configurations allow user namespaces. See `unshare` docs. ([blog.quarkslab.com][4], [Unix & Linux Stack Exchange][8])
* To exit and clean up, just `exit` the shell — mounts and the PID namespace go away with the process. If you created bind mounts, they unmount automatically when the namespace ends (but sometimes you must explicitly `umount` if they persist).

---

### B — Bubblewrap (recommended for single-process sandboxes)

`bwrap` is widely used by Flatpak. It’s rootless and builds a fresh namespace quickly:

```bash
# example: run bash in a sandbox with only /usr and a project dir visible
bwrap \
  --ro-bind /usr /usr \
  --dev /dev \
  --proc /proc \
  --tmpfs /tmp \
  --bind /home/you/your-project /home/sandbox/project \
  --unshare-all \
  --chdir /home/sandbox/project \
  /bin/bash --login
```

Benefits:

* Quick, zero-dependency for untrusted code.
* You can add `--bind` for any host paths you want visible.
  Caveats:
* Bubblewrap uses user namespaces and a temporary CAP\_SYS\_ADMIN inside the namespace which increases kernel attack surface; not perfect confinement. Read warnings in the project docs. ([GitHub][5], [Julia Evans][7])

---

### C — systemd-nspawn (if systemd available and you have a minimal rootfs)

Good when you need a full distro-like environment with controlled networking:

```bash
# Create a minimal rootfs or use debootstrap/arch-bootstrap, then:
sudo debootstrap --variant=minbase focal /srv/container-root http://archive.ubuntu.com/ubuntu
# Run nspawn with private network and machine name:
sudo systemd-nspawn -D /srv/container-root --private-network --machine=mywork
# You now have a container shell; ctrl+d / exit to stop.
```

`systemd-nspawn` sets up namespaces and a PID1 inside your container and handles a lot of complexity for you. ([ArchWiki][3])

---

### D — containerd + nerdctl (production-like rootless containers)

If you want containerd specifically (not Docker), use rootless containerd + nerdctl. On many distros you can install the rootless setuptool and run containers as a non-root user.

Quick steps (conceptual; follow project docs for full setup):

```bash
# Install containerd rootless helper (on the target, requires network & tooling)
curl -fsSL https://raw.githubusercontent.com/containerd/containerd/main/contrib/rootless/README.md -o /tmp/rootless.md
# Use the rootless setuptool (exists in containerd docs)
containerd-rootless-setuptool.sh install

# install nerdctl (CLI) if available, then run a container:
nerdctl run --rm -it -v /home/you/your-project:/work --workdir /work alpine sh
```

Notes:

* Rootless containerd works via user/systemd user units; it’s the closest to production container behavior without requiring root. See the rootless docs for setup and limitations. ([rootlesscontaine.rs][1], [GitHub][2])

---

# 4) Controlling what the host sees (mounts, keys, secrets)

* **Never copy private keys to the host disk**. Instead:

  * Use **SSH agent forwarding** to authenticate to other hosts from inside your sandbox (you’ll need to forward the agent into the sandbox; with `ssh -A` when you connect).
  * Or **mount your SSH socket** into the sandbox (bind `/run/user/$UID/ssh-agent.socket` or `~/.gnupg/S.gpg-agent`), but only if the host allows it and you trust it.
* **Mount only what you need** and prefer `--ro-bind` for host-sensitive directories.
* **Decrypt secrets only in-memory** or inside the sandbox where they will be destroyed afterwards; track and shred files after use.
* **Make your sandbox’s home a separate tempdir** so the sandboxed apps can’t touch the host home unless you explicitly bind it.

Example bubblewrap showing restricted home and bind only project and SSH agent socket:

```bash
bwrap \
  --ro-bind /usr /usr \
  --dev /dev \
  --proc /proc \
  --tmpfs /tmp \
  --bind /home/you/your-project /home/sandbox/project \
  --ro-bind /run/user/1000/ssh-agent.sock /run/user/1000/ssh-agent.sock \
  --setenv SSH_AUTH_SOCK /run/user/1000/ssh-agent.sock \
  --unshare-all \
  --chdir /home/sandbox/project \
  /bin/bash --login
```

---

# 5) Resource control & cgroups

* If you need CPU/memory limits you should use cgroup v2 and either:

  * use `systemd-run --scope -p MemoryMax=...` when launching a process (if systemd is present), or
  * use `nerdctl run --memory`/`--cpus` to set limits in containerd.
* Rootless setups may have limitations on cgroup manipulation; delegation is required or use features of the container runtime. See containerd rootless docs. ([rootlesscontaine.rs][1])

---

# 6) Cleanup & auditability

Always instrument your sandbox creation so you can destroy and audit:

* **Manifest**: create a JSON/TXT manifest (timestamped) of:

  * mounts you created,
  * bind mounts paths,
  * processes PIDs (from `ps` inside the namespace),
  * files written (capture checksums).
* **Cleanup script**: call `umount -l` or `fusermount -uz` as necessary and kill the namespace processes (PID 1 inside the namespace).
* Example quick cleanup (for unshare or bwrap): killing the top-level shell or `pkill -f` the command; check `lsns` and `ps -eo pid,cmd | grep <marker>` to find related processes. Use `nsenter` or `ip netns` to inspect namespaces. See `lsns`/`nsenter` docs for diagnostics. ([blog.quarkslab.com][4])

---

# 7) Quick script: ephemeral namespaced workspace (production-minded)

Drop this script on the target (owner runs it). It creates a disposable namespace and writes a manifest for cleanup.

```bash
#!/usr/bin/env bash
set -euo pipefail
WORKDIR="${1:-$HOME/your-project}"
MANIFEST="/tmp/namespaced-manifest-$(date +%s).json"

sudo unshare --fork --pid --mount --uts --ipc --net --user --map-root-user \
  bash -c "
    set -e
    mkdir -p /proc
    mount -t proc proc /proc
    mkdir -p /tmp/work
    mount --bind $WORKDIR /tmp/work
    echo '{' > ${MANIFEST}
    echo '  \"started_at\": \"'\"\$(date -Iseconds)\"'\",' >> ${MANIFEST}
    echo '  \"workdir\": \"/tmp/work\"' >> ${MANIFEST}
    echo '}' >> ${MANIFEST}
    cd /tmp/work
    echo 'Namespaced shell ready (exit to destroy). Manifest: ${MANIFEST}'
    exec bash
  "
```

Notes:

* The manifest is created inside the *new namespace* and will be deleted when the namespace ends — you can `bind`-mount `/tmp` to a host path if you want the manifest to persist for audit.

---

# 8) Security caveats & kernel realities (must-read)

* **User namespaces are powerful but not a substitute for full VM isolation**. Kernel bugs or misconfigurations can allow escapes; sandboxing reduces surface area but doesn’t eliminate risk. Consider microVMs (Firecracker, KVM) for hostile untrusted code. ([healeycodes.com][9])
* **Bubblewrap / user-namespace sandboxes** are good but have known limitations and attack surface; read their docs. ([GitHub][5], [Julia Evans][7])
* **Rootless containerd** is mature but has operational caveats (networking, cgroup delegation) — consult the rootless containerd docs when deploying. ([rootlesscontaine.rs][1], [GitHub][2])

---

# 9) Recommendations (what I’d do, step-by-step)

1. For **one-off troubleshooting** on someone’s machine: have the owner run `./env-access-bootstrap.sh grant-access tmate` (tmate) or run a bubblewrap sandbox — minimal footprint, no keys moved, ephemeral access.
2. For **longer sessions where you need images and reproducible environments**: install rootless containerd + nerdctl and run your container images; mount in only the dirs you need. ([rootlesscontaine.rs][1], [GitHub][2])
3. For **full isolation when hosts are untrusted**: prefer a microVM or full VM (KVM/Firecracker) when you require airtight execution.
4. Always create a **manifest + cleanup** script and never leave private keys on the host.

---

If you want, I’ll do one of the following next (pick one — I’ll produce the exact script without hedging):

A) a **ready-to-run `namespaced-workspace.sh`** you can paste on a target that creates a full isolated namespace, mounts a repo, binds your SSH agent socket read-only, logs the manifest to the host, and provides a one-line cleanup command; or
B) a **rootless-containerd + nerdctl setup script** (user-mode installer) that sets up containerd in rootless mode on a machine and runs an example container with bind mounts and resource limits; or
C) a **bubblewrap-based sandbox wrapper** that safely exposes only `~/project` and your SSH agent, with manifesting and auto-cleanup.

Which one do you want me to produce right now?

[1]: https://rootlesscontaine.rs/getting-started/containerd/?utm_source=chatgpt.com "containerd (nerdctl) - Rootless Containers"
[2]: https://github.com/containerd/nerdctl/blob/master/docs/rootless.md?utm_source=chatgpt.com "nerdctl/docs/rootless.md at main · containerd/nerdctl · GitHub"
[3]: https://wiki.archlinux.org/title/Systemd-nspawn?utm_source=chatgpt.com "systemd-nspawn - ArchWiki"
[4]: https://blog.quarkslab.com/digging-into-linux-namespaces-part-1.html?utm_source=chatgpt.com "Digging into Linux namespaces - part 1 - Quarkslab's blog"
[5]: https://github.com/containers/bubblewrap?utm_source=chatgpt.com "containers/bubblewrap: Low-level unprivileged sandboxing ... - GitHub"
[6]: https://www.redhat.com/en/blog/pid-namespace?utm_source=chatgpt.com "Building containers by hand: The PID namespace - Red Hat"
[7]: https://jvns.ca/blog/2022/06/28/some-notes-on-bubblewrap/?utm_source=chatgpt.com "Notes on running containers with bubblewrap - Julia Evans"
[8]: https://unix.stackexchange.com/questions/702980/user-namespaces-how-to-mount-a-folder-only-for-a-given-program?utm_source=chatgpt.com "User namespaces: how to mount a folder only for a given program"
[9]: https://healeycodes.com/running-untrusted-python-code?utm_source=chatgpt.com "Running Untrusted Python Code - Andrew Healey"
