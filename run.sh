#!/usr/bin/env bash
# Launch a job: ./run.sh <job> [--model <name>] [-- <extra args>]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS="$ROOT/agents"

list_jobs() {
  local d
  for d in "$AGENTS"/*/; do
    [[ -f "$d/compose.yaml" ]] && printf '  %s\n' "$(basename "$d")"
  done
}

usage() {
  cat <<EOF
Usage: ./run.sh <job> [--model <name>] [-- <extra args>]

Starts agents/<job>/compose.yaml with 'docker compose run --rm <job>'.

Options:
  --model <name>   Model for this run only (default: MODEL= in agents/<job>/.env).
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

if [[ $# -eq 0 ]]; then
  usage >&2
  exit 1
fi

case "$1" in
  -h|--help) usage; exit 0 ;;
esac

job="$1"; shift
model_override=""
extra=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)
      [[ $# -ge 2 && -n "$2" ]] || { echo "error: --model needs a value" >&2; exit 1; }
      model_override="$2"; shift 2 ;;
    --model=*)
      model_override="${1#--model=}"; shift ;;
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
MODEL="${model_override:-$(dotenv_get "$job_dir/.env" MODEL)}"
if [[ -z "$MODEL" ]]; then
  echo "error: no model. Set MODEL= in agents/$job/.env or pass --model" >&2
  exit 1
fi
export MODEL

# Bind-mount sources must exist, or Docker creates them as root
mkdir -p "$job_dir/state"
# Claude Code jobs mount state/.claude (dir) and state/claude.json (file);
# a missing file would otherwise become a root-owned directory
if grep -qF './state/claude.json' "$job_dir/compose.yaml"; then
  mkdir -p "$job_dir/state/.claude"
  if [[ ! -e "$job_dir/state/claude.json" ]]; then
    (umask 077; printf '{}\n' > "$job_dir/state/claude.json")
  fi
fi

echo "job: $job  model: $MODEL" >&2
exec docker compose -f "$job_dir/compose.yaml" run --rm "$job" ${extra[@]+"${extra[@]}"}
