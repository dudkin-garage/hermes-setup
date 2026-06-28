# syntax=docker/dockerfile:1.7

ARG HERMES_IMAGE=nousresearch/hermes-agent:latest
FROM ${HERMES_IMAGE}

USER root

ENV DEBIAN_FRONTEND=noninteractive \
    OBSIDIAN_VAULTS_DIR=/workspace/obsidian-vaults \
    NEUTTS_VENV=/opt/neutts-venv \
    NEUTTS_MODELS_DIR=/opt/models/neutts \
    HF_HOME=/opt/models/neutts/huggingface \
    HUGGINGFACE_HUB_CACHE=/opt/models/neutts/huggingface/hub \
    TORCH_HOME=/opt/models/neutts/torch \
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
      build-essential \
      cmake \
      curl \
      espeak-ng \
      ffmpeg \
      gnupg \
      libopenblas-dev \
      libsndfile1 \
      nano \
      ninja-build \
      neovim \
      pipx \
      pkg-config \
      python3 \
      python3-dev \
      python3-pip \
      python3-venv; \
    install -d -m 0755 /usr/share/keyrings; \
    curl -fsSL https://downloads.1password.com/linux/keys/1password.asc -o /tmp/1password.asc; \
    gpg --dearmor -o /usr/share/keyrings/1password-archive-keyring.gpg /tmp/1password.asc; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" > /etc/apt/sources.list.d/1password.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends 1password-cli; \
    pipx install --pip-args='--no-cache-dir' obsidian-cli; \
    pipx install --pip-args='--no-cache-dir' openai-whisper; \
    python3 -m venv "${NEUTTS_VENV}"; \
    "${NEUTTS_VENV}/bin/pip" install --no-cache-dir --upgrade pip setuptools wheel; \
    CMAKE_ARGS='-DGGML_BLAS=ON -DGGML_BLAS_VENDOR=OpenBLAS' "${NEUTTS_VENV}/bin/pip" install --no-cache-dir 'neutts[all]'; \
    ln -sf "${NEUTTS_VENV}/bin/python" /usr/local/bin/neutts-python; \
    ln -sf "${NEUTTS_VENV}/bin/pip" /usr/local/bin/neutts-pip; \
    install -d -m 0775 /workspace/obsidian-vaults; \
    install -d -m 0775 "${NEUTTS_MODELS_DIR}"; \
    rm -rf /var/lib/apt/lists/* /tmp/1password.asc

RUN set -eux; \
    rm -f /usr/local/bin/neutts-python /usr/local/bin/neutts-pip; \
    printf '%s\n' '#!/bin/sh' 'unset TRANSFORMERS_CACHE' 'exec "${NEUTTS_VENV:-/opt/neutts-venv}/bin/python" "$@"' > /usr/local/bin/neutts-python; \
    printf '%s\n' '#!/bin/sh' 'unset TRANSFORMERS_CACHE' 'exec "${NEUTTS_VENV:-/opt/neutts-venv}/bin/pip" "$@"' > /usr/local/bin/neutts-pip; \
    chmod 0755 /usr/local/bin/neutts-python /usr/local/bin/neutts-pip

WORKDIR /workspace
