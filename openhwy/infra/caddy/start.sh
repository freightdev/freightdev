#!/usr/bin/env sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
if [ -f "$here/.env" ]; then
  set -a
  . "$here/.env"
  set +a
fi
cd "$here"
docker compose up -d
