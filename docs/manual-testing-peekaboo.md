---
summary: "Manual Peekaboo end-to-end check for Trimmy (menu bar, settings, clipboard)."
read_when:
  - Running a full Trimmy validation using Peekaboo
  - Verifying menu bar + settings + clipboard trimming end-to-end
---

# Trimmy E2E Manual Test (Peekaboo)

Goal: use Peekaboo to open Trimmy from the menu bar, open Settings, capture screenshots, and verify clipboard trimming end-to-end.

## Prereqs
- Trimmy running (`open -a Trimmy`).
- Peekaboo CLI built (`Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo` or `/tmp/peekaboo-cli-build/debug/peekaboo`).
- Permissions granted: `peekaboo permissions status`.

## Notes
- Trimmy reads the clipboard via `NSPasteboard.string` (type `.string` / `public.utf8-plain-text`).
  Peekaboo `clipboard --action set --text` writes both `public.plain-text` + `public.utf8-plain-text`.
- The settings checkbox element IDs are dynamic per snapshot; capture a fresh snapshot and use those IDs.
- Use `peekaboo see --menubar` after a menu bar click to OCR the popover when needed.
- Remember: `peekaboo menu click --app Trimmy --item "Settings…"` is the reliable settings opener.
- Memory hook (clipboard sanity): `peekaboo clipboard --action set --text $'ls \\\n | wc -l\n' --verify`

## Runbook

1) Pull latest
```bash
cd ~/Projects/Trimmy
git pull

cd ~/Projects/Peekaboo
git pull
```

2) Build Peekaboo CLI
```bash
cd ~/Projects/Peekaboo
swift build --package-path Apps/CLI
```

3) Launch Trimmy
```bash
open -a Trimmy
```

4) Menu bar click (verified)
```bash
cd ~/Projects/Peekaboo

Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo menubar list
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo menubar click --verify "Trimmy"
```

If verification fails, retry by index:
```bash
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo menubar click --verify --index <trimmy-index>
```

Optional: capture the popover via OCR for debugging:
```bash
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo see --menubar --json --path /private/tmp/trimmy-menubar.png \
  > /private/tmp/trimmy-menubar.json
```

5) Open Trimmy Settings (menu bar popover)
```bash
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo menu click --app Trimmy --item "Settings…"
```

6) Capture Settings screenshot
```bash
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo list windows --app Trimmy
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo image --window-id <settings-window-id> --path /private/tmp/trimmy-settings.png
```

7) Grab checkbox IDs (snapshot + jq)
```bash
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo see --app Trimmy --window-title "General" --annotate \
  --json --path /private/tmp/trimmy-settings-annotated.png \
  > /private/tmp/trimmy-settings.json
jq -r '.data.ui_elements[] | select(.role=="checkbox") | "\(.id)\t\(.description)"' /private/tmp/trimmy-settings.json
jq -r '.data.snapshot_id' /private/tmp/trimmy-settings.json
```

8) Clipboard E2E (Peekaboo)
```bash
# Save clipboard
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action save --slot trimmy-e2e --log-level debug

# Toggle Auto-trim (use checkbox ID for "Auto-trim enabled")
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo click --on <auto-trim-id> --snapshot <snapshot-id>

# Auto-trim OFF → unchanged
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action set --verify \
  --text $'ls \\\n | wc -l\n'

sleep 0.5
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action get

# Auto-trim ON → trimmed
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo click --on <auto-trim-id> --snapshot <snapshot-id>
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action set --verify \
  --text $'ls \\\n | wc -l\n'

sleep 0.5
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action get

# Keep blank lines ON (checkbox "Keep blank lines")
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo click --on <keep-blank-lines-id> --snapshot <snapshot-id>
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action set --verify \
  --text $'$ echo one\n\n$ echo two\n'

sleep 0.5
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action get

# Box drawing removal ("Remove box drawing chars (│┃)")
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action set --verify \
  --text $'│ ls -la \\\n│ | grep foo\n'

sleep 0.5
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action get

# Restore clipboard
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action restore --slot trimmy-e2e --log-level debug
```

9) Restore settings state (optional)
```bash
# Toggle "Keep blank lines" back off
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo click --on <keep-blank-lines-id> --snapshot <snapshot-id>
```

10) Record the run (inline notes)
```bash
code /Users/steipete/Projects/Trimmy/docs/manual-testing-peekaboo.md
```
Update the “Latest run” block with date, machine, and outcome.

