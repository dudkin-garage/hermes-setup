# Hermes SSH Tunnel Setup

This setup runs Hermes in Docker on a VPS and reaches the Docker-published Hermes API and dashboard through SSH tunnels.

## Environment

Set the VPS SSH endpoint in `.env`:

```bash
VPS_HOST=h2.dudkin-garage.com
VPS_SSH_USER=worker
VPS_SSH_PORT=22
```

Hermes is configured to publish its Docker ports on VPS loopback by default, so the API and dashboard are not exposed publicly:

```bash
HERMES_API_BIND_HOST=127.0.0.1
HERMES_DASHBOARD_BIND_HOST=127.0.0.1
```

## Dashboard/API Tunnel

Run this on your local machine:

```bash
make tunnel
```

Then open:

```bash
http://127.0.0.1:19119
```

The API is forwarded to:

```bash
http://127.0.0.1:18642
```

## Reverse Tunnel

If the Hermes container on the VPS needs to call a service running on your local machine, use the reverse tunnel target:

```bash
make tunnel-reverse
```

Inside the Hermes container, the reverse-forwarded API is reachable at:

```bash
http://host.docker.internal:18642
```

## Verification Tests

### Host Tests
Run these on the Hetzner host:
```bash
curl http://127.0.0.1:18642/health
curl http://172.17.0.1:18642/health
```

### Container Test
Run this inside the Hermes container:
```bash
curl http://host.docker.internal:18642/health
```

## Security Note
Keep `HERMES_API_BIND_HOST` and `HERMES_DASHBOARD_BIND_HOST` set to `127.0.0.1` unless you have explicitly configured a firewall and authentication. Do not bind reverse tunnels to `0.0.0.0` unless you intend to expose them publicly.
