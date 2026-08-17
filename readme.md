Uptime Kuma for Cloud in a Bottle. Runs as a single Docker container:

- Uptime Kuma v2 (self-hosted uptime monitoring)
- Persistent state in Cloud in a Bottle app data
- Public by default on all paths

## Deploying

Deploy via the Cloud in a Bottle router dashboard and point it at this repo.

## First-time setup

On first visit, create your Uptime Kuma admin account in the setup wizard.

## Data

All Uptime Kuma data lives in `$OPENHOST_APP_DATA_DIR/` (database, monitor config, notification config, status pages).

## Access control

This app is public by default. `openhost.toml` sets `public_paths = ["/"]` so all routes are reachable without Cloud in a Bottle auth.

## Resources

Uses 512MB RAM and 0.5 CPU cores.

## Files

- `Dockerfile` — wraps official `louislam/uptime-kuma:2`
- `start.sh` — binds Uptime Kuma data dir to Cloud in a Bottle persistent storage
- `openhost.toml` — Cloud in a Bottle app manifest (private)

## License

Uptime Kuma is licensed under the MIT License (Copyright (c) 2021 Louis Lam).
Its copyright and permission notice are reproduced in `LICENSE`, as MIT
requires for redistribution; attribution and the upstream source link are in
`NOTICE`. The packaging files original to this repository are also provided
under the MIT License, so this repository is MIT overall.
