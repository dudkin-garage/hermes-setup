# Hermes Docker Environment

This repository builds a derived Hermes Agent image from the official Docker image and adds durable tooling for local operation.

Official reference:

https://hermes-agent.nousresearch.com/docs/user-guide/docker

## What This Image Adds

- 1Password CLI (`op`)
- Neovim
- Nano
- Whisper (`openai-whisper`)

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

The default bind host is loopback-only. Use `make tunnel` from your local machine to reach these VPS-local ports over SSH instead of exposing them publicly.

The example environment enables the API server so it can accept requests through the SSH tunnel:

```sh
API_SERVER_ENABLED=true
API_SERVER_HOST=0.0.0.0
API_SERVER_KEY=<minimum-8-character-secret>
API_SERVER_CORS_ORIGINS=http://127.0.0.1:19119,http://localhost:19119
```

Generate a key with:

```sh
openssl rand -hex 32
```

The example environment also enables the Hermes dashboard:

```sh
HERMES_DASHBOARD=1
HERMES_DASHBOARD_INSECURE=1
```

Do not expose the dashboard publicly without configuring dashboard authentication. `HERMES_DASHBOARD_INSECURE=1` disables the auth gate and should only be used on trusted networks, loopback-only Docker bindings, or behind your own auth layer.

## SSH Tunnel

Configure your VPS SSH endpoint in `.env`:

```sh
VPS_HOST=h2.dudkin-garage.com
VPS_SSH_USER=worker
VPS_SSH_PORT=22
```

Open both the dashboard and API tunnels:

```sh
make tunnel
```

Local URLs:

```sh
http://127.0.0.1:19119  # dashboard
http://127.0.0.1:18642  # API
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

## Verify Installed Tools

Inside the container, verify the installed tools:

```sh
op --version
nvim --version
nano --version
whisper --help
```

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
