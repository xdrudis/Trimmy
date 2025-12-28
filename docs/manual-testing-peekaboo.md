---
summary: "Manual Peekaboo end-to-end check for Trimmy (menu bar, settings, clipboard)."
read_when:
  - Running a full Trimmy validation using Peekaboo
  - Verifying menu bar + settings + clipboard trimming end-to-end
---

# Trimmy E2E Manual Test (Peekaboo)

Goal: use Peekaboo to open Trimmy from the menu bar, open Settings, capture a screenshot, and verify clipboard trimming end-to-end.

## Prereqs
- Trimmy running (`open -a Trimmy`).
- Peekaboo CLI built (`Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo`).
- Permissions granted: `peekaboo permissions status`.

## Notes
- Trimmy reads the clipboard via `NSPasteboard.string` (type `.string`).
  Peekaboo now writes `.string` by default when using `clipboard set --text`.
  If you are on an older Peekaboo build, pass `--also-text` to add the `.string` representation.
- The settings checkbox element IDs are dynamic per snapshot; capture a fresh snapshot and use those IDs.
- The Trimmy menu bar popover is not reliably exposed to `peekaboo see`; use the Settings window for checkbox targeting.

## Runbook

1) Pull latest
```bash
cd ~/Projects/Trimmy

git pull
```

2) Open Trimmy menu bar item (Peekaboo)
```bash
cd ~/Projects/Peekaboo

Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo menubar list
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo menubar click "Trimmy"
```

3) Open Trimmy Settings (app menu)
```bash
osascript -e 'tell application "System Events" to tell process "Trimmy" to click menu item "Settings…" of menu 1 of menu bar item "Trimmy" of menu bar 1'
```

4) Capture Settings screenshot
```bash
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo list windows --app Trimmy
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo image --window-id <settings-window-id> --path /private/tmp/trimmy-settings.png
```

5) Grab checkbox IDs (snapshot + jq)
```bash
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo see --window-id <settings-window-id> --json-output > /private/tmp/trimmy-settings.json
jq -r '.data.ui_elements[] | select(.role=="checkbox") | "\(.id)\t\(.description)"' /private/tmp/trimmy-settings.json
jq -r '.data.snapshot_id' /private/tmp/trimmy-settings.json
```

6) Clipboard E2E (Peekaboo)
```bash
# Save clipboard
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action save --slot trimmy-e2e --log-level debug

# Toggle Auto-trim (use checkbox ID for "Auto-trim enabled")
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo click --on <auto-trim-id> --snapshot <snapshot-id>

# Auto-trim OFF → unchanged
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action set \
  --text $'ls \\\n | wc -l\n'

sleep 0.5
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action get

# Auto-trim ON → trimmed
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo click --on <auto-trim-id> --snapshot <snapshot-id>
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action set \
  --text $'ls \\\n | wc -l\n'

sleep 0.5
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action get

# Keep blank lines ON (checkbox "Keep blank lines")
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo click --on <keep-blank-lines-id> --snapshot <snapshot-id>
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action set \
  --text $'$ echo one\n\n$ echo two\n'

sleep 0.5
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action get

# Box drawing removal ("Remove box drawing chars (│┃)")
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action set \
  --text $'│ ls -la \\\n│ | grep foo\n'

sleep 0.5
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action get

# Restore clipboard
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action restore --slot trimmy-e2e --log-level debug
```

7) Restore settings state (optional)
```bash
# Toggle "Keep blank lines" back off
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo click --on <keep-blank-lines-id> --snapshot <snapshot-id>
```

## Latest run (2025-12-28)
- Menu bar click: OK (`peekaboo menubar click "Trimmy"`).
- Settings opened via app menu (System Events).
- Screenshot: `/private/tmp/trimmy-settings.png`.
- Clipboard E2E:
  - Auto-trim OFF → `ls \\n | wc -l` (unchanged).
  - Auto-trim ON → `ls | wc -l` (trimmed).
  - Keep blank lines ON → `echo one\n\necho two` (blank line preserved).
  - Box drawing removal ON → `ls -la | grep foo`.
- Clipboard restored to slot `trimmy-e2e`.

## Manual debugging flow (when things go wrong)

1) Menu bar click hits the wrong icon
```bash
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo menubar list
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo menubar click --index <trimmy-index>
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
osascript -e 'tell application "System Events" to tell process "Trimmy" to click menu item "Settings…" of menu 1 of menu bar item "Trimmy" of menu bar 1'
```

4) `peekaboo see` can’t find settings elements
```bash
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo list windows --app Trimmy
Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo see --window-id <settings-window-id> --json-output > /private/tmp/trimmy-settings.json
jq -r '.data.ui_elements[] | select(.role=="checkbox") | "\(.id)\t\(.description)"' /private/tmp/trimmy-settings.json
```

5) Clipboard does not trim
- Confirm Auto-trim is on (checkbox in Settings).
- Re-seed the clipboard with a command that has strong signals:
  ```bash
  Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action set --text $'ls \\\n | wc -l\n'
  sleep 0.5
  Apps/CLI/.build/arm64-apple-macosx/debug/peekaboo clipboard --action get
  ```
