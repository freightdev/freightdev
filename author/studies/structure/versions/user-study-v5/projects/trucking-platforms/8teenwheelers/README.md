# 🚚 OpenHWY Web App — FEDispatching.com

This is the **Next.js App Router** frontend for `fedispatching.com`, part of the OpenHWY ecosystem. It powers the SaaS dispatcher interface, public marketing site, authenticated dashboards, documentation pages, and administrative review tools.

---

## 🧽 Directory Overview

```
apps/web/app/
├── layout.tsx                     # Root app layout
├── (marketing)/                  # Public site pages (unauthenticated)
│   ├── about/                    # About the company
│   ├── careers/                  # Job openings
│   ├── contact/                  # Contact form
│   ├── feedback/                # Testimonials + suggestions
│   ├── pricing/                 # Membership pricing tiers
│   ├── testimonial/             # Case studies or quotes
│   └── page.tsx                  # Landing page entry
├── (pages)/                      # Informational and educational content
│   ├── blog/                     # Articles + updates
│   ├── docs/                     # System documentation
│   ├── help/                     # Help center & FAQs
│   ├── legal/                    # Terms, privacy, and legal policy
│   └── showcase/                 # Public showcase of tools/products
└── (platform)/                   # Secure authenticated areas
    ├── admin/                    # Admin-only views and controls
    │   ├── dashboard/            # Admin dashboards
    │   ├── reviews/              # Multi-entity audits & reviews
    │   ├── settings/             # Platform-level settings
    │   └── testing/              # Internal staging tools and sandboxes
    ├── (auth)/                   # Authentication flows
    │   ├── login/                # Login form
    │   ├── signup/               # Signup form
    │   ├── oauth/                # OAuth callback handlers
    │   ├── reset/                # Password resets
    │   └── verify/               # Email verification
    └── (user)/                   # Dispatcher portal
        ├── course/               # Learning portal
        ├── dashboard/            # Dispatcher tools, loads, clients
        ├── settings/             # Personal configuration
        └── profile/              # User info + customization
```

---

## 🧹 Tech Stack

* **Next.js App Router** — with nested layouts and route groups
* **Tailwind CSS** — for rapid UI styling
* **Solito + Expo** — cross-platform routing (web + mobile)
* **RustAPI / Custom Backends** — via `open-hwy.com` SDK/API
* **AI Agents (future)** — Markdown-native logic coming soon

---

## 📌 Naming & Conventions

* Use `(group)` to isolate public vs. private areas (e.g. `(auth)`, `(platform)`)
* Dynamic routes use `[id]` or `[slug]`
* `layout.tsx` exists in every major folder for scoped theming
* `page.tsx` = entry point per route folder

---

## 👋 Contributing

1. Clone the repo: `git clone git@github.com:freightdev/fedispatching.git`
2. Install: `pnpm install`
3. Start: `pnpm dev`
4. Explore `/apps/web/app/` to dive into routes and logic

For agent integration docs, see [`/docs`](../docs).

---

## 🧠 Built by Jesse Conley

> “I didn’t learn to code to automate the road. I learned to build the system before the system builds us.”
