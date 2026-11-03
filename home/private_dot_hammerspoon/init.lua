require("hs.ipc")

hs.autoLaunch(false)
hs.menuIcon(false)

require("sketchybar_menu_guard")
require("hyperkey")
require("sketchybar_audio_keys")
local sketchybar = require("sketchybar")

for slot = 1, 10 do
  hs.hotkey.bind({ "cmd", "alt", "ctrl", "shift" }, tostring(slot % 10), function()
    sketchybar.trigger("popup_toggle", "SLOT=" .. slot, "Popup toggle failed")
  end)
end
