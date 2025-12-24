jesse@echo-ops ~/.dev/projects/archbox 
❯ treestub                                                                        13:40:10
.
├── core
│   ├── boot.rs
│   ├── context.rs
│   ├── kernel.rs
│   ├── memory.rs
│   ├── router.rs
│   └── scheduler.rs
├── _gitea
├── lib.rs
├── main.rs
├── _meta
├── readme.md
└── src
    ├── adapters
    │   ├── apk.rs
    │   ├── authentik.rs
    │   ├── bridge.rs
    │   ├── buildah.rs
    │   ├── buildkit.rs
    │   ├── caddy.rs
    │   ├── candle.rs
    │   ├── cargo.rs
    │   ├── celery.rs
    │   ├── centrifugo.rs
    │   ├── cloudflare.rs
    │   ├── containerd.rs
    │   ├── coredns.rs
    │   ├── crowdsec.rs
    │   ├── crun.rs
    │   ├── cucoost.rs
    │   ├── cudarc.rs
    │   ├── dagger.rs
    │   ├── devenv.rs
    │   ├── docker.rs
    │   ├── drone.rs
    │   ├── duckdb.rs
    │   ├── earthly.rs
    │   ├── elastic.rs
    │   ├── envoy.rs
    │   ├── fail2ban.rs
    │   ├── fastnetmon.rs
    │   ├── firewalld.rs
    │   ├── frp.rs
    │   ├── gateway.rs
    │   ├── gitea.rs
    │   ├── githooks.rs
    │   ├── github.rs
    │   ├── go.rs
    │   ├── grafana.rs
    │   ├── haproxy.rs
    │   ├── headscale.rs
    │   ├── host_local.rs
    │   ├── indexdb.rs
    │   ├── inlets.rs
    │   ├── iptables_nft.rs
    │   ├── jest.rs
    │   ├── journald.rs
    │   ├── jq.rs
    │   ├── just.rs
    │   ├── k3s.rs
    │   ├── k6s.rs
    │   ├── k8s.rs
    │   ├── keycloak.rs
    │   ├── kong.rs
    │   ├── krakend.rs
    │   ├── kubernetes.rs
    │   ├── letsencrypt.rs
    │   ├── llama.cpp.rs
    │   ├── loki.rs
    │   ├── lsp.rs
    │   ├── mkcert.rs
    │   ├── mod.rs
    │   ├── modsecurity.rs
    │   ├── mysql.rs
    │   ├── nats.rs
    │   ├── nerdctl.rs
    │   ├── netdata.rs
    │   ├── nginx.rs
    │   ├── nix.rs
    │   ├── nmap.rs
    │   ├── nomad.rs
    │   ├── oathkeeper.rs
    │   ├── openresty.rs
    │   ├── pacman.rs
    │   ├── pf.rs
    │   ├── podman.rs
    │   ├── postgres.rs
    │   ├── prometheus.rs
    │   ├── prost.rs
    │   ├── redis.rs
    │   ├── runc.rs
    │   ├── s6_overlay.rs
    │   ├── sed.rs
    │   ├── serde.rs
    │   ├── sops.rs
    │   ├── spin.rs
    │   ├── stripe.rs
    │   ├── supervisord.rs
    │   ├── systemd.rs
    │   ├── tailscale.rs
    │   ├── tantivy.rs
    │   ├── teleport.rs
    │   ├── terraform.rs
    │   ├── tls.rs
    │   ├── tonic.rs
    │   ├── traefik.rs
    │   ├── transformers.rs
    │   ├── triton.rs
    │   ├── ufw.rs
    │   ├── unbound.rs
    │   ├── unix.rs
    │   ├── varnish.rs
    │   ├── vault.rs
    │   ├── vector.rs
    │   ├── vllm.rs
    │   ├── wasm_bindgen.rs
    │   ├── wasmedge.rs
    │   ├── wasm_pack.rs
    │   ├── wasmtime.rs
    │   ├── wireguard.rs
    │   ├── woodpecker.rs
    │   ├── yay.rs
    │   ├── yq.rs
    │   ├── zitadel.rs
    │   └── zora.rs
    ├── bin
    │   ├── archbox-agent.rs
    │   ├── archboxd.rs
    │   └── archbox-worker.rs
    ├── bindings
    │   ├── llama_cpp.rs
    │   └── mod.rs
    ├── cli
    │   ├── args.rs
    │   ├── completions.rs
    │   ├── mod.rs
    │   └── subcommands.rs
    ├── commands
    │   ├── ai.rs
    │   ├── api_mgr.rs
    │   ├── ask.rs
    │   ├── auth_mgr.rs
    │   ├── backup.rs
    │   ├── bride.rs
    │   ├── build.rs
    │   ├── chat.rs
    │   ├── clean.rs
    │   ├── cluster.rs
    │   ├── containers.rs
    │   ├── create.rs
    │   ├── database.rs
    │   ├── dev.rs
    │   ├── dns.rs
    │   ├── edit.rs
    │   ├── explain.rs
    │   ├── firewall.rs
    │   ├── git.rs
    │   ├── index.rs
    │   ├── infra.rs
    │   ├── init.rs
    │   ├── jupyter.rs
    │   ├── mod.rs
    │   ├── monitor_alerts.rs
    │   ├── monitor.rs
    │   ├── network.rs
    │   ├── notify_mgr.rs
    │   ├── proxy.rs
    │   ├── query.rs
    │   ├── runner_mgr.rs
    │   ├── run.rs
    │   ├── scan.rs
    │   ├── security.rs
    │   ├── services.rs
    │   ├── setup.rs
    │   ├── socket.rs
    │   ├── step.rs
    │   ├── storage.rs
    │   ├── system.rs
    │   ├── test.rs
    │   ├── tuning.rs
    │   ├── tunnel.rs
    │   └── workers.rs
    ├── core
    │   ├── api.rs
    │   ├── auth.rs
    │   ├── config.rs
    │   ├── constants.rs
    │   ├── errors.rs
    │   ├── exec.rs
    │   ├── gpg.rs
    │   ├── loggings.rs
    │   ├── mod.rs
    │   ├── notify.rs
    │   ├── parser.rs
    │   ├── runners.rs
    │   ├── ssh.rs
    │   ├── state.rs
    │   ├── system_info.rs
    │   └── utils.rs
    ├── handlers
    │   ├── ai_handler.rs
    │   ├── api_handler.rs
    │   ├── auth_handler.rs
    │   ├── backup_handler.rs
    │   ├── bridge_handler.rs
    │   ├── build_handler.rs
    │   ├── cluster_handler.rs
    │   ├── containers_handler.rs
    │   ├── database_handler.rs
    │   ├── dev_handler.rs
    │   ├── dns_handler.rs
    │   ├── exec_handler.rs
    │   ├── firewall_handler.rs
    │   ├── infra_handler.rs
    │   ├── jupyter_handler.rs
    │   ├── logging_handler.rs
    │   ├── memory_handler.rs
    │   ├── mod.rs
    │   ├── monitor_alerts_handler.rs
    │   ├── monitor_handler.rs
    │   ├── network_handler.rs
    │   ├── notify_handler.rs
    │   ├── proxy_handler.rs
    │   ├── query_handler.rs
    │   ├── register_handler.rs
    │   ├── route_handler.rs
    │   ├── runner_handler.rs
    │   ├── security_handler.rs
    │   ├── server_handler.rs
    │   ├── services_handler.rs
    │   ├── socket_handler.rs
    │   ├── storage_handler.rs
    │   ├── sync_handler.rs
    │   ├── system_handler.rs
    │   ├── tts_handler.rs
    │   ├── tuning_handler.rs
    │   └── workers_handler.rs
    ├── _idea
    │   ├── bash.rs
    │   ├── busybox.rs
    │   ├── cgroups.rs
    │   ├── contracts.rs
    │   ├── c++.rs
    │   ├── firecracker.rs
    │   ├── go.rs
    │   ├── gRPC.rs
    │   ├── justfile.rs
    │   ├── kvm.rs
    │   ├── libvirt.rs
    │   ├── lxc.rs
    │   ├── make.rs
    │   ├── musl.rs
    │   ├── nats.rs
    │   ├── qemu.rs
    │   ├── tmux.rs
    │   ├── virt_mgr.rs
    │   ├── webhooks.rs
    │   └── zsh.rs
    ├── logic
    │   ├── controller.rs
    │   ├── extractor.rs
    │   ├── flow.rs
    │   ├── generator.rs
    │   ├── hydrate.rs
    │   ├── inject.rs
    │   ├── map.rs
    │   ├── match.rs
    │   ├── mod.rs
    │   ├── summarize.rs
    │   ├── trigger.rs
    │   └── vectorize.rs
    ├── model
    │   ├── call.rs
    │   ├── format.rs
    │   ├── mod.rs
    │   ├── prompt.rs
    │   ├── router.rs
    │   └── schema.rs
    ├── portals
    │   ├── cockpit
    │   ├── dashy
    │   ├── grafana
    │   ├── homarr
    │   ├── jupyter
    │   └── portainer
    ├── protocol
    │   ├── encoding.rs
    │   ├── eventbus.rs
    │   └── ppur.rs
    ├── runners
    │   ├── cli.rs
    │   ├── daemon.rs
    │   ├── mod.rs
    │   └── repl.rs
    ├── runtime
    │   ├── cache.rs
    │   ├── env.rs
    │   ├── mod.rs
    │   ├── session.rs
    │   └── telemetry.rs
    ├── signal
    │   ├── agent.rs
    │   ├── file.rs
    │   ├── model.rs
    │   ├── system.rs
    │   └── task.rs
    ├── tests
    │   ├── mod.rs
    │   ├── test_ai.rs
    │   ├── test_api.rs
    │   ├── test_backup.rs
    │   ├── test_containers.rs
    │   ├── test_jupyter.rs
    │   ├── test_network.rs
    │   ├── test_security.rs
    │   ├── test_storage.rs
    │   └── test_system.rs
    └── utils
        ├── colors.rs
        ├── compression.rs
        ├── context.rs
        ├── crontab.rs
        ├── fs.rs
        ├── input.rs
        ├── interval.rs
        ├── json.rs
        ├── macros.rs
        ├── metrics.rs
        ├── mod.rs
        ├── output.rs
        ├── path.rs
        ├── profile.rs
        ├── random.rs
        ├── retry.rs
        ├── string.rs
        ├── styles.rs
        ├── table.rs
        ├── time.rs
        ├── tree.rs
        └── yaml.rs
