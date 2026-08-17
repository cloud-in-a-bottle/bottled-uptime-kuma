# bottled-uptime-kuma

[Uptime Kuma](https://github.com/louislam/uptime-kuma) is a self-hosted uptime
monitor that checks whether your sites and services are reachable and alerts you
when they are not. This repository packages it as a Cloud in a Bottle app.

## What you get

- Uptime Kuma v2 running on `https://uptime-kuma.<zone>/`.
- Owner only: gated behind your Cloud in a Bottle login, not public.
- No second login. Open the app and you are already on the dashboard.
- Monitors for HTTP and HTTPS, TCP ports, ping, DNS, and more, on the interval
  you choose.
- Notifications through the providers Uptime Kuma supports, such as email,
  Slack, and webhooks.
- Uptime history, response-time graphs, and status pages.
- Monitors, history, and settings persist in the app's storage.

## Usage

Log in to Cloud in a Bottle, then open `https://uptime-kuma.<zone>/`. You land
on the dashboard. Choose "Add New Monitor", pick a type such as HTTP(s), enter
the URL to watch, and save. The monitor starts checking immediately and its
history builds up on the dashboard. Add a notification under Settings if you
want to be told when something goes down.

## Access control

Only you can reach this app. `openhost.toml` sets `public_paths = []`, so
anyone who is not logged in to Cloud in a Bottle is sent to the Cloud in a
Bottle login instead.

Because Cloud in a Bottle already handles the login, Uptime Kuma's own login is
turned off. On first boot the app creates a single Uptime Kuma admin account
named after the zone owner and disables Uptime Kuma's login screen, so there is
no setup wizard and no second password to keep track of.

Do not make this app public. Uptime Kuma's own login is off, so opening any
path to anonymous visitors would expose the whole dashboard.

For the same reason, status pages are visible only to you. Sharing one with
someone who cannot log in to your zone will not work.

## Caveats

Ping monitors do not work. App containers do not receive ICMP echo replies, so
a Ping monitor reports 100% packet loss and stays permanently down even when the
target is healthy. Use an HTTP(s), TCP port, or DNS monitor instead, all of
which work normally.

## Data

Everything Uptime Kuma stores lives under `$OPENHOST_APP_DATA_DIR/`: the
database, monitor configuration, notification settings, and status pages.

## Resources

About 512 MB RAM and 0.5 CPU cores.

## License

Uptime Kuma is licensed under the MIT License (Copyright (c) 2021 Louis Lam).
Its copyright and permission notice are reproduced in `LICENSE`, as MIT
requires for redistribution; attribution and the upstream source link are in
`NOTICE`. The packaging files original to this repository are also provided
under the MIT License, so this repository is MIT overall.
