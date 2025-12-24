# Directory Structure

```
BookOS/
├── 📁 mark-kernel/                   # MARK Kernel core system
│   ├── 📄 mark (CLI entrypoint)
│   ├── 📄 kernel.rs
│   └── 📁 schema/
│       ├── 📄 markdb.schema.json
│       ├── 📄 ribbon.schema.json
│       └── 📄 trail.schema.json
│
├── 📁 beats/                         # Beat agents: execution units
│   ├── 📄 dispatch.beat.yaml
│   ├── 📄 trainer.beat.yaml
│   └── 📄 summarize.beat.yaml
│
├── 📁 markers/                       # Markers: interaction controllers
│   ├── 📄 book.mrkr.yaml
│   ├── 📄 summarize.mrkr.yaml
│   ├── 📄 routing.mrkr.yaml
│   └── 📄 search.mrkr.yaml
│
├── 📁 memory/                        # Persistent memory and mmap structure
│   ├── 📄 case.markdb
│   ├── 📄 user.mmap
│   ├── 📄 dispatch.mmap
│   └── 📁 archive/
│       └── 📄 backup_20240717.mmap
│
├── 📁 ribbons/                       # Ribbon cache layer
│   ├── 📄 summary.rib.yaml
│   └── 📄 index.json                 # Index of all ribbons
│
├── 📁 trails/                        # Trail logging
│   ├── 📄 trail.schema.json
│   └── 📁 tmp/
│       └── 📄 abc123.trl             # Dynamic runtime-generated trails
│
├── 📁 books/                         # User/project specific memory
│   ├── 📁 dispatch/
│   │   ├── 📄 book.md
│   │   ├── 📁 pages/
│   │   │   ├── 📄 overview.md
│   │   │   └── 📄 schedule.md
│   │   ├── 📁 ribbons/
│   │   │   └── 📄 summary.rib.yaml
│   │   └── 📁 trails/
│   │       └── 📄 dispatch-session.trl
│   │
│   └── 📁 user/
│       ├── 📄 book.md
│       ├── 📁 pages/
│       │   ├── 📄 profile.md
│       │   └── 📄 settings.md
│       ├── 📁 ribbons/
│       │   └── 📄 intro.rib.yaml
│       └── 📁 trails/
│           └── 📄 user-session.trl
│
├── 📁 docs/                          # System documentation & schema
│   ├── 📄 README.md                  # Introduction to BookOS
│   ├── 📁 beats/
│   │   └── 📄 intro.md
│   ├── 📁 markers/
│   │   └── 📄 intro.md
│   ├── 📁 ribbons/
│   │   └── 📄 intro.md
│   ├── 📁 memory/
│   │   └── 📄 intro.md
│   ├── 📁 trails/
│   │   └── 📄 intro.md
│   ├── 📁 api/
│   │   └── 📄 integration.md
│   └── 📁 economy/
│       └── 📄 cost-structure.md
│
├── 📁 config/                        # Platform and execution config
│   ├── 📄 mark.yaml                  # Main kernel configuration
│   ├── 📄 init.mtp                   # MARK Telling Protocol config
│   └── 📄 economy.yaml               # Cost and revenue settings
│
├── 📁 scripts/                       # Platform helper scripts
│   ├── 📄 init_db.sh                 # runs `mark init db`
│   ├── 📄 validate_schemas.sh
│   └── 📄 deploy_bookos.sh
│
└── 📁 ui/                            # Bookmark UI Layer
    ├── 📄 ui-mark.tsx                # Visual render logic for .mark files
    └── 📄 ribbon-viewer.tsx          # Ribbon interaction UI component
```

---

## 🧠 What does `mark init db` do here?

**When you run:**

```bash
mark init db
```

It scans:

* ✅ `books/**/*.md`
* ✅ `markers/**/*.mrkr.yaml`
* ✅ `beats/**/*.beat.yaml`
* ✅ `ribbons/**/*.rib.yaml`

Then it builds:

* 📄 `memory/case.markdb` → the indexed database of markers, beats, books, ribbons
* 📄 `ribbons/index.json` → a quick-access ribbon-cache index
* 📄 `trails/tmp/*.trl` → initializes temporary trail logs for execution

**After indexing**, filenames no longer require `.mark` in their naming—MARK kernel knows them by their schemas.

---

## 🚀 Next Steps?

* Run:

```bash
mark init db
```

* Validate schemas:

```bash
scripts/validate_schemas.sh
```

* Launch UI renderer:

```bash
cd ui && yarn start
```
