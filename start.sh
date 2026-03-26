#!/bin/sh
set -e

# OpenHost mounts persistent storage at OPENHOST_APP_DATA_DIR.
# Uptime Kuma stores all state in /app/data.
PERSIST="${OPENHOST_APP_DATA_DIR:-/app/data}"

if [ "$PERSIST" != "/app/data" ]; then
    mkdir -p "$PERSIST"

    if [ -d /app/data ] && [ "$(ls -A /app/data 2>/dev/null)" ]; then
        cp -a /app/data/* "$PERSIST/" 2>/dev/null || true
    fi

    rm -rf /app/data 2>/dev/null || true
    ln -sfn "$PERSIST" /app/data
else
    mkdir -p /app/data
fi

echo "Uptime Kuma starting: data_dir=$PERSIST"

exec /usr/bin/dumb-init -- node server/server.js
