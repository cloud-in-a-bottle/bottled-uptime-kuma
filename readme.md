Uptime Kuma for Cloud in a Bottle. Runs as a single Docker container:

- Uptime Kuma v2 (self-hosted uptime monitoring)
- Persistent state in Cloud in a Bottle app data
- Owner-only: gated behind Cloud in a Bottle auth (not public)

## Deploying

Deploy via the Cloud in a Bottle router dashboard and point it at this repo.

## Access control and login

This app is gated to the zone owner. `openhost.toml` sets `public_paths = []`, so
every route requires the Cloud in a Bottle owner to be logged in; anonymous
visitors are redirected to the Cloud in a Bottle login.

Uptime Kuma has no reverse-proxy / trusted-header auth of its own, so rather than
running two separate logins, the Cloud in a Bottle owner gate IS the
authentication and Uptime Kuma's own login is disabled. On first boot `start.sh`:

- seeds a single Uptime Kuma admin user named after the Cloud in a Bottle owner, and
- sets Uptime Kuma's `disableAuth`, so every (already authenticated) visitor is
  auto-logged straight into the dashboard.

There is no Uptime Kuma setup wizard and no separate Uptime Kuma password to
manage — the first time you open the app as the logged-in owner you land directly
on the dashboard.

Because Uptime Kuma's own auth is disabled, do not make this app public (do not
set `public_paths = ["/"]`): that would expose the full dashboard to anyone.

## Data

All Uptime Kuma data lives in `$OPENHOST_APP_DATA_DIR/` (database, monitor config, notification config, status pages).

## Resources

Uses 512MB RAM and 0.5 CPU cores.

## Files

- `Dockerfile` — wraps official `louislam/uptime-kuma:2`
- `start.sh` — binds the Uptime Kuma data dir to Cloud in a Bottle persistent storage, seeds the owner admin user, and disables Uptime Kuma's own auth
- `openhost.toml` — Cloud in a Bottle app manifest (private)
