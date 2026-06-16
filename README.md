# Hermes Setup

Monorepo for running Hermes in a Docker Compose environment with an extended image that includes:

- 1Password CLI (`op`)
- Neovim
- Nano
- Whisper (`openai-whisper` CLI)

This setup follows the official Hermes Agent Docker guide:

https://hermes-agent.nousresearch.com/docs/user-guide/docker

## Repository Layout

```text
.
├── compose.yaml
├── containers/
│   └── hermes/
│       └── Dockerfile
└── docs/
    └── hermes-docker.md
```

## Quick Start

```sh
cp .env.example .env
docker compose build --pull hermes
docker compose run --rm hermes setup
docker compose up -d
```

By default, Hermes state is stored on the host at `${HOME}/.hermes` and mounted into the container at `/opt/data`.

Ports are configurable in `.env`:

- `8642` exposes the gateway OpenAI-compatible API server when `API_SERVER_ENABLED=true`.
- `9119` exposes the dashboard when `HERMES_DASHBOARD=1`.

See [`docs/hermes-docker.md`](docs/hermes-docker.md) for setup, usage, and upgrade instructions.
