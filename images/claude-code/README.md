# claude-code image

Generic Claude Code container. It replaces the old standalone `claude-box`.

- Base: `node:24-bookworm-slim`, plus `git`, `ca-certificates`, `procps`, `ripgrep`.
- Claude Code is pinned with the build arg `CLAUDE_CODE_VERSION`.
- Runs as `node` (uid 1000), workdir `/work`, entrypoint `claude`.

Auth: set `ANTHROPIC_API_KEY` in the job's `.env`, or leave it unset and log in with
your subscription. The login is stored in the job's `state/.claude/`.
Model: the job's compose passes `ANTHROPIC_MODEL=${MODEL}`.

Jobs that need extra tooling (e.g. `agents/rea-mobile`) have their own Dockerfile that starts
with `FROM base`. Compose maps `base` to this image via `additional_contexts: base: service:claude-code-base`.

Build it alone:

```bash
docker build -t my-ai-agents/claude-code:local images/claude-code
```
