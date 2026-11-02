# PDF tooling for literature-review, on top of either tool base (goose or claude-code).
# The bases differ (goose: plain Debian, user `agent`; claude-code: Node, user `node`),
# but both are Debian with uid 1000, so this file only uses apt and `USER 1000`.
# Digital journal PDFs only: no OCR, no LaTeX (pdfjam stays on the host).
FROM base

USER root
ENV DEBIAN_FRONTEND=noninteractive
# poppler-utils: pdfinfo, pdftotext, pdftoppm (render pages), pdfimages, pdfseparate/pdfunite
# qpdf: repairs/decrypts broken PDFs; exiftool: reads and sets PDF metadata
RUN apt-get update && apt-get install -y --no-install-recommends \
      poppler-utils \
      qpdf \
      libimage-exiftool-perl \
 && rm -rf /var/lib/apt/lists/*

USER 1000
WORKDIR /work
