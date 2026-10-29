# Generic aider image. Nothing job-specific here:
# jobs that need extra tools add a Dockerfile with `FROM base` on top of this.
# aider-chat requires Python >=3.10,<3.13
FROM python:3.12-slim

ARG AIDER_VERSION=0.86.2
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update && apt-get install -y --no-install-recommends \
      git ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv \
 && /opt/venv/bin/pip install "aider-chat==${AIDER_VERSION}"
ENV PATH="/opt/venv/bin:$PATH"

RUN useradd --create-home --uid 1000 --shell /bin/bash agent \
 && mkdir -p /work && chown agent:agent /work
USER agent
ENV HOME=/home/agent
WORKDIR /work
ENTRYPOINT ["aider"]
