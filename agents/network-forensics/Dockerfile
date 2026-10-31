# Offline pcap tooling on top of either tool base (aider or goose). Reads
# captures only, never captures (no NET_RAW). Both bases are Debian with user
# `agent`. Python is installed explicitly so this also layers on the goose base
# (plain Debian); the aider base already ships Python but we don't rely on it.
FROM base

USER root
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      tshark \
      tcpdump \
      libpcap-dev \
      gcc \
      python3 \
      python3-venv \
 && rm -rf /var/lib/apt/lists/*

# Separate venv so the analysis libs can't clash with the tool's own deps.
# It comes first on PATH, so `python` in /work/cases is the analysis env.
RUN python3 -m venv /opt/forensics \
 && /opt/forensics/bin/pip install --no-cache-dir \
      scapy \
      pyshark \
      dpkt \
      pandas \
      ja4plus
ENV PATH="/opt/forensics/bin:$PATH"

USER agent
WORKDIR /work/cases
