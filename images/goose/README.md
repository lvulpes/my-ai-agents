# goose image

Generic Goose container. Goose is an autonomous CLI agent: it plans and runs
multi-step work, supports MCP "extensions", and has approval modes so a human
verifies actions instead of directing every step.

- Base: `debian:bookworm-slim`, plus `git`, `ca-certificates`, `curl`.
- Goose is pinned with the build arg `GOOSE_VERSION` (a tag from the releases page).
  The CLI tarball is downloaded directly from `GOOSE_REPO` (default `aaif-goose/goose`,
  which is where the former `block/goose` release assets are now served) and the
  `goose` binary is installed to `/usr/local/bin`.
- Runs as `agent` (uid 1000), workdir `/work`, entrypoint `goose`.
- `GOOSE_DISABLE_KEYRING=1`: no system keyring in the container, so provider keys
  come from the environment and any other secrets go in Goose's config under `$HOME`.

Auth and model: Goose picks a **provider** and a **model** separately. The job's
compose sets `GOOSE_PROVIDER` (e.g. `groq`) and `GOOSE_MODEL=${MODEL}`, and passes
the provider key (`GROQ_API_KEY`, ...) from the job's `.env`. This lets a job run
open-weight models (Groq, Ollama, OpenRouter) without being tied to one provider.

Jobs that need extra tooling have their own Dockerfile that starts with `FROM base`.
Compose maps `base` to this image via `additional_contexts: base: service:goose-base`.

Build it alone:

```bash
docker build -t my-ai-agents/goose:local images/goose
```
