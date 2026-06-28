# Hermes Docker Environment

This repository builds a derived Hermes Agent image from the official Docker image and adds durable tooling for local operation.

Official reference:

https://hermes-agent.nousresearch.com/docs/user-guide/docker

## What This Image Adds

- 1Password CLI (`op`)
- Neovim
- Nano
- Obsidian CLI (`obsidian`)
- Whisper (`openai-whisper`)
- NeuTTS (`neutts`) in `/opt/neutts-venv`, with `neutts-python` and `neutts-pip` wrappers

The base image defaults to `nousresearch/hermes-agent:latest` and can be changed with `HERMES_IMAGE` in `.env`.

## Prerequisites

- Docker with Docker Compose v2
- Access to `nousresearch/hermes-agent:latest`
- Optional: 1Password account or service account token if you need `op` inside the container

## Persistent Data

Hermes stores config, API keys, sessions, skills, memories, logs, and per-profile home directories under `/opt/data` inside the container.

This Compose setup maps that to the host directory configured by `HERMES_DATA_DIR`, which defaults to:

```sh
${HOME}/.hermes
```

Never run two Hermes gateway containers against the same data directory at the same time.

Obsidian vaults are mounted separately from Hermes runtime data. Configure the host directory with:

```sh
OBSIDIAN_VAULTS_HOST_DIR=${HOME}/obsidian-vaults
OBSIDIAN_VAULTS_CONTAINER_DIR=/workspace/obsidian-vaults
```

Inside the Hermes container, the vault directory is available as:

```sh
$OBSIDIAN_VAULTS_DIR
```

The default container path is `/workspace/obsidian-vaults`.

NeuTTS model weights and Hugging Face/Torch caches are mounted separately from the image at:

```sh
/opt/models/neutts
```

Compose stores that directory in the named Docker volume configured by `NEUTTS_MODELS_VOLUME`, which defaults to:

```sh
hermes-neutts-models
```

## First-Time Setup

Create your environment file:

```sh
cp .env.example .env
```

Build the derived image:

```sh
docker compose build --pull hermes
```

Run the setup wizard once:

```sh
docker compose run --rm hermes setup
```

This writes Hermes configuration and secrets to `${HERMES_DATA_DIR}/.env`.

## Gateway Mode

Start Hermes as a persistent gateway:

```sh
docker compose up -d
```

View logs:

```sh
docker compose logs -f hermes
```

Stop it:

```sh
docker compose down
```

## Ports

Hermes uses two primary ports in Docker:

- `8642`: gateway OpenAI-compatible API server and health endpoint
- `9119`: web dashboard

Both are published by Compose with configurable host ports:

```sh
HERMES_API_BIND_HOST=127.0.0.1
HERMES_API_HOST_PORT=8642
HERMES_DASHBOARD_BIND_HOST=127.0.0.1
HERMES_DASHBOARD_HOST_PORT=9119
```

The API bind host is loopback-only by default. Use `make tunnel-api` from your local machine to reach the VPS-local API port over SSH instead of exposing it publicly.

The example environment enables the API server so it can accept requests through the SSH tunnel:

```sh
API_SERVER_ENABLED=true
API_SERVER_HOST=0.0.0.0
API_SERVER_KEY=<minimum-8-character-secret>
API_SERVER_CORS_ORIGINS=https://hermes-h2.dudkin-garage.com,http://127.0.0.1:19119,http://localhost:19119
```

Generate a key with:

```sh
openssl rand -hex 32
```

The example environment also enables the Hermes dashboard:

```sh
HERMES_DASHBOARD=1
HERMES_DASHBOARD_INSECURE=0
HERMES_DASHBOARD_PUBLIC_URL=https://hermes-h2.dudkin-garage.com
HERMES_DASHBOARD_OIDC_ISSUER=https://<your-team-name>.cloudflareaccess.com/cdn-cgi/access/sso/oidc/<cloudflare-access-oidc-client-id>
HERMES_DASHBOARD_OIDC_CLIENT_ID=<cloudflare-access-oidc-client-id>
HERMES_DASHBOARD_OIDC_SCOPES="openid email profile"
```

## Cloudflare Tunnel

The Compose stack includes a `cloudflared` connector so the dashboard can be exposed without opening public inbound ports on the VPS.

Create the tunnel in Cloudflare:

1. Open **Cloudflare Zero Trust**.
2. Go to **Networks** -> **Tunnels**.
3. Click **Create a tunnel**.
4. Select **Cloudflared**.
5. Name it `hermes-h2`.
6. Choose **Docker** as the connector environment.
7. Copy the generated tunnel token.

Set the token in `.env` on the VPS:

```sh
CLOUDFLARE_TUNNEL_TOKEN=<cloudflare-generated-token>
```

Add this public hostname to the tunnel in Cloudflare:

```sh
Subdomain: hermes-h2
Domain: dudkin-garage.com
Path: <empty>
Service Type: HTTP
Service URL: hermes:9119
```

That routes:

```sh
https://hermes-h2.dudkin-garage.com -> http://hermes:9119
```

No public `80`, `443`, or `9119` inbound ports are required on the VPS for the dashboard when using Cloudflare Tunnel.

Create the OIDC application in Cloudflare Access:

1. Open **Cloudflare Zero Trust**.
2. Go to **Access controls** -> **Applications**.
3. Click **Create new application**.
4. Select **SaaS application**.
5. Enter a custom application name, for example `Hermes Dashboard`.
6. Select **OIDC**.
7. Add this redirect URL:

```sh
https://hermes-h2.dudkin-garage.com/auth/callback
```

