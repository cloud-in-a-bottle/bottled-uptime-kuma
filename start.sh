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

# --- OpenHost single sign-on --------------------------------------------
# Uptime Kuma has no reverse-proxy / trusted-header auth, so instead of
# bolting a username header on, we let the OpenHost router BE the auth
# layer (the app is gated to the zone owner in openhost.toml) and disable
# Uptime Kuma's own login.  On first boot we:
#   1. let Uptime Kuma create + migrate its SQLite DB,
#   2. seed a single admin user (so the setup wizard is skipped), named
#      after the OpenHost owner, and
#   3. set the `disableAuth` setting, so Uptime Kuma auto-logs every
#      (already OpenHost-authenticated) visitor straight into the dashboard.
# Uptime Kuma caches settings at startup, so this runs as a short phase-1
# boot that we then restart from.  On later boots the user already exists
# and we skip straight to launch.
DB="/app/data/kuma.db"

# Pre-select SQLite so Uptime Kuma (v2) skips its interactive
# "choose database" wizard and creates kuma.db on first boot.
if [ ! -f /app/data/db-config.json ]; then
    printf '%s' '{"type":"sqlite"}' > /app/data/db-config.json
fi

OWNER="$(printf '%s' "${OPENHOST_OWNER_USERNAME:-}" | tr -cd 'A-Za-z0-9._-')"
[ -n "$OWNER" ] || OWNER="admin"

has_user() {
    [ -f "$DB" ] || return 1
    n="$(sqlite3 "$DB" "SELECT count(*) FROM user;" 2>/dev/null || echo 0)"
    [ "$n" -ge 1 ] 2>/dev/null
}

if ! has_user; then
    echo "Uptime Kuma SSO: first boot — initialising DB and disabling local auth"
    # Phase 1: boot Uptime Kuma so it creates + migrates the DB.
    node server/server.js >/tmp/kuma-init.log 2>&1 &
    INIT_PID=$!
    # Wait (up to ~90s) until init has finished: the `user` table exists and
    # the jwtSecret setting has been generated (done right after migrations).
    i=0
    while [ $i -lt 90 ]; do
        if [ -f "$DB" ] \
           && [ -n "$(sqlite3 "$DB" "SELECT name FROM sqlite_master WHERE type='table' AND name='user';" 2>/dev/null)" ] \
           && [ -n "$(sqlite3 "$DB" "SELECT value FROM setting WHERE key='jwtSecret';" 2>/dev/null)" ]; then
            break
        fi
        i=$((i + 1))
        sleep 1
    done

    if [ "$(sqlite3 "$DB" "SELECT count(*) FROM user;" 2>/dev/null || echo 0)" = "0" ]; then
        # The owner authenticates via OpenHost, never this password, so use a
        # throwaway random one (bcrypt-hashed with Uptime Kuma's own bcryptjs).
        PW_HASH="$(node -e "console.log(require('bcryptjs').hashSync(require('crypto').randomBytes(18).toString('hex'), 10))")"
        sqlite3 "$DB" "INSERT INTO user (username, password, active, twofa_status) VALUES ('$OWNER', '$PW_HASH', 1, 0);"
        echo "Uptime Kuma SSO: created admin user '$OWNER'"
    fi

    # Disable Uptime Kuma's own auth — OpenHost gating is the auth layer.
    sqlite3 "$DB" "INSERT INTO setting (key, value, type) VALUES ('disableAuth', 'true', 'general') ON CONFLICT(key) DO UPDATE SET value = 'true';"
    echo "Uptime Kuma SSO: local auth disabled (OpenHost owner gating is the auth)"

    # Stop the init instance; the real launch below picks up the seeded state.
    kill "$INIT_PID" 2>/dev/null || true
    wait "$INIT_PID" 2>/dev/null || true
fi

echo "Uptime Kuma starting: data_dir=$PERSIST"

exec /usr/bin/dumb-init -- node server/server.js
