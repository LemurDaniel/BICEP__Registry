Goal (checkable): `pwsh .scripts/Test-Modules.ps1` exits 0.

1. Read `.claude/state/check-modules.md` if it exists (previous failures and what was tried).
2. Run `pwsh .scripts/Test-Modules.ps1`. The script is the judge; do not decide yourself that a module passes.
3. For each failure, fix the module's Bicep or parameter file. Never edit `version.json` and never touch Azure.
4. Re-run the script. Stop after 3 fix attempts in total and report what is still failing.
5. Overwrite `.claude/state/check-modules.md` with: failures found, fixes made, failures left.

Use with e.g. `/loop 30m /check-modules`.
