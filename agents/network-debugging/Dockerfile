# Live network debugging tools on Kali, for either tool (goose or claude-code).
# Exception to the repo pattern: the job image is Kali, not the tool image.
# `FROM base` is only used to copy the agent program out of the tool image:
# both bases keep it entirely in /usr/local (goose: one binary; claude-code:
# Node + its global npm packages). Everything else the tool image set up
# (user, home, entrypoint, env) is redone here or in compose.<tool>.yaml.
# Unlike the forensics jobs this one talks to the network on purpose.
FROM base AS tool

FROM kalilinux/kali-rolling

USER root
ENV DEBIAN_FRONTEND=noninteractive
# git/ca-certificates/curl/procps/ripgrep: what the tool images provided;
# ping/tracepath/arping: iputils; dig: bind9-dnsutils; nc: netcat-openbsd;
# iproute2 (`ip`) shows the container's own interfaces and routes;
# libcap2-bin provides setcap for the step below
RUN apt-get update && apt-get install -y --no-install-recommends \
      git \
      ca-certificates \
      curl \
      procps \
      ripgrep \
      nmap \
      iputils-ping \
      iputils-arping \
      iputils-tracepath \
      traceroute \
      telnet \
      netcat-openbsd \
      bind9-dnsutils \
      iproute2 \
      libcap2-bin \
      seclists wordlists \
      metasploit-framework \
 && rm -rf /var/lib/apt/lists/*

# The agent program (goose, or node + claude) from the tool image
COPY --from=tool /usr/local/ /usr/local/

# uid 1000 like every job. Both homes exist and belong to it, so the state
# mounts of either tool (goose: /home/agent, claude-code: /home/node) work.
RUN useradd --create-home --uid 1000 --shell /bin/bash agent \
 && mkdir -p /home/node /work \
 && chown 1000:1000 /home/node /work

# Raw sockets for exactly two tools (compose adds NET_RAW and allows file
# capabilities for this job only). Everything else runs without privileges.
# No setuid/setgid binaries are left, so nothing in the image can become root.
RUN setcap cap_net_raw+ep "$(command -v nmap)" \
 && setcap cap_net_raw+ep "$(command -v arping)" \
 && find / -xdev -type f -perm /6000 -exec chmod a-s {} +

# nmap only uses its raw-socket scans (-sS, -O, ARP discovery) when not root
# if this variable is set; without it, it falls back to connect scans.
ENV NMAP_PRIVILEGED=1

USER 1000
WORKDIR /work
