# my-ai-agents

AI agents in Docker. There's one image per **tool** and one folder per **job**. Some jobs can run with either tool.

```
images/   claude-code/, aider/      one generic image per tool
agents/   <job>/                    compose.yaml (+ compose.<tool>.yaml), tool config, .env, the job's own data
skills/                             shared skills, mounted read-only into every job
run.sh                              launcher
```

| Job | Tools | Default model | Data (rw) | Read-only |
|---|---|---|---|---|
| `recipe` | **aider** (architect) or claude-code | aider: `gemini/gemini-3.8-flash`, edits by `groq/openai/gpt-oss-120b`; claude-code: `sonnet` | `workspace/` | instructions (`GEMINI.md`, `.gemini/system.md`) |
| `code-architect` | **aider** (architect) or claude-code | aider: `gemini/gemini-3.1-pro-preview`, edits by `groq/openai/gpt-oss-120b`; claude-code: `opus` | `$WORKSPACE_DIR` | |
| `network-forensics` | aider + tshark | `groq/openai/gpt-oss-120b` | `cases/` | `evidence/` (pcaps) |
| `reverse-engineering` | claude-code + REA/Ghidra, binwalk/unblob, binutils | `opus` | `cases/` | `evidence/` (firmware, binaries, CTF files) |
| `claude-developer` | claude-code + python/shellcheck | `opus` | `$WORKSPACE_DIR`, normally this repo (minus `masks`) | `CLAUDE.md` |

**Tools.** A job with several tools has a shared `compose.yaml` plus one `compose.<tool>.yaml` per tool
(image, entrypoint, state, model variable). `.env` sets the default with `TOOL=`; `--tool` overrides it for one run.
Single-tool jobs have only `compose.yaml`.
- aider: a pair programmer. Works with any provider (Groq, Gemini, Anthropic API key, ...), but not your Claude subscription.
- claude-code: an autonomous agent (runs commands, MCP, skills). Claude models only.

**Models.** Model names differ per tool, so a multi-tool job's `.env` sets one per tool: `MODEL_AIDER=`, `MODEL_CLAUDE_CODE=`.
Single-tool jobs use `MODEL=`. `--model` overrides it for one run.
- aider: Groq (`GROQ_API_KEY`) does the edits. In architect mode, Gemini (`GEMINI_*` key) does the reasoning.
- claude-code: uses `ANTHROPIC_API_KEY`, or your subscription login when the key is unset. Each job has its own login.

## Usage

```bash
cp agents/<job>/.env.example agents/<job>/.env   # then fill in the keys
./run.sh <job> [--tool <tool>] [--model <name>] [-- <extra args>]

./run.sh recipe
./run.sh code-architect --tool claude-code
./run.sh code-architect --tool claude-code --model sonnet
./run.sh network-forensics --model gemini/gemini-3.8-flash
./run.sh reverse-engineering -- --resume
./run.sh --help
```

The first run builds the images. Rebuild after changes with `docker compose -f agents/<job>/compose.yaml build`
(multi-tool jobs: add `-f agents/<job>/compose.<tool>.yaml`).

## Rules

- Secrets live only in `agents/<job>/.env` (gitignored). Tool logins and state live in `agents/<job>/state/` (gitignored), never in the data folder.
  In multi-tool jobs aider uses `state/aider/` and Claude Code `state/.claude/` + `state/claude.json`.
- Containers run as uid 1000 with `cap_drop: ALL` and `no-new-privileges`. They never get the Docker socket, `$HOME` or `/`.
- Evidence is always mounted `:ro`.
- `claude-developer` manages this repo, so its `WORKSPACE_DIR` normally points here. `run.sh` hides the paths in `agents/claude-developer/masks` (every `.env`, `state/`, `cases/`, `evidence/`, ...) by mounting empty files and folders over them. A new job's secrets are covered automatically as long as they follow these folder names.
