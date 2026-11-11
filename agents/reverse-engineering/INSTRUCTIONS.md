# Job: reverse engineering (reverse-engineering)

Static reverse engineering: firmware analysis, security research and CTF challenges. There is no emulator
and no attached device, so don't plan on running the target (no qemu, no live exploitation).
The same brief is read by Claude Code (as `CLAUDE.md`) and by goose (as `.goosehints`).

- REA is installed at `/opt/rea` (`rea` on `PATH`). Its disassembler backend is Ghidra 12.1.4 at
  `/opt/ghidra` (`GHIDRA_INSTALL_DIR`) with JDK 21 (`JAVA_HOME`). Run `rea doctor` if a provider fails.
  Use it through its MCP tools when they are loaded, otherwise as a CLI (`rea --help`).
  Its workflow guide is `/opt/rea/.agents/skills/reverse-engineer-anything/SKILL.md`.
- Firmware: `binwalk` 3.1 and `unblob` 26.6 (REA uses them via `REA_BINWALK_COMMAND`/`REA_UNBLOB_COMMAND`),
  plus `unsquashfs`, `debugfs`, `7z`, `unar`, `cpio`, `dtc` (devicetrees) and `dumpimage` (U-Boot images).
- CLI fallback: multi-arch binutils (`objdump`, `readelf`, `nm`, `strings`), `file`, `xxd`, `hexdump`, `jq`.
  Python 3 with `capstone`, `pyelftools`, `lief`, `pycryptodome`, `z3-solver` is the default `python3`.
- `/work/evidence` is **read-only** evidence (firmware images, binaries, challenge files). Never try to modify, move or delete it.
- Work in `/work/cases/<case-name>/`: notes, scripts, extracted artifacts and reports go there.
  Extract firmware into the case folder, never next to the evidence.

Keep the context small:
- Never dump a whole binary, disassembly or extraction listing into the conversation.
  Redirect big output to a file in the case folder and look at slices (`head`, `grep`, `wc`).
- Prefer targeted queries (one function, one section, `strings | grep`) over full listings.
- Write findings to a report in the case folder as you go.
