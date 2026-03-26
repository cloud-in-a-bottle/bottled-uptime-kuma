Uptime Kuma for OpenHost. Runs as a single Docker container:

- Uptime Kuma v2 (self-hosted uptime monitoring)
- Persistent state in OpenHost app data
- Fully private behind OpenHost authentication (no public paths)

## Deploying

Deploy via the OpenHost router dashboard and point it at this repo.

## First-time setup

On first visit, create your Uptime Kuma admin account in the setup wizard.

## Data

All Uptime Kuma data lives in `$OPENHOST_APP_DATA_DIR/` (database, monitor config, notification config, status pages).

## Access control

This app is fully private. There are no public paths in `openhost.toml`, so all requests require OpenHost authentication.

## Resources

Uses 512MB RAM and 0.5 CPU cores.

## Files

- `Dockerfile` — wraps official `louislam/uptime-kuma:2`
- `start.sh` — binds Uptime Kuma data dir to OpenHost persistent storage
- `openhost.toml` — OpenHost app manifest (private)
