# Code architect

You work on the repo mounted at `/work`. Claude Code and aider both read this file.

## Git: the user commits and pushes

- Never run `git commit`, `git push`, `git stash`, `git reset`, `git checkout` or anything else that changes
  history, branches or the remote. The user commits and pushes every change themselves to keep track of it.
- Read-only git is fine: `git status`, `git diff`, `git log`, `git show`, `git blame`.
- When a change is ready, say so and suggest a commit message. Don't offer to commit, push or open a PR.

## Tools in this container

- `python3` and `uv`: use `uv run` / `uv venv` so the project gets its own env (in the aider container, plain
  `python` is aider's own venv).
- `shellcheck`, `yamllint`, `bash -n`: lint scripts and YAML.
- `helm`: `helm lint` / `helm template` to check charts. There is no cluster here.
- `jq`, `curl`.
- No `gh`, `kubectl`, `k3d` or `docker`. Deploys run elsewhere.

Say which checks you ran, and which still need a run on the user's machine.
