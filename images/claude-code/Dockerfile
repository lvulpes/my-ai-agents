# Generic Claude Code image (formerly claude-box). Nothing job-specific here:
# jobs that need extra tools add a Dockerfile with `FROM base` on top of this.
FROM node:24-bookworm-slim

ARG CLAUDE_CODE_VERSION=2.1.312
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      git ca-certificates procps ripgrep \
 && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} \
 && npm cache clean --force

# The node image already has user node (uid 1000)
RUN mkdir -p /work && chown node:node /work
USER node
ENV HOME=/home/node
WORKDIR /work
ENTRYPOINT ["claude"]
