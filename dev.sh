#!/bin/bash
# Serve the vault locally with hot reload.
# Override ports with e.g. PORT=8081 WS_PORT=3004 ./dev.sh
set -e

PORT="${PORT:-8080}"
# Not 3001: a bun process commonly holds that port, and a collision kills the
# server instead of just disabling hot reload.
WS_PORT="${WS_PORT:-3003}"

VAULT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$VAULT/.quartz"
# Git-sourced plugins live in .quartz/.quartz/plugins/, which is gitignored,
# and the build command does not fetch them on its own. Without this a fresh
# clone builds fine but silently drops them.
npm run install-plugins

# See build.sh: `npx quartz` resolves to an unrelated registry package.
node ./quartz/bootstrap-cli.mjs build --serve \
  --port "$PORT" --wsPort "$WS_PORT" \
  -d ../content -o ../public
