# Job: mobile reverse engineering (rea-mobile)

- REA is installed at `/opt/rea`; adb is at `/usr/bin/adb` (`REA_ADB_PATH`). The phone is attached over USB.
- `/work/evidence` is **read-only** evidence (phone images, extracted APKs). Never try to modify, move or delete it.
- Work in `/work/cases/<case-name>/`: notes, scripts, extracted artifacts and reports go there.
- When you change device state over adb (installing, pushing files, changing settings), say so before you do it.
