# my-ai-agents

AI agents in Docker. There's one image per **tool** and one folder per **job**. Some jobs can run with either tool.

```
images/   claude-code/, aider/, goose/   one generic image per tool
agents/   <job>/                    compose.yaml (+ compose.<tool>.yaml), tool config, .env, the job's own data
skills/                             shared skills, mounted read-only into every job
run.sh                              launcher
```

| Job | Tools | Default model | Data (rw) | Read-only |
|---|---|---|---|---|
| `recipe` | **aider** (architect) or claude-code | aider: `gemini/gemini-3.8-flash`, edits by `groq/openai/gpt-oss-120b`; claude-code: `sonnet` | `workspace/` | instructions (`GEMINI.md`, `.gemini/system.md`) |
| `code-architect` | **aider** (architect) or claude-code, + python/uv, shellcheck/yamllint, helm, jq/curl | aider: `openrouter/google/gemini-3.1-pro-preview`, edits by `openrouter/deepseek/deepseek-v3.2`; claude-code: `opus` | `$WORKSPACE_DIR` | `CLAUDE.md` (git rules: you commit and push) |
| `network-forensics` | **goose** or aider, + tshark | goose: `openai/gpt-oss-120b`; aider: `groq/openai/gpt-oss-120b` | `cases/` | `evidence/` (pcaps), `.goosehints` (goose brief) |
| `literature-review` | **goose** or claude-code, + poppler-utils (pdfinfo/pdftotext), qpdf, exiftool | goose: `openai/gpt-oss-120b` via OpenRouter; claude-code: `sonnet` | `workspace/` (summaries) | `papers/` (PDFs), `INSTRUCTIONS.md` (brief for both tools) |
| `reverse-engineering` | **goose** or claude-code, + REA/Ghidra, binwalk/unblob, binutils | goose: `openai/gpt-oss-120b` via OpenRouter; claude-code: `opus` | `cases/` | `evidence/` (firmware, binaries, CTF files), `INSTRUCTIONS.md` (brief for both tools) |
| `claude-developer` | claude-code + python/shellcheck | `opus` | `$WORKSPACE_DIR`, normally this repo (minus `masks`) | `CLAUDE.md` |

**Tools.** A job with several tools has a shared `compose.yaml` plus one `compose.<tool>.yaml` per tool
(image, entrypoint, state, model variable). `.env` sets the default with `TOOL=`; `--tool` overrides it for one run.
Single-tool jobs have only `compose.yaml`.
- aider: a pair programmer. Works with any provider (Groq, Gemini, Anthropic API key, ...), but not your Claude subscription.
- claude-code: an autonomous agent (runs commands, MCP, skills). Claude models only.
- goose: an autonomous agent (plans and runs multi-step work, MCP extensions, approval modes for human-in-the-loop verification). Any provider/model, so it can drive open-weight models (Groq, Ollama, OpenRouter, ...).

**Models.** Model names differ per tool, so a multi-tool job's `.env` sets one per tool: `MODEL_AIDER=`, `MODEL_CLAUDE_CODE=`, `MODEL_GOOSE=`.
Single-tool jobs use `MODEL=`. `--model` overrides it for one run.
- aider: in architect mode one model plans (`MODEL_AIDER=`) and a cheaper one writes the edits (`EDITOR_MODEL_AIDER=` in `code-architect`).
  Names are `provider/model`, and each provider needs its key in `.env`: `gemini/...` (`GEMINI_*`), `groq/...` (`GROQ_API_KEY`),
  or `openrouter/<vendor>/<model>` (`OPENROUTER_API_KEY`), where one key reaches every OpenRouter model, so planner and editor can be different vendors.
- claude-code: uses `ANTHROPIC_API_KEY`, or your subscription login when the key is unset. Each job has its own login.
- goose: provider and model are separate — set `GOOSE_PROVIDER=` (e.g. `groq`) in `.env`, the model with `MODEL_GOOSE=`/`MODEL=`/`--model`, and the provider key (`GROQ_API_KEY`, ...) in `.env`.
  With `GOOSE_PROVIDER=openrouter` (`OPENROUTER_API_KEY`), one key reaches many vendors and `--model` takes any OpenRouter slug
  (`vendor/model`, see openrouter.ai/models). The model must support tool calling, or goose can't run commands.

## Usage

```bash
cp agents/<job>/.env.example agents/<job>/.env   # then fill in the keys
./run.sh <job> [--tool <tool>] [--model <name>] [-- <extra args>]

./run.sh recipe
./run.sh code-architect --tool claude-code
./run.sh code-architect --tool claude-code --model sonnet
./run.sh code-architect --model openrouter/moonshotai/kimi-k2.7-code
./run.sh network-forensics                       # goose (default)
./run.sh network-forensics --tool aider
./run.sh network-forensics -- run -t "Top talkers in evidence/*.pcap"
./run.sh literature-review                       # goose via OpenRouter (default)
./run.sh literature-review --model google/gemini-2.5-pro
./run.sh literature-review --tool claude-code
./run.sh reverse-engineering                     # goose via OpenRouter, REA loaded as MCP extension
./run.sh reverse-engineering --tool claude-code -- --resume
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
