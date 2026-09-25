#!/usr/bin/env bash
# Plays ChuChu's Claude-driven animations one after another by sending fake events to Clawd.
# Usage: ~/chuchu-demo.sh            (whole tour)
#        ~/chuchu-demo.sh error      (just one state)
PORT=$(python3 -c 'import json,pathlib;print(json.loads((pathlib.Path.home()/".clawd/runtime.json").read_text())["port"])' 2>/dev/null || echo 23333)

send() {  # state event
  code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "http://127.0.0.1:$PORT/state" \
    -H 'content-type: application/json' \
    -d "{\"agent_id\":\"claude-code\",\"session_id\":\"chuchu-demo\",\"state\":\"$1\",\"event\":\"$2\"}")
  printf '%-13s %-20s HTTP %s\n' "$1" "$2" "$code"
}

if [ -n "$1" ]; then
  send "$1" "${2:-PreToolUse}"
  exit
fi

send thinking     UserPromptSubmit;   sleep 4
send working      PreToolUse;         sleep 5
send juggling     SubagentStart;      sleep 5
send carrying     PreToolUse;         sleep 4
send sweeping     PreCompact;         sleep 6
send error        PostToolUseFailure; sleep 6
send notification Notification;       sleep 6
send attention    Stop;               sleep 5
send idle         SessionEnd
echo "Done. When ChuChu is idle: double-click = poke, 4 fast clicks = jump, drag = carry; leave the mouse still ~1 min for sleep."
