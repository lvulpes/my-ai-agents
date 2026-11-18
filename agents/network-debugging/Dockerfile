# Live network debugging tools on top of either tool base (goose or claude-code).
# Both bases are Debian bookworm with uid 1000, so this file only uses apt and `USER 1000`.
# Unlike the forensics jobs this one talks to the network on purpose.
FROM base

USER root
ENV DEBIAN_FRONTEND=noninteractive
# ping/tracepath/arping: iputils; dig: bind9-dnsutils; nc: netcat-openbsd;
# iproute2 (`ip`) shows the container's own interfaces and routes;
# libcap2-bin provides setcap for the step below
RUN apt-get update && apt-get install -y --no-install-recommends \
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
 && rm -rf /var/lib/apt/lists/*

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
