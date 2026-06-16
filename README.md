# Hermes Setup

Monorepo for running Hermes in a Docker Compose environment with an extended image that includes:

- 1Password CLI (`op`)
- Neovim
- Nano
- Whisper (`openai-whisper` CLI)

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
docker compose run --rm hermes
```

Set `HERMES_IMAGE` in `.env` if the upstream Hermes image is not available locally as `hermes:latest`.

See [`docs/hermes-docker.md`](docs/hermes-docker.md) for setup, usage, and upgrade instructions.
