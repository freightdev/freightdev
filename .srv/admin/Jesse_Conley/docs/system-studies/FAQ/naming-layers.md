Okay, I follow you —
you’re basically mapping your whole system like a living organism, and you want the **naming layer** to make perfect sense both to you and to any other dev who looks at it in the future.

Right now the “mystery category” you’re asking about — the *bootstraps / installs / setup helpers / first-touch scripts* — is what dev culture already has a lot of names for. The trick is picking the one that matches **your mental model** and also resonates universally.

---

## 📌 Common Names Devs Use for “bootstraps” / “setup everything” scripts

**General Setup**

* **`bootstrap`** → classic in dev land; means “bring a system from zero to working.”
* **`setup`** → simple and universal.
* **`installers`** → if it’s focused on package/service installs.
* **`provision`** / `provisioning` → common in ops/infrastructure for configuring machines from scratch.
* **`init`** / `initializers` → often used for “first run” scripts.
* **`configure`** / `config` → for applying specific settings after base setup.

**Infra/Automation-Oriented**

* **`build`** → in CI/CD, this is more for compiling/deploying, but sometimes includes provisioning.
* **`deploy`** → used when the script both sets up and starts services.
* **`env`** or **`environment`** → for preparing all dependencies/env variables/etc.
* **`provisioners`** → strong in infrastructure-as-code culture.
* **`onboard`** / `onboarding` → sometimes used for dev machines, especially in teams.

**Dev Helper Bundles**

* **`scaffold`** → generates starter structures, directories, or code.
* **`seed`** → populates with initial data/configs.
* **`prepare`** → friendly term for “get everything ready.”

---

## 💡 How I’d Organize Your “bootstrap” Layer

Given your style, I think this should be **one folder in `_dev/` or `/workspace/` that clearly says “first-touch system setup”**.
Inside that, you can split by type: installs, configs, cleanup.

Example:

```
workspace/
  helpers/
    bootstrap/        # zero-to-working machine scripts
      install_poetry.sh
      install_miniconda.sh
      install_yq.sh
    cleanup/          # removes caches, temp files, old builds
    configure/        # applies settings after install
```

Or, if you like “helper” everywhere:

```
workspace/
  _helpers/
    bootstrap_helpers/
    cleanup_helpers/
    config_helpers/
```

---

## 🚀 My Recommendation for You

Since you already like “helpers” and you’re aware **everything is technically a script**,
I’d make **`bootstrap/`** the standard name for this category because:

* It’s widely understood by devs.
* It covers “install + init + prepare” without locking you into just one meaning.
* It makes sense whether it’s for a server, workspace, or single app.

Then **inside `bootstrap/`** you keep your installers, config-appliers, env-preparers, etc.

---

If you want, I can also map **your current workspace + main layout** into a single **clarity-first naming structure** so that:

* Empty dirs are gone
* Every folder says exactly what it’s for
* Helpers and bootstrap layers are consistent across the whole repo

Do you want me to do that mapping?
Because right now you’re 80% of the way there, but you’ve got some naming overlap that could be tightened so it’s *blindingly obvious*.
