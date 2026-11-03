package.cpath = os.getenv("HOME") .. "/.local/share/sketchybar_lua/?.so;" .. package.cpath
local ok, sbar = pcall(require, "sketchybar")
assert(ok, "SbarLua unavailable or Lua ABI changed. See README SketchyBar rebuild instructions.\n" .. tostring(sbar))

-- Upstream SbarLua lifecycle: batch startup, then one persistent event loop.
sbar.begin_config()

local theme = require("theme")

sbar.bar({
  position = "top",
  topmost = false,
  height = 32,
  color = theme.base,
  padding_left = 8,
  padding_right = 8,
})

sbar.default({
  icon = {
    drawing = false,
    font = "SF Pro:Regular:16.0",
    color = theme.text,
    padding_left = 10,
    padding_right = 10,
  },
  label = {
    font = "Hack Nerd Font:Bold:13.0",
    color = theme.text,
    padding_left = 10,
    padding_right = 10,
  },
  -- Background color/height implicitly enable drawing; do not set them on items.
  background = { drawing = false },
})

-- Insertion order controls layout; right-side items grow inward.
local shortcuts = require("ui.shortcuts")
for _, name in ipairs({ "aerospace", "current_app", "battery", "audio", "network", "coffee", "system" }) do
  -- Contextual AeroSpace service help keeps its own bindings, not numbered slots.
  shortcuts.enabled = name ~= "aerospace" and name ~= "current_app"
  require("components." .. name)(sbar, theme)
end
shortcuts.enabled = false
shortcuts.start(sbar)

sbar.hotload(true)
sbar.end_config()
sbar.event_loop()
