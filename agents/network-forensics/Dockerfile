# aider + offline pcap tooling. Reads captures only, never captures (no NET_RAW).
FROM base

USER root
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      tshark \
      tcpdump \
      libpcap-dev \
      gcc \
 && rm -rf /var/lib/apt/lists/*

# Separate venv so the analysis libs can't clash with aider's pinned deps.
# It comes first on PATH, so `python` in /run is the analysis env; aider keeps its own.
RUN python -m venv /opt/forensics \
 && /opt/forensics/bin/pip install \
      scapy \
      pyshark \
      dpkt \
      pandas \
      ja4plus
ENV PATH="/opt/forensics/bin:$PATH"

USER agent
WORKDIR /work/cases
