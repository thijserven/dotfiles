return function(sbar)
  -- Right-side items grow inward; add clock first to keep it at far right.
  local clock = sbar.add("item", "clock", { position = "right", update_freq = 15 })

  local function refresh_clock()
    clock:set({ label = os.date("%A %H:%M") })
  end

  clock:subscribe({ "routine", "forced", "system_woke" }, refresh_clock)

  local function open_calendar()
    sbar.exec("open 'https://calendar.google.com'")
  end

  require("ui.shortcuts").register("clock", { toggle = open_calendar, title = "Open Google Calendar" }, clock)
  clock:subscribe("mouse.clicked", open_calendar)
end
