# syntax=docker/dockerfile:1.7

ARG HERMES_IMAGE=nousresearch/hermes-agent:latest
FROM ${HERMES_IMAGE}

USER root

ENV DEBIAN_FRONTEND=noninteractive \
    PIPX_HOME=/opt/pipx \
    PIPX_BIN_DIR=/usr/local/bin

RUN set -eux; \
    if ! command -v apt-get >/dev/null 2>&1; then \
      echo "This Dockerfile expects a Debian or Ubuntu based Hermes image with apt-get available." >&2; \
      exit 1; \
    fi; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      curl \
      ffmpeg \
      gnupg \
      nano \
      neovim \
      pipx \
      python3 \
      python3-pip \
      python3-venv; \
    install -d -m 0755 /usr/share/keyrings; \
    curl -fsSL https://downloads.1password.com/linux/keys/1password.asc -o /tmp/1password.asc; \
    gpg --dearmor -o /usr/share/keyrings/1password-archive-keyring.gpg /tmp/1password.asc; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" > /etc/apt/sources.list.d/1password.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends 1password-cli; \
    pipx install --pip-args='--no-cache-dir' openai-whisper; \
    rm -rf /var/lib/apt/lists/* /tmp/1password.asc

WORKDIR /workspace
