# skills

Skills shared by several jobs. Every job mounts this folder **read-only**:

| Tool | Mounted at | Picked up how |
|---|---|---|
| claude-code | `/work/.claude/skills`, or `/opt/shared/.claude/skills` in multi-tool jobs | Automatically: Claude Code loads project skills from `.claude/skills/<name>/SKILL.md`, and multi-tool jobs start it with `--add-dir /opt/shared` so nothing is mounted into the workspace |
| aider | `/skills` | Manually: `/read /skills/<name>/SKILL.md` in the chat, or add the file to `read:` in the job's `.aider.conf.yml` |

Layout: one folder per skill, each with a `SKILL.md`:

```
skills/
  <skill-name>/
    SKILL.md
    (supporting files)
```

There are no shared skills yet. REA's own skills live in `agents/reverse-engineering/rea/.agents/skills/`,
and the account-synced Claude skills live in each job's `state/.claude/skills/`. Neither is managed here.
