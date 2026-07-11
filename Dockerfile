# code-server + Claude Code CLI + mise dev workspace image
# Thin base: build toolchain + mise + the `claude` CLI baked in; language
# RUNTIMES (Node/Java/Python/Go/...) are installed per-project via mise onto the
# persistent PVC at runtime — NOT baked here.
#
# NOTE: at runtime a PVC mounts over /home/coder, masking anything baked into it.
# Therefore all baked config goes to system paths (/etc, /usr) — never /home/coder.
FROM docker.io/codercom/code-server:4.127.0

USER root

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=Europe/Amsterdam

# --- system packages: build toolchain + fetch/extract tools + classic build libs ---
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates locales tzdata \
      build-essential python3 python3-venv pkg-config \
      git curl wget unzip tar gzip xz-utils openssh-client gnupg \
      libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libffi-dev liblzma-dev \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

# --- system Node LTS (22.x) — hosts the global `claude` CLI, decoupled from mise ---
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g @anthropic-ai/claude-code \
    && npm cache clean --force \
    && rm -rf /var/lib/apt/lists/*

# --- mise (binary system-wide; runtimes install to $HOME on the PVC at runtime) ---
RUN curl -fsSL https://mise.run | MISE_VERSION=v2026.7.5 MISE_INSTALL_PATH=/usr/local/bin/mise sh \
    && chmod 755 /usr/local/bin/mise

# --- PATH (process env, survives the PVC mount) + system-wide mise activation ---
# ~/.local/bin: user tools; mise shims: covers non-interactive spawns (VS Code tasks/debuggers)
ENV PATH="/home/coder/.local/bin:/home/coder/.local/share/mise/shims:${PATH}" \
    XDG_CACHE_HOME=/home/coder/.cache \
    NPM_CONFIG_CACHE=/home/coder/.cache/npm \
    PIP_CACHE_DIR=/home/coder/.cache/pip \
    GOCACHE=/home/coder/.cache/go-build \
    GOPATH=/home/coder/go \
    MISE_DATA_DIR=/home/coder/.local/share/mise
# PATH delivery across all shell types (files under /etc survive the PVC mount):
#  - ENV PATH above → non-login, non-interactive spawns (VS Code tasks/debuggers/LSPs)
#  - /etc/profile.d → LOGIN shells (Debian's /etc/profile resets PATH, so re-prepend here)
#  - mise activate in /etc/bash.bashrc → INTERACTIVE terminals (dynamic shims + tool env)
RUN printf 'export PATH="/home/coder/.local/bin:/home/coder/.local/share/mise/shims:$PATH"\n' > /etc/profile.d/00-mise-path.sh \
    && chmod 644 /etc/profile.d/00-mise-path.sh \
    && printf '\n# mise activation (code-server-claude image)\nif command -v mise >/dev/null 2>&1; then eval "$(mise activate bash)"; fi\n' >> /etc/bash.bashrc

USER coder
