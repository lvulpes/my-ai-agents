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
# Same for a CLAUDE.md mounted inside state/.claude
if grep -qF ':/home/node/.claude/CLAUDE.md' "$job_dir/compose.yaml"; then
  [[ -e "$job_dir/state/.claude/CLAUDE.md" ]] || : > "$job_dir/state/.claude/CLAUDE.md"
fi

compose_files=(-f "$job_dir/compose.yaml")
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

echo "job: $job  model: $MODEL" >&2
exec docker compose "${compose_files[@]}" run --rm "$job" ${extra[@]+"${extra[@]}"}
