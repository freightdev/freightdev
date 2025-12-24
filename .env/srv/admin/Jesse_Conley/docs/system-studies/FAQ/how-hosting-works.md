# 🧭 THE STRUCTURAL PRIMER FOR HOSTING USERS, AGENTS, AND CLIENTS

## 🔒 Part 1: The Old Way — UNIX Isolation Without Containers

### ✅ User-based sandboxing

In the original server model, users were **system accounts** with home directories:

```
/home/jesse
/home/client01
/home/agent77
```

Each user was sandboxed using:

* **UNIX permissions** (`chmod`, `chown`, `umask`)
* **Groups** (`/etc/group`)
* **Shells** (`/bin/bash`, `/sbin/nologin`)
* **Chroot jails** (limited visibility of the filesystem)

But this model:

* 💥 Can leak if users are careless with permissions
* 🧱 Offers no resource control (no CPU/GPU/RAM quotas)

---

## 🚀 Part 2: The Container Way — Docker/Podman/Containerd

Each client gets:

* **Ephemeral isolated environment** (`docker run`)
* **Mapped data volumes**: `-v /srv/users/client01:/data`
* **Cgroup quotas** (RAM/CPU/GPU limits)
* **User namespace isolation** (real UID != container UID)

---

## 🔩 DIRECTORY STRUCTURE: WHERE YOU PUT STUFF (MODERN WAY)

### 🎯 Base layout (on your ASUS server):

```
/srv/
├── users/              # Real persistent volume mounts
│   ├── jesse/          # Your orchestrator storage
│   ├── client01/       # A paying customer
│   ├── agent77/        # AI sandbox or service
├── docker/             # Optional Docker bind mounts
│   ├── volumes/
│   ├── configs/
├── ops/                # Your operational scripts/logs
├── runtime/            # Shared system temp/running states
│   ├── build/
│   └── tmp/
```

You **never** write to `/var` unless it's runtime-only stuff. Treat `/srv` as your **host-managed user-facing volume zone**.

---

### 🛠 User container mapping example:

* **Persistent user data**: `/srv/users/client01/`
* **Bind-mount into container**:

```bash
docker run \
  --name client01 \
  --memory=4g --cpus=2 \
  --gpus=1 \
  -v /srv/users/client01:/app/data \
  user-container-image
```

That way, the client can do *whatever* inside the container, but their files always live on host under `/srv/users/client01`.

---

## 📦 Part 3: What Goes Where?

| What                        | Path on Host                           | Notes                    |
| --------------------------- | -------------------------------------- | ------------------------ |
| User data (clients, agents) | `/srv/users/<name>`                    | All persistent state     |
| Docker volumes              | `/srv/docker/volumes/`                 | Optional, Docker-managed |
| Build scripts               | `/srv/ops/` or `/usr/local/bin/`       | For system-wide logic    |
| Runtime containers          | `/var/run/docker/`, `/run/containers/` | Auto-managed by runtime  |
| Temporary files             | `/srv/runtime/tmp/`, `/tmp`            | Can be cleaned on exit   |
| Logs                        | `/var/log/`, `/srv/ops/logs/`          | Separate per workload    |

---

## 🧠 Part 4: Resource Isolation (per-user limits)

For **true multi-tenant isolation**, each container gets:

* `--cpus=N`
* `--memory=N`
* `--gpus=all` (or specific via NVIDIA runtime)

Use `cgroups` or `docker-compose` to automate it.

---

## 🧼 Part 5: Lifecycle Scripts (from your Lenovo)

You should control **everything** via remote scripts stored in something like:

```
~/scripts/remote/
├── create-user.sh
├── delete-user.sh
├── build-container.sh
├── purge-container.sh
├── reboot-asus.sh
├── push-model.sh
```

### 🛠 Example: Create a new client and container

```bash
#!/bin/bash
USER="$1"

# Create persistent folder
ssh asus "mkdir -p /srv/users/$USER"

# Launch container
ssh asus "
  docker run -d \
    --name $USER \
    --memory=4g --cpus=2 \
    -v /srv/users/$USER:/app/data \
    user-base-image
"
```

### 🔁 Delete user workload:

```bash
#!/bin/bash
USER="$1"
ssh asus "
  docker rm -f $USER
  rm -rf /srv/users/$USER
"
```

---

## 🧩 Part 6: Think Like a Host OS

> The host (ASUS) is the **infra**. All real state **lives in `/srv`**, nothing pollutes `/home`, `/var`, or `/opt`.

### Design principle:

* **Your Lenovo** → orchestrates (manages `/srv`, launches builds, purges users)
* **Your ASUS** → hosts isolated environments, containers, data mounts

---

## ✅ Final Summary: What You Need to Know

### 🎯 Where do I put things?

* **Data** → `/srv/users/<user>` (bind-mount to containers)
* **Scripts** → `/usr/local/bin/` (or `/srv/ops/`)
* **Runtime builds** → `/srv/runtime/build/` or `/tmp`
* **Logs** → `/var/log/` (or `/srv/ops/logs/` for user-specific)

### 📦 How to isolate users?

* Docker + cgroups
* UID namespace or limited access to `/srv/users/<user>`
* File system ACLs or Linux permission model

### 🛡️ How to secure users?

* Never let them access the host shell
* Use `--read-only` containers if needed
* Rotate volumes or destroy containers after session

---

You are now ready to:

* Create a full `/srv`-based multi-user host
* Map everything via Docker or Podman
* Orchestrate everything from Lenovo using Tailscale SSH

Let me know if you want:

* A `/srv` skeleton builder
* Per-user container auto-launchers
* Real world example: "agent77 connects, container spawns, dies after 1hr"

You're officially **entering infrastructure mode**.
