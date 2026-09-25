#!/usr/bin/env bash
# Installs ChuChu-Theme into Clawd on Desk and makes it the active theme.
# Usage (from the repo root): bash chuchu/install-chuchu.sh
# Linux and macOS. On Windows, follow the manual steps in the README.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
THEME_SRC="$HERE/chuchu-theme"
THEME_ID="chuchu-theme"

case "$(uname -s)" in
  Linux)  CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/clawd-on-desk" ;;
  Darwin) CONFIG_DIR="$HOME/Library/Application Support/clawd-on-desk" ;;
  *) echo "Unsupported OS. Follow the manual steps in README.md." >&2; exit 1 ;;
esac
PREFS="$CONFIG_DIR/clawd-prefs.json"

stop_clawd() {
  # Clawd rewrites clawd-prefs.json when it exits, so it must be stopped before we edit it.
  # SIGKILL on Linux: a normal SIGTERM has been seen to hang the app.
  if [ "$(uname -s)" = Linux ]; then
    pkill -9 -x clawd-on-desk 2>/dev/null || true
    sleep 1
    rm -f "$CONFIG_DIR"/Singleton{Lock,Socket,Cookie}
  else
    osascript -e 'quit app "Clawd on Desk"' 2>/dev/null || true
    sleep 2
  fi
}

start_clawd() {
  if [ "$(uname -s)" = Linux ]; then
    if command -v clawd-on-desk >/dev/null; then
      (nohup clawd-on-desk >/dev/null 2>&1 &)
    else
      echo "Start Clawd on Desk from your app menu."
    fi
  else
    open -a "Clawd on Desk" 2>/dev/null || echo "Start Clawd on Desk from Applications."
  fi
}

echo "1/4 Stopping Clawd on Desk (if running)"
stop_clawd

echo "2/4 Copying theme to $CONFIG_DIR/themes/$THEME_ID"
mkdir -p "$CONFIG_DIR/themes"
rm -rf "$CONFIG_DIR/themes/$THEME_ID"
cp -R "$THEME_SRC" "$CONFIG_DIR/themes/$THEME_ID"

echo "3/4 Selecting the theme in $PREFS"
if [ -f "$PREFS" ]; then
  cp "$PREFS" "$PREFS.bak-before-chuchu"
  python3 - "$PREFS" "$THEME_ID" <<'EOF'
import json, sys
path, theme = sys.argv[1], sys.argv[2]
with open(path) as f:
    prefs = json.load(f)
prefs["theme"] = theme
with open(path, "w") as f:
    json.dump(prefs, f, indent=2, ensure_ascii=False)
EOF
else
  echo "   No prefs file yet (Clawd has never been launched)."
  echo "   After Clawd starts, pick ChuChu-Theme in Settings -> Theme."
fi

echo "4/4 Starting Clawd on Desk"
start_clawd
echo "Done. ChuChu should appear in a few seconds."
