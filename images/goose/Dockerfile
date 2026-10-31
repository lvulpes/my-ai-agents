# Generic Goose image. Nothing job-specific here:
# jobs that need extra tools add a Dockerfile with `FROM base` on top of this.
# Goose is a CLI agent that plans and runs multi-step work and takes a provider
# + model separately, so it can drive open-weight models (Groq, Ollama,
# OpenRouter, ...) as well as hosted ones.
FROM debian:bookworm-slim

# Pin the Goose CLI release. GOOSE_VERSION is a tag from the releases page (keep
# the leading "v"). The repo was renamed from block/goose to aaif-goose/goose,
# which is where release assets are now served.
ARG GOOSE_VERSION=v1.57.0
ARG GOOSE_REPO=aaif-goose/goose
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      git ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

# Download the pinned CLI tarball directly (-L follows GitHub's redirect to the
# signed asset URL) and install the self-contained goose binary system-wide. The
# archive is flat (goose at its root); the glibc ("gnu") build matches the Debian
# base, so do not use the musl one.
RUN set -eux; \
    url="https://github.com/${GOOSE_REPO}/releases/download/${GOOSE_VERSION}/goose-x86_64-unknown-linux-gnu.tar.gz"; \
    tmp="$(mktemp -d)"; \
    curl -fL "$url" -o "$tmp/goose.tar.gz"; \
    tar -xzf "$tmp/goose.tar.gz" -C "$tmp"; \
    install -m 0755 "$tmp/goose" /usr/local/bin/goose; \
    rm -rf "$tmp"; \
    goose --version

RUN useradd --create-home --uid 1000 --shell /bin/bash agent \
 && mkdir -p /work && chown agent:agent /work

USER agent
# No system keyring in the container: Goose reads provider keys from the
# environment and stores any other secrets in its config file under $HOME.
ENV HOME=/home/agent \
    GOOSE_DISABLE_KEYRING=1

WORKDIR /work
ENTRYPOINT ["goose"]
