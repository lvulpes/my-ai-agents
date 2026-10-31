# Dev tooling for code-architect, on top of either tool base (aider or claude-code).
# The bases differ (aider: Python, user `agent`; claude-code: Node, user `node`),
# but both are Debian with uid 1000, so this file only uses apt and `USER 1000`.
# No gh, kubectl or docker: commits/PRs and deploys stay with the user.
FROM base

USER root
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 python3-venv \
      shellcheck yamllint \
      jq curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# uv: official static binaries, copied from Astral's image (matches the build arch)
COPY --from=ghcr.io/astral-sh/uv:0.9.5 /uv /uvx /usr/local/bin/

# helm: pinned release from get.helm.sh, checked against its published sha256
ARG HELM_VERSION=v3.19.0
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    tgz="helm-${HELM_VERSION}-linux-${arch}.tar.gz"; \
    tmp="$(mktemp -d)"; \
    curl -fsSL "https://get.helm.sh/${tgz}" -o "$tmp/${tgz}"; \
    curl -fsSL "https://get.helm.sh/${tgz}.sha256sum" -o "$tmp/${tgz}.sha256sum"; \
    (cd "$tmp" && sha256sum -c "${tgz}.sha256sum"); \
    tar -xzf "$tmp/${tgz}" -C "$tmp"; \
    install -m 0755 "$tmp/linux-${arch}/helm" /usr/local/bin/helm; \
    rm -rf "$tmp"; \
    helm version

USER 1000
WORKDIR /work
