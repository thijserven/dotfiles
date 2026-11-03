return function(sbar, theme)
  local system = require("services.system")
  local owner = sbar.add("item", "system", {
    position = "right",
    update_freq = 10,
    icon = { drawing = true, string = utf8.char(0xf4bc), font = "Hack Nerd Font:Regular:18.0" },
    label = { string = "—", padding_left = 0 },
  })
  local popup = require("ui.popup")(sbar, theme, owner, "system")
  popup.spacer("top", popup.top_padding)
  popup.header("heading", "System load", 340)
  popup.spacer("header", 9)

  local rows = {}
  for _, spec in ipairs({
    { "cpu", "CPU usage" },
    { "ram", "RAM used / total" },
    { "compressed", "Compressed RAM" },
    { "pressure", "Memory available" },
    { "swap", "Swap used" },
    { "load", "Load (1 / 5 / 15 min)" },
  }) do
    rows[spec[1]] = popup.columns(spec[1], spec[2], "—", 170, 170, 26)
  end
  popup.spacer("bottom")

  local busy = false
  local function refresh()
    if busy then return end
    busy = true

    sbar.exec(system.command, function(result, code)
      busy = false
      local data = code == 0 and system.parse(result)
      if not data then
        owner:set({ label = { string = "—" }, icon = { color = theme.text } })
        for _, row in pairs(rows) do row:set({ label = { string = "Unavailable" } }) end
        return
      end

      local ram = data.used / data.total * 100
      owner:set({
        label = { string = string.format("C %.0f%% M %.0f%%", data.cpu, ram) },
        icon = { color = math.max(data.cpu, ram) >= 85 and theme.primary or theme.text },
      })
      local values = {
        cpu = string.format("%.1f%%", data.cpu),
        ram = string.format("%.1f / %.1f GiB", data.used / 2^30, data.total / 2^30),
        compressed = string.format("%.1f GiB", data.compressed / 2^30),
        pressure = data.available and string.format("%d%%", data.available) or "—",
        swap = data.swap,
        load = data.load,
      }
      for name, value in pairs(values) do rows[name]:set({ label = { string = value } }) end
    end)
  end

  popup.on_open = refresh
  owner:subscribe({ "routine", "forced", "system_woke" }, refresh)
  refresh()
end