8. Select the `openid`, `email`, and `profile` scopes.
9. Add an Access policy that allows the users or groups that should reach Hermes.
10. Configure the OIDC client as a public client that uses authorization code flow with PKCE S256.
11. Disable any requirement for a client secret. Hermes' self-hosted OIDC provider does not support confidential clients yet.
12. Copy the generated **Issuer** and **Client ID** values into `.env`.

Cloudflare's issuer has this shape:

```sh
https://<your-team-name>.cloudflareaccess.com/cdn-cgi/access/sso/oidc/<cloudflare-access-oidc-client-id>
```

Do not configure Hermes with a Cloudflare OIDC client secret. If Cloudflare only offers a confidential client for this app, it is not compatible with Hermes dashboard OIDC; the token exchange will fail after sign-in.

The OIDC configuration endpoint is useful for troubleshooting provider discovery:

```sh
https://<your-team-name>.cloudflareaccess.com/cdn-cgi/access/sso/oidc/<cloudflare-access-oidc-client-id>/.well-known/openid-configuration
```

Do not expose the dashboard publicly without configuring dashboard authentication. Keep `HERMES_DASHBOARD_INSECURE=0` for public access.

## SSH Tunnel

Configure your VPS SSH endpoint in `.env`:

```sh
VPS_HOST=h2.dudkin-garage.com
VPS_SSH_USER=worker
VPS_SSH_PORT=22
```

Open the API tunnel:

```sh
make tunnel-api
```

Local API URL:

```sh
http://127.0.0.1:18642
```

## Interactive CLI

Run an interactive Hermes session against the same data directory:

```sh
docker compose run --rm hermes hermes
```

Run a shell in the image:

```sh
docker compose run --rm hermes bash
```

## Generated Slack Manifest

`manifests/slack/hermes-generated-manifest.json` is a captured copy of the Slack app manifest generated by Hermes Agent from inside the container. It is committed as a reference artifact for Slack app setup. Before importing it into Slack, replace placeholder callback URLs such as `https://hermes-agent.local/slack/commands` with the public Slack webhook URL for your deployment.

## Verify Installed Tools

Inside the container, verify the installed tools:

```sh
op --version
obsidian --help
nvim --version
nano --version
whisper --help
neutts-python -c 'from neutts import NeuTTS; print("NeuTTS import ok")'
```

## Obsidian Vaults

Create or store vaults under the mounted vault directory so Hermes can read and update them:

```sh
docker compose run --rm hermes sh -lc 'obsidian new "$OBSIDIAN_VAULTS_DIR/my-vault"'
docker compose run --rm hermes obsidian ls -l
```

On the host, the same files are stored under `${OBSIDIAN_VAULTS_HOST_DIR}`.

## 1Password CLI

For interactive use, sign in from inside the container:

```sh
op signin
```

For automation, set `OP_SERVICE_ACCOUNT_TOKEN` in your local `.env`. Do not commit `.env`; it is ignored by Git.

## Whisper

Whisper is installed from the `openai-whisper` Python package through `pipx`. `ffmpeg` is installed because Whisper requires it for audio processing.

Example:

```sh
whisper audio.mp3 --model small
```

## NeuTTS

NeuTTS is installed in an isolated Python virtual environment at `/opt/neutts-venv`. Use the `neutts-python` wrapper so it can import the bundled package without changing Hermes' Python environment.

The image installs the `neutts[all]` extras, including `onnxruntime` and `llama-cpp-python` compiled with OpenBLAS for CPU inference. Downloaded model files are not baked into the image; Hugging Face and Torch caches are directed to `${NEUTTS_MODELS_DIR}`, which Compose mounts from the `NEUTTS_MODELS_VOLUME` named volume.

Example import check:

```sh
docker compose run --rm --no-deps --entrypoint /bin/sh hermes -lc 'neutts-python -c "from neutts import NeuTTS; print(\"NeuTTS import ok\")"'
```

The first real synthesis run will download model weights into the `hermes-neutts-models` volume unless you change `NEUTTS_MODELS_VOLUME` in `.env`.

## Multi-Profile Notes

The official image uses s6 supervision and supports multiple Hermes profiles inside one container. Create and manage profiles with `docker exec`:

```sh
docker exec hermes hermes profile create coder
docker exec hermes hermes -p coder gateway start
docker exec hermes hermes -p coder gateway status
```

If a second profile needs its own OpenAI-compatible API endpoint, configure a unique `API_SERVER_PORT` in that profile's own `.env` and publish that extra port in `compose.yaml`.

## Updating Hermes Later

If you track `latest`, pull the newest base image and recreate the container:

```sh
docker compose pull
docker compose up -d --build
```

For a clean rebuild of the derived image:

```sh
docker compose build --pull --no-cache hermes
docker compose up -d --force-recreate
```

If you pin Hermes versions, update `HERMES_IMAGE` in `.env`:

```sh
HERMES_IMAGE=nousresearch/hermes-agent:<version>
```

Then rebuild:

```sh
docker compose build --pull hermes
docker compose up -d
```

Your `${HERMES_DATA_DIR}` directory is preserved across image upgrades. Hermes may run non-interactive config migrations on startup and writes backups next to config files when needed.

## Resource Limits

The official guide recommends at least 1 GB memory and 1 CPU, with 2-4 GB memory and 2 CPUs preferred when browser automation is used. Compose currently applies:

```yaml
memory: 4G
cpus: "2.0"
```

The service also sets `shm_size: 1g` for Playwright/Chromium stability.

## Monorepo Notes

This repository is structured so additional apps, packages, or infrastructure can be added alongside `containers/` and `docs/` without changing the Hermes Docker workflow.
