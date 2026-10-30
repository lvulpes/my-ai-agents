# Job: light software development and ai-agents repo organization

You write python and bash scripts mostly. Your main purpose is to help me organize this very repository of ai agents.
The goal is a flexible setup: a new use case should not need a new agent, and no job should be tied to one model or one tool.
We use Groq, Gemini and Anthropic models through either Claude Code or aider.

## How to work with me

- I'm a beginner with this. Explain trade-offs in plain words, give one recommendation, and point out constraints I may not know about.
- For design questions, report back with a proposal **before** changing files. Small, clearly asked-for edits can go ahead directly.
- **Never run git** (no commit, add, stash, checkout, diff ...). I handle commits and pushes myself.
- Keep the docs in sync: `README.md`, `skills/README.md`, `images/*/README.md` and the `.env.example` files.

## Repo layout (see README.md for details)

- `images/<tool>/`: one generic image per tool (`aider`, `claude-code`), nothing job-specific.
- `agents/<job>/`: one folder per job: compose files, tool config, `.env.example`, the job's data.
- `skills/`: shared skills, mounted read-only into every job.
- `run.sh`: launcher. `./run.sh <job> [--tool <tool>] [--model <name>] [-- <tool args>]`.

## Conventions

- **Multi-tool jobs** (`code-architect`, `recipe`): `compose.yaml` holds only what both tools share (data mounts, security).
  `compose.<tool>.yaml` adds image, entrypoint, state mounts, the model variable and skills. `run.sh` finds the tools by those files.
  `.env` sets `TOOL=` and one model per tool: `MODEL_AIDER=`, `MODEL_CLAUDE_CODE=` (`MODEL=` is a fallback for the default tool).
- **Single-tool jobs** (`network-forensics`, `reverse-engineering`, `claude-developer`): `compose.yaml` is complete and `.env` uses `MODEL=`.
- Jobs with extra tooling use a Dockerfile with `FROM base`, where compose maps `base` to the tool image (`additional_contexts`).
  The images differ: aider has Python and user `agent` (home `/home/agent`); claude-code has Node and user `node` (home `/home/node`).
- Model names differ per tool: aider takes `provider/model` (`gemini/...`, `groq/...`), Claude Code takes Claude models or aliases (`opus`, `sonnet`).
  Claude Code can't use non-Anthropic models, and aider can't use a Claude subscription (it needs `ANTHROPIC_API_KEY`).
- State: aider uses `state/aider/` in multi-tool jobs (`state/` in single-tool ones), Claude Code uses `state/.claude/` + `state/claude.json`.
  `run.sh` pre-creates bind-mount sources so Docker doesn't create them as root.

## Security rules (keep them in every change)

- Secrets only in `agents/<job>/.env`, tool logins only in `agents/<job>/state/`, both gitignored and never in a data folder.
- Containers run as uid 1000 with `cap_drop: ALL` and `no-new-privileges`. Never mount the Docker socket, `$HOME` or `/`.
- Evidence is always mounted `:ro`, and those jobs use `label:disable` instead of `:z` so its metadata is never changed.
- Don't mount anything into an external `WORKSPACE_DIR` repo (shared skills go through `--add-dir /opt/shared` for Claude Code).

## Your environment

- This repo is mounted at `/work`. The paths in `agents/claude-developer/masks` are hidden: every `.env`, `state/`, `cases/`, `evidence/`.
  You see them as empty files or folders. Ask me for their contents if needed, and tell me when I need to edit them myself.
- Available: `python3` (with `yaml`), `bash`, `shellcheck`. There is **no Docker**: test `run.sh` in a scratch copy with a stub `docker`
  script on `PATH`, lint with `shellcheck`, and tell me which parts still need a real run on my machine.
