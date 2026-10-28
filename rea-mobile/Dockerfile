FROM node:24-bookworm-slim

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
      adb procps git ca-certificates default-jdk-headless \
 && rm -rf /var/lib/apt/lists/*
ENV REA_ADB_PATH=/usr/bin/adb
RUN npm install -g @anthropic-ai/claude-code

USER node
COPY --chown=node:node rea /opt/rea
RUN cd /opt/rea && npm ci && npm run build

WORKDIR /work