## Latest run
- Date: 2025-12-28 16:34 local
- Machine: macOS 26.x (arm64)
- Menu bar click: `menubar click --verify "Trimmy"` succeeded (index 7).
- Menu bar capture: `see --menubar --app Trimmy --path /tmp/trimmy-menubar.png` selected area capture, but OCR text came from Terminal (popover still not detected via CGWindowList/AX).
- Settings open: `peekaboo menu click --app Trimmy --item "Settings…"` succeeded; window title `General`.
- Screenshots: `/tmp/trimmy-settings.png`, `/tmp/trimmy-settings_annotated.png`, `/tmp/trimmy-aggressive.png`, `/tmp/trimmy-aggressive_annotated.png`.
- Aggressiveness toggles: clicked `elem_4` (Low) and `elem_6` (High) via snapshot `EA7849DB-36B8-45FF-B368-4552D9D2DC3A`.
- Auto-trim toggle: clicked `elem_3` (off → on) via snapshot `4D9DC2D4-F27A-4C1A-98E7-F5B32EAC4EDC`.
- Clipboard verify: `clipboard set --text ... --verify` read back both `public.plain-text` + `public.utf8-plain-text`.
- Clipboard E2E: Auto-trim still did not change output after 0.4s and 1.5s waits (multiline unchanged).

## Previous run
- Date: 2025-12-28 16:01 local
- Machine: macOS 26.x (arm64)
- Menu bar click: `menubar click --verify "Trimmy"` succeeded; `see --menubar --app Trimmy` returned empty OCR (no popover detected).
- Settings open: `peekaboo menu click --app Trimmy --item "Settings…"` succeeded.
- Screenshots: `/tmp/trimmy-menubar.png` (menubar OCR, empty), `/tmp/trimmy-aggressiveness.png`, `/tmp/trimmy-general.png`.
- See (Aggressiveness): `peekaboo see --app Trimmy --window-title "Aggressiveness"` succeeded; snapshot `6A621DCC-95EF-4E6C-BB0D-09D16F490FDB`.
- Aggressiveness toggles: clicked `Low` → `Normal` → `High` via `elem_4` / `elem_5` / `elem_6` (snapshot `6A621DCC-95EF-4E6C-BB0D-09D16F490FDB`).
- Switched to General tab: clicked `elem_17`, window title updated to `General`.
- See (General): `peekaboo see --app Trimmy --window-title "General"` succeeded; snapshot `2E5A7CDD-B883-4EF9-8BA0-3BDB501C019E`.
- Clipboard E2E: clipboard set/get OK; Auto-trim still did not change output after 1s (multiline).

## Earlier run
- Date: 2025-12-28 15:34 local
- Machine: macOS 26.2 (arm64)
- Menu bar click: `menubar click --verify "Trimmy"` + `--index 6` failed (popover not detected); fallback AppleScript open worked.
- Settings open: `osascript` menu item succeeded.
- Screenshots: `/private/tmp/trimmy-menubar.png`, `/private/tmp/trimmy-settings.png`, `/private/tmp/trimmy-settings-annotated.png`.
- Clipboard E2E:
  - Auto-trim ON → `ls | wc -l`.
  - Auto-trim OFF → `ls \\n | wc -l` (unchanged).
  - Auto-trim ON → `ls | wc -l` (trimmed).
  - Keep blank lines ON → `echo one\n\necho two` (blank line preserved, prompt stripped).
  - Box drawing removal ON → `ls -la | grep foo`.
- Clipboard restored: slot `trimmy-e2e`.

## Manual debugging flow (when things go wrong)

1) Menu bar click hits the wrong icon
```bash
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo menubar list
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo menubar click --verify --index <trimmy-index>
```
If you keep hitting a neighbor, increase spacing by moving other menu bar extras temporarily.

2) Trimmy shows an update prompt instead of the menu
```bash
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo list windows --app Trimmy
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo image --window-id <window-id> --path /private/tmp/trimmy-update.png
```
Dismiss the dialog manually or via coordinate click, then re-run the menu bar click.

3) Settings window does not open from the popover
```bash
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo menu click --app Trimmy --item "Settings…"
```

4) `peekaboo see` can’t find settings elements
```bash
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo list windows --app Trimmy
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo see --window-id <settings-window-id> --json > /private/tmp/trimmy-settings.json
jq -r '.data.ui_elements[] | select(.role=="checkbox") | "\(.id)\t\(.description)"' /private/tmp/trimmy-settings.json
```

5) Clipboard does not trim
- Confirm Auto-trim is on (checkbox in Settings).
- Re-seed the clipboard with a command that has strong signals:
  ```bash
  Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action set --verify --text $'ls \\\n | wc -l\n'
  sleep 0.5
  Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action get
  ```
