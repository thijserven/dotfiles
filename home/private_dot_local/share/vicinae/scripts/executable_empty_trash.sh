#!/bin/sh
# @vicinae.schemaVersion 1
# @vicinae.title Empty Trash
# @vicinae.icon 🗑️
# @vicinae.mode compact

exec /usr/bin/osascript <<'APPLESCRIPT'
tell application "Finder"
  empty trash without security
end tell

return "Trash emptied."
APPLESCRIPT
