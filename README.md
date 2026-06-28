# Hermes Dashboard And Tunnel Setup

This setup runs Hermes in Docker on a VPS, exposes the Hermes dashboard through Cloudflare Tunnel with Cloudflare Access OIDC, and keeps the API reachable through SSH tunnels.

## Environment

Set the VPS SSH endpoint in `.env`:

```bash
VPS_HOST=h2.dudkin-garage.com
VPS_SSH_USER=worker
VPS_SSH_PORT=22
```

Hermes is configured to keep the API and dashboard host ports on VPS loopback by default:

```bash
HERMES_API_BIND_HOST=127.0.0.1
HERMES_DASHBOARD_BIND_HOST=127.0.0.1
```

## Cloudflare Tunnel

The public dashboard URL is:

```bash
https://hermes-h2.dudkin-garage.com
```

Create the tunnel in Cloudflare:

1. Open **Cloudflare Zero Trust**.
2. Go to **Networks** -> **Tunnels**.
3. Click **Create a tunnel**.
4. Select **Cloudflared**.
5. Name it `hermes-h2`.
6. Choose **Docker** as the connector environment.
7. Copy the generated tunnel token.

Set the token in `.env` on the VPS:

```bash
CLOUDFLARE_TUNNEL_TOKEN=<cloudflare-generated-token>
```

Add a public hostname to the tunnel in Cloudflare:

```bash
Subdomain: hermes-h2
Domain: dudkin-garage.com
Path: <empty>
Service Type: HTTP
Service URL: hermes:9119
```

That routes Cloudflare public HTTPS traffic to the private Docker service URL:

```bash
https://hermes-h2.dudkin-garage.com -> http://hermes:9119
```

No public `80`, `443`, or `9119` inbound ports are required on the VPS for the dashboard when using Cloudflare Tunnel.

## Dashboard OIDC

Create the OIDC application in Cloudflare Access:

1. Open **Cloudflare Zero Trust**.
2. Go to **Access controls** -> **Applications**.
3. Click **Create new application**.
4. Select **SaaS application**.
5. Enter a custom application name, for example `Hermes Dashboard`.
6. Select **OIDC**.
7. Add this redirect URL:

```bash
https://hermes-h2.dudkin-garage.com/auth/callback
```

8. Select the `openid`, `email`, and `profile` scopes.
9. Add an Access policy that allows the users or groups that should reach Hermes.
10. Copy the generated **Issuer** and **Client ID** values.

Cloudflare's issuer has this shape:

```bash
https://<your-team-name>.cloudflareaccess.com/cdn-cgi/access/sso/oidc/<cloudflare-access-oidc-client-id>
```

Set these Hermes dashboard values in `.env`:

```bash
HERMES_DASHBOARD=1
HERMES_DASHBOARD_INSECURE=0
HERMES_DASHBOARD_PUBLIC_URL=https://hermes-h2.dudkin-garage.com
HERMES_DASHBOARD_OIDC_ISSUER=https://<your-team-name>.cloudflareaccess.com/cdn-cgi/access/sso/oidc/<cloudflare-access-oidc-client-id>
HERMES_DASHBOARD_OIDC_CLIENT_ID=<cloudflare-access-oidc-client-id>
HERMES_DASHBOARD_OIDC_SCOPES="openid email profile"
```

Cloudflare also shows a client secret for the OIDC SaaS application. If Hermes asks for an OIDC client secret in its dashboard setup, copy that value from Cloudflare into the corresponding Hermes setting.

The OIDC configuration endpoint is useful for troubleshooting provider discovery:

```bash
https://<your-team-name>.cloudflareaccess.com/cdn-cgi/access/sso/oidc/<cloudflare-access-oidc-client-id>/.well-known/openid-configuration
```

Start or recreate the stack after updating `.env`:

```bash
docker compose up -d
```

## API Tunnel

Run this on your local machine when you need API access:

```bash
make tunnel-api
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
Keep `HERMES_API_BIND_HOST` and `HERMES_DASHBOARD_BIND_HOST` set to `127.0.0.1`. Keep `HERMES_DASHBOARD_INSECURE=0` for public dashboard access. Do not bind reverse tunnels to `0.0.0.0` unless you intend to expose them publicly.
