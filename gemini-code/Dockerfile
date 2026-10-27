FROM node:22-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install system tools, tshark (with automatic prompt responses), and Python build tooling
RUN apt-get update && apt-get install -y --no-install-recommends \
    tshark \
    tcpdump \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    libpcap-dev \
    gcc \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create a virtual environment to avoid PEP 668 external-environment conflicts
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python PCAP libraries in the virtual environment
RUN pip install --no-cache-dir \
    scapy \
    pyshark \
    dpkt \
    pandas \
    ja4plus

RUN npm install -g @google/gemini-cli

WORKDIR /workspace
ENTRYPOINT ["gemini"]
