# Hermes Docker Environment

This repository builds a local Hermes development image from the latest Hermes base image and adds common tools used inside the container.

## Prerequisites

- Docker with Docker Compose v2
- Access to the upstream Hermes Docker image
- Optional: 1Password account or service account token if you need `op` inside the container

## Configure the Hermes Base Image

Copy the environment template:

```sh
cp .env.example .env
```

Set `HERMES_IMAGE` to the upstream Hermes image you want to extend:

```sh
HERMES_IMAGE=hermes:latest
```

If Hermes is published in a registry, use the full image name instead:

```sh
HERMES_IMAGE=ghcr.io/example/hermes:latest
```

The Dockerfile expects the Hermes base image to be Debian or Ubuntu based because it installs packages with `apt-get` and uses the official 1Password Debian repository.

## Build

Build the extended Hermes image:

```sh
docker compose build --pull hermes
```

The resulting local image name is controlled by `HERMES_SETUP_IMAGE` in `.env` and defaults to:

```sh
dudkin-garage/hermes-setup:local
```

## Run

Open an interactive shell:

```sh
docker compose run --rm hermes
```

The current repository is mounted at `/workspace`. A named Docker volume persists `/root` between runs so shell history, editor config, and 1Password CLI session files can survive container restarts.

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

## Updating Hermes Later

If you track `latest`, pull the newest base image and rebuild:

```sh
docker compose build --pull --no-cache hermes
```

If you pin Hermes versions, update `HERMES_IMAGE` in `.env`:

```sh
HERMES_IMAGE=ghcr.io/example/hermes:1.2.3
```

Then rebuild:

```sh
docker compose build --pull hermes
```

Commit version changes if `.env.example`, `compose.yaml`, or `containers/hermes/Dockerfile` changes. Do not commit local `.env` files containing tokens or account-specific settings.

## Updating Installed Tools

- 1Password CLI is installed from the official 1Password apt repository during image build.
- Neovim, Nano, Python, pipx, and ffmpeg come from the base operating system repositories.
- Whisper is installed with `pipx install openai-whisper`.

To refresh all installed tools, rebuild without cache:

```sh
docker compose build --pull --no-cache hermes
```

## Monorepo Notes

This repository is structured so additional apps, packages, or infrastructure can be added alongside `containers/` and `docs/` without changing the Hermes Docker workflow.
