markbook/
├── Makefile
├── Cargo.toml
├── .cargo/
|   └──config.toml
├── run.sh
├── bookmarks/
│   ├── home.bkmark
│   ├── tools.bkmark
│   ├── secrets.bkmark
│   ├── agents.bkmark
│   └── darknet.bkmark
│
├── bootloader/
│   └── src/main.rs
├── kernel/
│   └── src/
│       ├── main.rs
│       ├── markos.rs
│       ├── arch/
│       │   ├── x86_64/
│       │   │   ├── paging.rs
│       │   │   ├── gdt.rs
│       │   │   ├── idt.rs
│       │   │   ├── apic.rs
│       │   │   └── tsc.rs
│       ├── memory/
│       │   ├── zones.rs
│       │   ├── allocator.rs
│       │   ├── pressure.rs
│       │   └── quarantine.rs
│       ├── devices/
│       │   ├── framebuffer.rs
│       │   ├── keyboard.rs
│       │   ├── sound.rs
│       │   ├── rtc.rs
│       │   └── mouse.rs
│       ├── syscall/
│       │   ├── table.rs
│       │   ├── handler.rs
│       │   ├── trap.rs
│       │   └── api.rs
│       ├── mark/
│       │   ├── parser.rs
│       │   ├── executor.rs
│       │   ├── language.rs
│       │   ├── syscall.rs
│       │   └── guards.rs
│       ├── security/
│       │   ├── sandbox.rs
│       │   ├── ring.rs
│       │   ├── policy.rs
│       │   └── audit.rs
│       ├── shell/
│       │   ├── interface.rs
│       │   ├── history.rs
│       │   ├── themes.rs
│       │   └── pages.rs
│       ├── books/
│       │   ├── engine.rs
│       │   ├── metadata.rs
│       │   ├── fs.rs
│       │   └── virtual.rs
│       └── orchestrator.rs
│
├── userland/
│   ├── init.mark
│   ├── echo.mark
│   ├── watchtower.mark
│   └── container/
│       ├── net.mark
│       ├── disk.mark
│       ├── firewall.mark
│       └── ai.mark
│
├── gui/
│   ├── book.rs
│   ├── drawer.rs
│   ├── frame.rs
│   ├── touch.rs
│   └── view.rs
│
├── tools/
│   ├── binder.rs
│   ├── bookfmt.rs
│   ├── fontload.rs
│   ├── snapshot.rs
│   └── monitor/
│       ├── memwatch.rs
│       ├── cpuload.rs
│       └── agentlog.rs
│
├── ffi/
│   ├── libc_bindings.rs
│   ├── c_wrappers.c
│   ├── c_wrappers.h
│   └── markfs_ffi.rs
│
├── themes/
│   ├── dark.booktheme
│   ├── light.booktheme
│   └── echo_night.booktheme
│
├── logs/
│   ├── kernel.log
│   ├── agent.log
│   └── book.log
│
└── docs/
    ├── system.md
    ├── mark.md
    ├── memory.md
    ├── bookmarks.md
    ├── kernel_design.md
    ├── gui_spec.md
    └── how_to_contribute.md
