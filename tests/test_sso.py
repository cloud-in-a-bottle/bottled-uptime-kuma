import json
import time

import requests
from openhost_test_harness import OpenhostStack

SOCKET_IO = "/socket.io/?EIO=4&transport=polling"


def _socket_events(stack: OpenhostStack) -> list[str]:
    """Connect to Uptime Kuma's socket.io as the owner (HTTP long-polling) and return the names of the events it sends.

    The dashboard is a socket.io app: on connect the server sends "setup" (no user yet: the setup wizard),
    "loginRequired" (the login form) or, with auth disabled, "autoLogin" straight into the dashboard.
    """
    session = stack.owner_session
    deadline = time.monotonic() + 120
    while True:
        try:
            handshake = session.get(f"{stack.url}{SOCKET_IO}", timeout=30)
            if handshake.status_code == 200 and handshake.text.startswith("0"):
                break
            last = f"{handshake.status_code}: {handshake.text[:300]}"
        except requests.ConnectionError as exc:
            last = str(exc)
        if time.monotonic() > deadline:
            raise AssertionError(f"socket.io handshake failed: {last}\n\napp logs:\n{stack.app_logs()[-5000:]}")
        time.sleep(3)

    poll_url = f"{stack.url}{SOCKET_IO}&sid={json.loads(handshake.text[1:])['sid']}"
    connect = session.post(poll_url, data="40", headers={"Content-Type": "text/plain;charset=UTF-8"}, timeout=30)
    assert connect.status_code == 200, f"socket.io connect: {connect.status_code}: {connect.text[:300]}"

    events: list[str] = []
    deadline = time.monotonic() + 30
    while time.monotonic() < deadline and not {"autoLogin", "loginRequired"} & set(events):
        response = session.get(poll_url, timeout=60)
        assert response.status_code == 200, f"socket.io poll: {response.status_code}: {response.text[:300]}"
        for packet in response.text.split("\x1e"):
            if packet.startswith("42"):
                events.append(json.loads(packet[2:])[0])
    return events


def test_owner_lands_in_the_dashboard(stack: OpenhostStack) -> None:
    """start.sh seeds an admin user (no setup wizard) and sets disableAuth (no login form): the owner is logged in."""
    events = _socket_events(stack)
    assert "autoLogin" in events, f"owner was not auto-logged in; socket events: {events}"
    assert "setup" not in events and "loginRequired" not in events, f"socket events: {events}"


def test_anonymous_visitors_cannot_reach_the_app(stack: OpenhostStack) -> None:
    """Uptime Kuma's own login is disabled, so the router (public_paths = []) must keep everyone but the owner out."""
    for path in ("/", "/dashboard", SOCKET_IO, "/metrics"):
        response = requests.get(
            f"{stack.url}{path}", headers={"Accept": "text/html"}, allow_redirects=False, timeout=30
        )
        assert response.status_code == 404, f"anonymous GET {path}: {response.status_code}: {response.text[:300]}"


def test_data_is_stored_in_app_data(stack: OpenhostStack) -> None:
    """/app/data is moved to the app data dir, so monitors and history survive redeploys and updates."""
    assert (stack.data_dir / "kuma.db").exists(), sorted(p.name for p in stack.data_dir.iterdir())
