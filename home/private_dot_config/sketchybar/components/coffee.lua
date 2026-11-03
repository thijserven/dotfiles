-- Scope assertions to this user's bar; -w releases them when SketchyBar exits.
local find_bar = [[
uid="$(id -u)"
# macOS pgrep excludes ancestors by default; bar is callback's ancestor.
bar_pid="$(pgrep -a -o -x -u "$uid" sketchybar)"
case "$bar_pid" in ''|*[!0-9]*) exit 1 ;; esac
pattern="/usr/bin/caffeinate -di -w $bar_pid"
]]

local toggle = [[
if pgrep -f -x -u "$uid" "$pattern" >/dev/null; then
  pkill -f -x -u "$uid" "$pattern" || exit 1
  echo off
else
  /usr/bin/caffeinate -di -w "$bar_pid" </dev/null >/dev/null 2>&1 &
  kill -0 "$!" || exit 1
  echo on
fi
]]

local query = [[
if pgrep -f -x -u "$uid" "$pattern" >/dev/null; then echo on; else echo off; fi
]]

return function(sbar, theme)
  sbar.add("event", "coffee_toggle")

  local coffee = sbar.add("item", "coffee", {
    position = "right",
    width = 36,
    update_freq = 10,
    icon = {
      drawing = true,
      string = "󰅶",
      font = "Hack Nerd Font:Regular:18.0",
      color = theme.text,
    },
    label = { drawing = false },
  })

  local busy = false

  local function receive_state(result, code)
    busy = false
    if code ~= 0 or type(result) ~= "string" then return end

    local state = result:match("^(%a+)%s*$")
    if state ~= "on" and state ~= "off" then return end

    coffee:set({ icon = { color = state == "on" and theme.primary or theme.text } })
  end

  local function update(action)
    if busy then return end
    busy = true

    sbar.exec(find_bar .. action, receive_state)
  end

  local function toggle_coffee() update(toggle) end
  require("ui.shortcuts").register("coffee", { toggle = toggle_coffee, title = "Toggle caffeinate" }, coffee)
  coffee:subscribe({ "mouse.clicked", "coffee_toggle" }, toggle_coffee)
  coffee:subscribe({ "routine", "forced", "system_woke" }, function() update(query) end)
end
