return function(sbar)
  local battery = require("ui.status_icon")(sbar, "battery", {
    update_freq = 60, drawing = false,
    -- Optical inset brings narrow battery glyph closer to brightness.
    icon = { string = "󰁹", padding_left = -3, padding_right = 3 },
  })

  local function receive_battery(result, code)
    if code ~= 0 or type(result) ~= "string" then return end

    local percent = result:match("(%d+)%%")
    -- Match macOS: external power shows bolt even when full or charging paused.
    local charging = result:find("'AC Power'", 1, true) ~= nil
    local level = percent and tonumber(percent)
    local icons = { "󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹" }
    local icon = level and icons[math.floor(level / 10) + 1] or "󰁹"

    if charging then
      icon = "󰂄"
    end

    battery:set({
      drawing = percent ~= nil,
      icon = { string = icon },
    })
  end

  local function refresh_battery()
    sbar.exec("pmset -g batt", receive_battery)
  end

  local function open_battery()
    sbar.exec("open 'x-apple.systempreferences:com.apple.Battery-Settings.extension'")
  end

  require("ui.shortcuts").register("battery", { toggle = open_battery, title = "Open Battery settings" }, battery)
  battery:subscribe({ "routine", "forced", "power_source_change", "system_woke" }, refresh_battery)
  battery:subscribe("mouse.clicked", open_battery)
  refresh_battery()
end
