# Job: reverse engineering (reverse-engineering)

Static reverse engineering: firmware analysis, security research and CTF challenges. There is no emulator
and no attached device, so don't plan on running the target (no qemu, no live exploitation).

- REA is installed at `/opt/rea` (`rea` on `PATH`). Its disassembler backend is Ghidra 12.1.4 at
  `/opt/ghidra` (`GHIDRA_INSTALL_DIR`) with JDK 21 (`JAVA_HOME`). Run `rea doctor` if a provider fails.
- Firmware: `binwalk` 3.1 and `unblob` 26.6 (REA uses them via `REA_BINWALK_COMMAND`/`REA_UNBLOB_COMMAND`),
  plus `unsquashfs`, `debugfs`, `7z`, `unar`, `cpio`, `dtc` (devicetrees) and `dumpimage` (U-Boot images).
- CLI fallback: multi-arch binutils (`objdump`, `readelf`, `nm`, `strings`), `file`, `xxd`, `hexdump`, `jq`.
  Python 3 with `capstone`, `pyelftools`, `lief`, `pycryptodome`, `z3-solver` is the default `python3`.
- `/work/evidence` is **read-only** evidence (firmware images, binaries, challenge files). Never try to modify, move or delete it.
- Work in `/work/cases/<case-name>/`: notes, scripts, extracted artifacts and reports go there.
  Extract firmware into the case folder, never next to the evidence.
