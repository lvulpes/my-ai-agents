#!/usr/bin/env bash
# Launch a job: ./run.sh <job> [--tool <tool>] [--model <name>] [-- <extra args>]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS="$ROOT/agents"

# Tools a job supports: one agents/<job>/compose.<tool>.yaml each.
# Prints nothing for a single-tool job, whose compose.yaml is complete.
job_tools() {
  local f
  for f in "$1"/compose.*.yaml; do
    [[ -f "$f" ]] || continue
    f="${f##*/compose.}"
    printf '%s\n' "${f%.yaml}"
  done
}

list_jobs() {
  local d tools
  for d in "$AGENTS"/*/; do
    [[ -f "$d/compose.yaml" ]] || continue
    tools="$(job_tools "$d" | paste -sd, -)"
    printf '  %s%s\n' "$(basename "$d")" "${tools:+  (tools: $tools)}"
  done
}

usage() {
  cat <<EOF
Usage: ./run.sh <job> [--tool <tool>] [--model <name>] [-- <extra args>]

Starts agents/<job>/compose.yaml with 'docker compose run --rm <job>'.
Jobs that support several tools also get agents/<job>/compose.<tool>.yaml.

Options:
  --tool <tool>    Tool for this run only (default: TOOL= in agents/<job>/.env).
                   Only for jobs that list several tools below.
  --model <name>   Model for this run only (default: MODEL_<TOOL>= in
                   agents/<job>/.env, e.g. MODEL_CLAUDE_CODE=, then MODEL=).
                   Passed straight to the tool, not validated.
  -- <args>        Everything after -- goes to the tool (aider / claude).
  -h, --help       Show this help.

Jobs:
$(list_jobs)
EOF
}

# Read one KEY=value from a dotenv file without executing it
dotenv_get() {
  local file="$1" key="$2" line value=""
  [[ -f "$file" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "$key="* ]]; then
      value="${line#"$key="}"
      value="${value%\"}"; value="${value#\"}"
      value="${value%\'}"; value="${value#\'}"
    fi
  done < "$file"
  printf '%s' "$value"
}

# Print a compose override for service $1 that hides every path matching the
# globs in file $2, relative to host folder $3 (which the job mounts at /work).
# Prints nothing when no path matches.
masks_override() {
  local service="$1" file="$2" base="$3" pattern path entries=""
  while IFS= read -r pattern || [[ -n "$pattern" ]]; do
    [[ -z "$pattern" || "$pattern" == \#* ]] && continue
    while IFS= read -r -d '' path; do
      path="${path#"$base"/}"
      if [[ -L "$base/$path" ]]; then
        echo "error: mask '$path' is a symlink, refusing to mount over it" >&2
        return 1
      elif [[ -d "$base/$path" ]]; then
        entries+="      - type: tmpfs"$'\n'
      else
        entries+="      - type: bind"$'\n'"        source: /dev/null"$'\n'"        read_only: true"$'\n'
      fi
      entries+="        target: '/work/${path//\'/\'\'}'"$'\n'
    done < <(shopt -s nullglob; for path in "$base"/$pattern; do printf '%s\0' "$path"; done)
  done < "$file"
  [[ -n "$entries" ]] || return 0
  printf 'services:\n  %s:\n    volumes:\n%s' "$service" "$entries"
}

if [[ $# -eq 0 ]]; then
  usage >&2
  exit 1
fi

case "$1" in
  -h|--help) usage; exit 0 ;;
esac

job="$1"; shift
tool_override=""
model_override=""
extra=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)
      [[ $# -ge 2 && -n "$2" ]] || { echo "error: --model needs a value" >&2; exit 1; }
      model_override="$2"; shift 2 ;;
    --model=*)
      model_override="${1#--model=}"; shift ;;
    --tool)
      [[ $# -ge 2 && -n "$2" ]] || { echo "error: --tool needs a value" >&2; exit 1; }
      tool_override="$2"; shift 2 ;;
    --tool=*)
      tool_override="${1#--tool=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; extra=("$@"); break ;;
    *) echo "error: unknown argument '$1' (tool args go after --)" >&2; exit 1 ;;
  esac
done

# Job names are plain folder names: no paths, no traversal
if [[ ! "$job" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ || ! -f "$AGENTS/$job/compose.yaml" ]]; then
  echo "error: no such job '$job'. Available jobs:" >&2
  list_jobs >&2
  exit 1
fi

job_dir="$AGENTS/$job"
compose_files=(-f "$job_dir/compose.yaml")
job_files=("$job_dir/compose.yaml")

mapfile -t tools < <(job_tools "$job_dir")
default_tool="$(dotenv_get "$job_dir/.env" TOOL)"
if [[ ${#tools[@]} -eq 0 ]]; then
  # Single-tool job: compose.yaml has everything, the model is MODEL=
  if [[ -n "$tool_override" ]]; then
    echo "error: job '$job' has a single tool, --tool is not supported" >&2
    exit 1
  fi
  tool="$(sed -n 's|^ *image: my-ai-agents/\([^:]*\):.*|\1|p' "$job_dir/compose.yaml" | head -n1)"
  model_key="MODEL"
  MODEL="${model_override:-$(dotenv_get "$job_dir/.env" MODEL)}"
else
  tool="${tool_override:-$default_tool}"
  if [[ -z "$tool" ]]; then
    echo "error: no tool. Set TOOL= in agents/$job/.env or pass --tool ($(IFS=,; echo "${tools[*]}"))" >&2
    exit 1
  fi
  if [[ ! -f "$job_dir/compose.$tool.yaml" || ! "$tool" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    echo "error: job '$job' has no tool '$tool'. Available: $(IFS=,; echo "${tools[*]}")" >&2
    exit 1
  fi
  compose_files+=(-f "$job_dir/compose.$tool.yaml")
  job_files+=("$job_dir/compose.$tool.yaml")
  # claude-code -> MODEL_CLAUDE_CODE
  model_key="MODEL_$(tr 'a-z-' 'A-Z_' <<<"$tool")"
  MODEL="${model_override:-$(dotenv_get "$job_dir/.env" "$model_key")}"
  # MODEL= still works for the default tool (older .env files)
  if [[ -z "$MODEL" && "$tool" == "$default_tool" ]]; then
    MODEL="$(dotenv_get "$job_dir/.env" MODEL)"
  fi
fi
if [[ -z "$MODEL" ]]; then
  echo "error: no model. Set $model_key= in agents/$job/.env or pass --model" >&2
  exit 1
fi
export MODEL

# Bind-mount sources must exist, or Docker creates them as root
mkdir -p "$job_dir/state"
# Multi-tool jobs keep aider's home in state/aider
if grep -qF './state/aider:' "${job_files[@]}"; then
  mkdir -p "$job_dir/state/aider"
fi
# Claude Code jobs mount state/.claude (dir) and state/claude.json (file);
# a missing file would otherwise become a root-owned directory
if grep -qF './state/claude.json' "${job_files[@]}"; then
  mkdir -p "$job_dir/state/.claude"
  if [[ ! -e "$job_dir/state/claude.json" ]]; then
    (umask 077; printf '{}\n' > "$job_dir/state/claude.json")
  fi
fi
# Same for a CLAUDE.md mounted inside state/.claude
if grep -qF ':/home/node/.claude/CLAUDE.md' "${job_files[@]}"; then
  [[ -e "$job_dir/state/.claude/CLAUDE.md" ]] || : > "$job_dir/state/.claude/CLAUDE.md"
fi

# agents/<job>/masks lists paths inside WORKSPACE_DIR to hide from the container
if [[ -f "$job_dir/masks" ]]; then
  # Same precedence as compose: shell environment first, then .env
  workspace="${WORKSPACE_DIR:-$(dotenv_get "$job_dir/.env" WORKSPACE_DIR)}"
  [[ -n "$workspace" ]] || { echo "error: set WORKSPACE_DIR in agents/$job/.env" >&2; exit 1; }
  # Relative paths resolve against the job folder, as in compose
  [[ "$workspace" == /* ]] || workspace="$job_dir/$workspace"
  [[ -d "$workspace" ]] || { echo "error: WORKSPACE_DIR '$workspace' is not a folder" >&2; exit 1; }
  workspace="$(cd "$workspace" && pwd -P)"
  override="$job_dir/state/masks.compose.yaml"
  masks_override "$job" "$job_dir/masks" "$workspace" > "$override"
  [[ -s "$override" ]] && compose_files+=(-f "$override")
fi

echo "job: $job  tool: ${tool:-?}  model: $MODEL" >&2
exec docker compose "${compose_files[@]}" run --rm "$job" ${extra[@]+"${extra[@]}"}
