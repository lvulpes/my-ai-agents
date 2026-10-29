# my-ai-agents

AI agents in Docker. There's one image per **tool** and one folder per **job**.

```
images/   claude-code/, aider/      one generic image per tool
agents/   <job>/                    compose.yaml, tool config, .env, the job's own data
skills/                             shared skills, mounted read-only into every job
run.sh                              launcher
```

| Job | Tool | Default model | Data (rw) | Read-only |
|---|---|---|---|---|
| `recipe` | aider, architect | `gemini/gemini-3.8-flash`, edits by `groq/openai/gpt-oss-120b` | `workspace/` | instructions via `read:` |
| `code-architect` | aider, architect | `gemini/gemini-3.1-pro-preview`, edits by `groq/openai/gpt-oss-120b` | `$WORKSPACE_DIR` | |
| `network-forensics` | aider + tshark | `groq/openai/gpt-oss-120b` | `cases/` | `evidence/` (pcaps) |
| `rea-mobile` | claude-code + adb/REA | `opus` | `cases/` | `evidence/` (phone images), USB device |

**Models.** Each job's `.env` sets `MODEL=`. `--model` overrides it for one run.
- aider: Groq (`GROQ_API_KEY`) does the edits. In architect mode, Gemini (`GEMINI_*` key) does the reasoning.
- claude-code: uses `ANTHROPIC_API_KEY`, or your subscription login when the key is unset.

## Usage

```bash
cp agents/<job>/.env.example agents/<job>/.env   # then fill in the keys
./run.sh <job> [--model <name>] [-- <extra args>]

./run.sh recipe
./run.sh network-forensics --model gemini/gemini-3.8-flash
./run.sh rea-mobile -- --resume
./run.sh --help
```

The first run builds the images. Rebuild after changes with `docker compose -f agents/<job>/compose.yaml build`.

## Rules

- Secrets live only in `agents/<job>/.env` (gitignored). Tool logins and state live in `agents/<job>/state/` (gitignored), never in the data folder.
- Containers run as uid 1000 with `cap_drop: ALL` and `no-new-privileges`. They never get the Docker socket, `$HOME` or `/`.
- Evidence is always mounted `:ro`.
