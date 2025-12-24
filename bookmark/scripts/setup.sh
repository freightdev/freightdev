#!/bin/bash
# Creates the full marketeer/ directory tree

set -e

BASE="../"

echo "Creating directory structure for $BASE..."

# --- Directories ---
mkdir -p $BASE/{src/{cli,parser,executor,crypto,tracker,api,templates,config,utils},\
manifests/{examples,templates},migrations,app/{lib/{api,screens,widgets,providers,models,services,utils},assets/{images,icons},android,ios,linux,macos,windows,web},\
tests/{integration,unit,fixtures},scripts}

# --- Top-level files ---
touch $BASE/{Cargo.toml,Cargo.lock,.gitignore}

# --- src files ---
touch $BASE/src/{main.rs,lib.rs}
touch $BASE/src/cli/{mod.rs,commands.rs,args.rs,output.rs}
touch $BASE/src/parser/{mod.rs,manifest.rs,schema.rs,validator.rs}
touch $BASE/src/executor/{mod.rs,system.rs,users.rs,storage.rs,network.rs,vms.rs,containers.rs,k3s.rs,services.rs}
touch $BASE/src/crypto/{mod.rs,encryption.rs,hashing.rs,keys.rs}
touch $BASE/src/tracker/{mod.rs,database.rs,marks.rs,audit.rs,stats.rs}
touch $BASE/src/api/{mod.rs,server.rs,routes.rs,handlers.rs,middleware.rs}
touch $BASE/src/templates/{mod.rs,loader.rs,registry.rs}
touch $BASE/src/config/{mod.rs,settings.rs}
touch $BASE/src/utils/{mod.rs,error.rs,logger.rs,system_info.rs}

# --- manifests ---
touch $BASE/manifests/examples/{simple-user.yaml,ai-agent.yaml,full-system.yaml,k3s-cluster.yaml}
touch $BASE/manifests/templates/{arch-linux-base.yaml,debian-13-server.yaml,ai-agent-workspace.yaml,docker-development.yaml}

# --- migrations ---
touch $BASE/migrations/{001_initial_schema.sql,002_add_access_marks.sql,003_add_resource_stats.sql}

# --- app ---
touch $BASE/app/{pubspec.yaml,pubspec.lock,analysis_options.yaml}
touch $BASE/app/lib/{main.dart,app.dart}
touch $BASE/app/lib/api/{client.dart,models.dart,endpoints.dart}
touch $BASE/app/lib/screens/{dashboard_screen.dart,systems_screen.dart,resources_screen.dart,manifests_screen.dart,monitoring_screen.dart,control_screen.dart}
touch $BASE/app/lib/widgets/{system_card.dart,resource_list.dart,manifest_editor.dart,stats_chart.dart,activity_log.dart}
touch $BASE/app/lib/providers/{marketeer_provider.dart,systems_provider.dart,resources_provider.dart}
touch $BASE/app/lib/models/{system.dart,resource.dart,manifest.dart,mark.dart}
touch $BASE/app/lib/services/{api_service.dart,storage_service.dart}
touch $BASE/app/lib/utils/{constants.dart,themes.dart,helpers.dart}

# --- tests ---
touch $BASE/tests/integration/{mod.rs,user_provisioning.rs,vm_creation.rs,manifest_apply.rs}
touch $BASE/tests/unit/{mod.rs,parser_tests.rs,crypto_tests.rs,validator_tests.rs}
touch $BASE/tests/fixtures/{test-manifest.yaml,test-system-config.yaml}

# --- scripts ---
touch $BASE/scripts/{install.sh,build.sh,test.sh}

echo "✅ marketeer structure created successfully!"
