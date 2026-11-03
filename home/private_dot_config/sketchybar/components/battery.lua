-- Follows upstream SbarLua calendar/battery: Lua clock, async pmset, wake events.
return function(sbar)
  -- Right-side items grow inward; add clock first to keep it at far right.
  local clock = sbar.add("item", "clock", { position = "right", update_freq = 15 })

  local function refresh_clock()
    clock:set({ label = os.date("%A %b %d %H:%M") })
  end

  clock:subscribe({ "routine", "forced", "system_woke" }, refresh_clock)

  local function open_clock()
    sbar.exec("open -a Clock")
  end

  require("ui.shortcuts").register("clock", { toggle = open_clock, title = "Open Clock" }, clock)
  clock:subscribe("mouse.clicked", open_clock)

  -- Right-side items grow inward: separate clock from feature icons.
  sbar.add("item", "status.gap", {
    position = "right",
    width = 5,
    icon = { drawing = false },
    label = { drawing = false },
  })

  local battery = sbar.add("item", "battery", {
    position = "right", update_freq = 60,
    icon = { drawing = true, string = "􀛨", padding_right = 3 },
    label = { padding_left = 3 },
  })

  local function receive_battery(result, code)
    if code ~= 0 or type(result) ~= "string" then return end

    local percent = result:match("(%d+)%%")
    -- Match macOS: external power shows bolt even when full or charging paused.
    local charging = result:find("'AC Power'", 1, true) ~= nil
    battery:set({
      drawing = percent ~= nil, label = percent and (percent .. "%") or "",
      icon = { string = charging and "􀢋" or "􀛨" },
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
end
