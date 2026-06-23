# Hermes SSH Reverse Tunnel Setup

This setup enables SSH reverse tunneling from a Mac/local node to a Hermes Docker container on a Hetzner host.

## Mac Tunnel Command
Run this on your local machine:
```bash
ssh -N -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -R 172.17.0.1:18642:127.0.0.1:8642 worker@h2.dudkin-garage.com
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
Do not bind `-R 0.0.0.0:18642:...` unless you have explicitly configured a firewall or additional authentication, as this would expose the port to the public internet.
