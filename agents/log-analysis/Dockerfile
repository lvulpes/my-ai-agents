# Offline log tooling on top of either tool base (goose or claude-code). The
# bases differ (goose: plain Debian, user `agent`; claude-code: Node, user `node`),
# but both are Debian with uid 1000, so this file only uses apt and `USER 1000`.
# Logs only: pcaps belong to the network-forensics job (tshark).
FROM base

USER root
ENV DEBIAN_FRONTEND=noninteractive
# jq: JSON/JSONL (Suricata eve.json, agent traces); miller (mlr): CSV/TSV/JSON
# tables (Zeek, proxy logs); ripgrep/gawk: fast filtering; sqlite3: agent
# frameworks that log to SQLite; the decompressors read rotated logs in place
RUN apt-get update && apt-get install -y --no-install-recommends \
      jq \
      miller \
      ripgrep \
      gawk \
      sqlite3 \
      file \
      gzip bzip2 xz-utils zstd unzip \
      python3 \
      python3-venv \
 && rm -rf /var/lib/apt/lists/*

# Separate venv so the analysis libs can't clash with the tool's own deps.
# It comes first on PATH, so `python3` is the analysis env.
# duckdb: SQL straight over big CSV/JSON/Parquet files; python-evtx: Windows .evtx
RUN python3 -m venv /opt/logtools \
 && /opt/logtools/bin/pip install --no-cache-dir \
      duckdb \
      pandas \
      pyarrow \
      python-evtx \
      pyyaml
ENV PATH="/opt/logtools/bin:$PATH"

USER 1000
WORKDIR /work
