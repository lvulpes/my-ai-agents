# Ghidra 12.1.4 (the version REA verifies), checked against the release SHA-256
FROM debian:bookworm-slim AS ghidra
ARG GHIDRA_URL=https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_12.1.4_build/ghidra_12.1.4_PUBLIC_20260921.zip
ARG GHIDRA_SHA256=ddac49f903da9d5bac833e5cc79395098b9c33cfd3279be5f31bd00387d2d4db
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip \
 && curl -fsSL -o /tmp/ghidra.zip "$GHIDRA_URL" \
 && echo "$GHIDRA_SHA256  /tmp/ghidra.zip" | sha256sum -c - \
 && unzip -q /tmp/ghidra.zip -d /tmp/ghidra \
 && mv /tmp/ghidra/ghidra_* /opt/ghidra

# Binwalk 3.1 (what REA accepts) has no prebuilt release, so build it from crates.io
FROM rust:1-bookworm AS binwalk
RUN apt-get update && apt-get install -y --no-install-recommends libfontconfig1-dev liblzma-dev libbz2-dev \
 && cargo install binwalk --version 3.1.0 --locked --root /opt/binwalk

FROM base

USER root
# CLI tools for static work: multi-arch binutils, file/hex tools, and the
# extractors binwalk and unblob call for common firmware formats
RUN apt-get update && apt-get install -y --no-install-recommends \
      binutils binutils-multiarch file xxd bsdextrautils jq \
      python3 python3-venv \
      e2fsprogs squashfs-tools mtd-utils cpio unzip p7zip-full unar cabextract \
      bzip2 xz-utils lz4 lzop zstd lziprecover \
      device-tree-compiler u-boot-tools \
      libfontconfig1 liblzma5 libbz2-1.0 \
 && rm -rf /var/lib/apt/lists/*

# Ghidra 12.1 needs JDK 21+, bookworm only has 17: take Temurin 21 from its official image
COPY --from=eclipse-temurin:21-jdk /opt/java/openjdk /opt/java/openjdk
COPY --from=ghidra /opt/ghidra /opt/ghidra
COPY --from=binwalk /opt/binwalk/bin/binwalk /usr/local/bin/binwalk
ENV JAVA_HOME=/opt/java/openjdk \
    GHIDRA_INSTALL_DIR=/opt/ghidra
ENV PATH=/opt/re-tools/bin:$JAVA_HOME/bin:$PATH

# Python tools in their own venv: unblob 26.6 (what REA accepts) and libraries for scripting
RUN python3 -m venv /opt/re-tools \
 && /opt/re-tools/bin/pip install --no-cache-dir \
      unblob==26.6.4 capstone pyelftools lief pycryptodome z3-solver
ENV REA_BINWALK_COMMAND=/usr/local/bin/binwalk \
    REA_UNBLOB_COMMAND=/opt/re-tools/bin/unblob

USER node
COPY --chown=node:node rea /opt/rea
RUN cd /opt/rea && npm ci && npm run build
USER root
RUN ln -s /opt/rea/scripts/rea.mjs /usr/local/bin/rea
USER node

WORKDIR /work
