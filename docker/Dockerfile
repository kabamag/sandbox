# syntax=docker/dockerfile:1
# Entwicklungs-Sandbox mit opencode und GitHub-Anbindung

# ---------------------------------------------------------------- MCP-Builder
# Der GitHub-MCP-Server wird aus dem Quelltext uebersetzt und als einzelnes
# Binary uebernommen. So braucht die Sandbox keinen Docker-Socket.
ARG GITHUB_MCP_VERSION=latest
FROM golang:1-trixie AS mcpbuild
ARG GITHUB_MCP_VERSION
ENV CGO_ENABLED=0
RUN go install "github.com/github/github-mcp-server/cmd/github-mcp-server@${GITHUB_MCP_VERSION}" \
 && test -x /go/bin/github-mcp-server

# ---------------------------------------------------------------- Sandbox
FROM debian:trixie-slim

ARG TZ=Europe/Berlin
ARG USER_UID=1000
ARG USER_GID=1000
ARG INSTALL_NODE=true
ARG NODE_MAJOR=22
ARG INSTALL_PYTHON=true
ARG INSTALL_GO=true
ARG GO_VERSION=
ARG INSTALL_RUST=false
ARG INSTALL_DOTNET=false
ARG DOTNET_VERSION=
ARG ENABLE_SUDO=true
ARG INSTALL_OPENCODE=true
ARG OPENCODE_VERSION=
ARG INSTALL_CLAUDE=true
ARG CLAUDE_CODE_VERSION=
ARG INSTALL_HERDR_TUI=false
ARG INSTALL_STARSHIP=true
ARG STARSHIP_VERSION=
ARG EXTRA_APT_PACKAGES=

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# ---------------------------------------------------------------- Basiswerkzeug
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl wget gnupg \
      git git-lfs lazygit openssh-client \
      bash-completion less nano vim-tiny tmux \
      procps psmisc htop lsof \
      ripgrep jq unzip zip xz-utils tar file tree \
      build-essential pkg-config make cmake \
      sudo tzdata \
      fd-find \
      ${EXTRA_APT_PACKAGES} \
 && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
 && ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone \
 && rm -rf /var/lib/apt/lists/*

ENV TZ=${TZ}

# ---------------------------------------------------------------- GitHub CLI
RUN set -eux; \
    mkdir -p /etc/apt/keyrings; \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /etc/apt/keyrings/githubcli-archive-keyring.gpg; \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends gh; \
    rm -rf /var/lib/apt/lists/*; \
    gh --version

# ---------------------------------------------------------------- Node.js
RUN set -eux; \
    if [ "${INSTALL_NODE}" = "true" ]; then \
      curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - ; \
      apt-get install -y --no-install-recommends nodejs; \
      rm -rf /var/lib/apt/lists/*; \
      node --version; npm --version; \
    fi

# ---------------------------------------------------------------- Python
RUN set -eux; \
    if [ "${INSTALL_PYTHON}" = "true" ]; then \
      apt-get update; \
      apt-get install -y --no-install-recommends python3 python3-venv python3-pip pipx; \
      rm -rf /var/lib/apt/lists/*; \
      ln -sf /usr/bin/python3 /usr/local/bin/python; \
      python --version; \
    fi

# ---------------------------------------------------------------- Go
ENV PATH=/usr/local/go/bin:${PATH}
RUN set -eux; \
    if [ "${INSTALL_GO}" = "true" ]; then \
      arch="$(dpkg --print-architecture)"; \
      ver="${GO_VERSION}"; \
      if [ -z "${ver}" ]; then ver="$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -n1)"; fi; \
      case "${ver}" in go*) ;; *) ver="go${ver}";; esac; \
      curl -fsSL "https://go.dev/dl/${ver}.linux-${arch}.tar.gz" -o /tmp/go.tgz; \
      rm -rf /usr/local/go; \
      tar -C /usr/local -xzf /tmp/go.tgz; \
      rm -f /tmp/go.tgz; \
      /usr/local/go/bin/go version; \
    fi

# ---------------------------------------------------------------- Rust (optional)
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:${PATH}
RUN set -eux; \
    if [ "${INSTALL_RUST}" = "true" ]; then \
      curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile minimal; \
      chmod -R a+rwX "${CARGO_HOME}" "${RUSTUP_HOME}"; \
      rustc --version; \
    fi

# ---------------------------------------------------------------- .NET SDK (optional)
# Ohne DOTNET_VERSION wird das neueste stabile SDK (GA) aus der offiziellen
# Release-Liste ermittelt - unabhaengig davon, ob LTS oder STS.
# Das SDK liegt unter /usr/local/dotnet, der Aufruf laeuft ueber den Symlink.
ENV DOTNET_ROOT=/usr/local/dotnet \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1

RUN set -eux; \
    if [ "${INSTALL_DOTNET}" = "true" ]; then \
      wget "https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb; \
      dpkg -i packages-microsoft-prod.deb; \
      rm packages-microsoft-prod.deb; \
      apt-get update; \
      apt-get install -y dotnet-sdk-10.0; \
      dotnet --version; \
    fi

# ---------------------------------------------------------------- opencode
# Der offizielle Installer legt das Binary unter $HOME/.opencode/bin ab;
# es wird anschliessend nach /usr/local/bin verschoben, damit es fuer alle
# Nutzer im PATH liegt. Faellt der Installer aus, greift die npm-Variante.
RUN set -eux; \
    if [ "${INSTALL_OPENCODE}" != "true" ]; then \
      echo "opencode wird uebersprungen (INSTALL_OPENCODE=false)"; \
    else \
    if [ -n "${OPENCODE_VERSION}" ]; then export VERSION="${OPENCODE_VERSION}"; fi; \
    if curl -fsSL https://raw.githubusercontent.com/anomalyco/opencode/refs/heads/v2/install | bash; then \
      cp -a "${HOME:-/root}/.opencode/bin/." /usr/local/bin/; \
      rm -rf "${HOME:-/root}/.opencode"; \
    elif [ "${INSTALL_NODE}" = "true" ]; then \
      npm install -g "opencode-ai${OPENCODE_VERSION:+@${OPENCODE_VERSION}}"; \
    else \
      echo "opencode konnte nicht installiert werden" >&2; exit 1; \
    fi; \
    chmod 0755 /usr/local/bin/opencode 2>/dev/null || true; \
    opencode --version; \
    fi

# ---------------------------------------------------------------- Claude Code CLI
RUN set -eux; \
    if [ "${INSTALL_CLAUDE}" = "true" ]; then \
      if [ "${INSTALL_NODE}" != "true" ]; then \
        echo "Claude Code benoetigt Node.js - INSTALL_NODE=true setzen" >&2; exit 1; \
      fi; \
      npm install -g "@anthropic-ai/claude-code${CLAUDE_CODE_VERSION:+@${CLAUDE_CODE_VERSION}}"; \
      claude --version; \
    fi

# ---------------------------------------------------------------- herdr tui (optional)
# Prebuiltes Binary ueber das offizielle Install-Skript (benoetigt curl + gawk);
# keine Rust-Toolchain noetig. Wird unter /usr/local/bin installiert und steht
# allen Nutzern zur Verfuegung.
RUN set -eux; \
    if [ "${INSTALL_HERDR_TUI}" = "true" ]; then \
      apt-get update; \
      apt-get install -y --no-install-recommends gawk; \
      rm -rf /var/lib/apt/lists/*; \
      export HERDR_INSTALL_DIR=/usr/local/bin; \
      curl -fsSL https://herdr.dev/install.sh | sh; \
      herdr --version; \
    fi

# ---------------------------------------------------------------- Starship
# Einzelnes Binary ueber das offizielle Install-Skript; landet in /usr/local/bin
# und wird von den bash-Konfigurationen als Prompt geladen.
RUN set -eux; \
    if [ "${INSTALL_STARSHIP}" = "true" ]; then \
      set -- --yes --bin-dir /usr/local/bin; \
      if [ -n "${STARSHIP_VERSION}" ]; then set -- "$@" --version "${STARSHIP_VERSION}"; fi; \
      curl -fsSL https://starship.rs/install.sh | sh -s -- "$@"; \
      starship --version; \
    fi

# ---------------------------------------------------------------- GitHub-MCP-Server
COPY --from=mcpbuild /go/bin/github-mcp-server /usr/local/bin/github-mcp-server
RUN chmod 0755 /usr/local/bin/github-mcp-server

# ---------------------------------------------------------------- Benutzer
RUN set -eux; \
    if ! getent group "${USER_GID}" >/dev/null; then groupadd -g "${USER_GID}" dev; fi; \
    if ! getent passwd "${USER_UID}" >/dev/null; then \
      useradd -m -u "${USER_UID}" -g "${USER_GID}" -s /bin/bash dev; \
    else \
      existing="$(getent passwd "${USER_UID}" | cut -d: -f1)"; \
      [ "${existing}" = "dev" ] || usermod -l dev -d /home/dev -m "${existing}"; \
    fi; \
    if [ "${ENABLE_SUDO}" = "true" ]; then \
      echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-dev; \
      chmod 0440 /etc/sudoers.d/90-dev; \
    fi; \
    mkdir -p /work \
             /home/dev/.config/opencode \
             /home/dev/.config/gh \
             /home/dev/.local/share/opencode \
             /home/dev/.claude/commands \
             /home/dev/.claude/skills \
             /home/dev/.agents/skills \
             /opt/agent-commands \
             /home/dev/.local/bin \
             /home/dev/.npm-global/bin \
             /home/dev/.cache \
             /home/dev/go/pkg; \
    chown -R "${USER_UID}:${USER_GID}" /work /home/dev /opt/agent-commands

# .bashrc fuer den dev User (wird bei interaktiven Nicht-Login-Shells geladen,
# im Gegensatz zu /etc/profile.d/*)
COPY --chown="${USER_UID}:${USER_GID}" bashrc.d/dev-bashrc /home/dev/.bashrc

# ~/.profile fuer sh/dash Login-Shells (herdr koennte sh statt bash starten)
COPY --chown="${USER_UID}:${USER_GID}" bashrc.d/dev-profile /home/dev/.profile

# Sandbox-Prompt fuer alle interaktiven bash-Shells. /etc/bash.bashrc wird auf
# Debian bei jeder interaktiven bash geladen (auch bei Non-Login-Shells wie
# 'docker exec ... bash').
COPY bashrc.d/bash.bashrc-sandbox /etc/bash.bashrc.d/sandbox-prompt
COPY bashrc.d/starship-prompt.sh /etc/bash.bashrc.d/starship-prompt
RUN echo 'if [ -f /etc/bash.bashrc.d/sandbox-prompt ]; then . /etc/bash.bashrc.d/sandbox-prompt; fi' >> /etc/bash.bashrc \
 && echo 'if [ -f /etc/bash.bashrc.d/starship-prompt ]; then . /etc/bash.bashrc.d/starship-prompt; fi' >> /etc/bash.bashrc

# Ebenfalls direkt in /etc/profile eintragen, damit der Prompt auch bei
# Login-Shells (z. B. 'docker compose exec ... bash -l' ueber sandbox.ps1)
# korrekt gesetzt wird. Zudem SHELL auf bash setzen, damit herdr (falls es
# $SHELL ausliest) moeglichst bash statt sh/dash startet.
RUN echo 'export PS1="\[\e]0;\u@\h: \w\a\]\[\033[01;32m\]sandbox\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> /etc/profile \
 && echo 'export SHELL=/bin/bash' >> /etc/profile \
 && echo 'if [ -f /etc/bash.bashrc.d/starship-prompt ]; then . /etc/bash.bashrc.d/starship-prompt; fi' >> /etc/profile

# Kopierte Konfigurationsdateien auf LF-Zeilenumbrueche normalisieren
# (Windows-CRLF wuerde die Escape-Sequenzen im Prompt zerstoeren).
RUN sed -i 's/\r$//' /home/dev/.bashrc /home/dev/.profile /etc/bash.bashrc.d/sandbox-prompt /etc/bash.bashrc.d/starship-prompt /etc/profile 2>/dev/null || true

ENV HOME=/home/dev \
    GOPATH=/home/dev/go \
    CLAUDE_CONFIG_DIR=/home/dev/.claude \
    PATH=/home/dev/.npm-global/bin:/home/dev/.local/bin:/home/dev/go/bin:/usr/local/go/bin:/usr/local/cargo/bin:/usr/local/bin:/usr/bin:/bin \
    NPM_CONFIG_PREFIX=/home/dev/.npm-global

# Wichtig: absolute Rechte setzen, nicht "chmod +x". COPY uebernimmt die
# Rechte der Quelldatei vom Host - liegt sie dort als 0600/0700, waere das
# Ergebnis nur fuer root lesbar und der Container startet nicht.
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY bashrc.d/sandbox.sh /etc/profile.d/zz-sandbox.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh \
 && chmod 0644 /etc/profile.d/zz-sandbox.sh \
 && chown root:root /usr/local/bin/entrypoint.sh /etc/profile.d/zz-sandbox.sh

USER dev
WORKDIR /work

# Ueber bash aufgerufen: so genuegt Leserecht, das Ausfuehrungsbit allein
# waere eine weitere Stolperstelle.
ENTRYPOINT ["/bin/bash", "/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
