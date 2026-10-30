# Claude Code + python/bash tooling for working on this repo.
FROM base

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 python3-venv python3-pip python3-yaml \
      shellcheck \
 && rm -rf /var/lib/apt/lists/*

USER node
