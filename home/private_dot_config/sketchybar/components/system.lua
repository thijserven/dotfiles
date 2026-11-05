return function(sbar, theme)
  local system = require("services.system")
  local owner = require("ui.status_icon")(sbar, "system", {
    update_freq = 10,
    icon = { string = utf8.char(0xf4bc) },
  })
  local popup = require("ui.popup")(sbar, theme, owner, "system")
  popup.spacer("top", popup.top_padding)
  local heading = popup.header("heading", "System load", 340)
  popup.open_on_click(heading, "/usr/bin/open -a Stats")
  popup.spacer("header", 9)

  local rows = {}
  for _, spec in ipairs({
    { "cpu", "CPU usage" },
    { "temperature", "CPU temperature" },
    { "ram", "RAM usage" },
    { "ram_space", "RAM used / total" },
    { "disk_activity", "Disk usage" },
    { "disk", "Storage used" },
    { "disk_space", "Storage used / total" },
  }) do
    local activity = spec[1] == "disk_activity"
    rows[spec[1]] = popup.columns(spec[1], spec[2], "—", activity and 100 or 170, activity and 240 or 170, 26)
  end
  popup.separator(340)
  popup.columns("consumers.heading", "Top consumers", "", 340, 0, 26)
  popup.spacer("consumers.heading", 6)
  local consumers = {}
  for index = 1, 3 do
    consumers[index] = popup.columns("consumer." .. index, "—", "—", 170, 170, 26)
  end
  popup.spacer("bottom")

  local function usage_color(value, warning, error)
    if not value then return theme.muted end
    if value >= error then return theme.error end
    if value >= warning then return theme.warning end
    return theme.text
  end

  local function show_unavailable()
    owner:set({ icon = { color = theme.text } })
    for _, row in pairs(rows) do
      row:set({ label = { string = "Unavailable", color = theme.muted } })
    end
    for _, row in ipairs(consumers) do
      row:set({ icon = { string = "—" }, label = { string = "Unavailable", color = theme.muted } })
    end
  end

  local function show_system(data)
    local ram = data.used / data.total * 100
    local values = {
      cpu = string.format("%.1f%%", data.cpu),
      temperature = data.temperature and string.format("%.1f °C", data.temperature) or "Unavailable",
      ram = string.format("%.1f%%", ram),
      ram_space = string.format("%.1f / %.1f GiB", data.used / 2^30, data.total / 2^30),
      disk_activity = data.activity and string.format("R %.1f / W %.1f MiB/s", data.activity.read, data.activity.write) or "—",
      disk = data.disk and string.format("%.1f%%", data.disk.used / data.disk.total * 100) or "Unavailable",
      disk_space = data.disk and string.format("%.1f / %.1f GiB", data.disk.used / 2^30, data.disk.total / 2^30) or "Unavailable",
    }
    local disk_color = usage_color(data.disk and data.disk.used / data.disk.total * 100, 80, 90)
    local ram_color = usage_color(ram, 70, 90)
    local colors = {
      cpu = usage_color(data.cpu, 70, 90),
      temperature = usage_color(data.temperature, 80, 95),
      ram = ram_color,
      ram_space = ram_color,
      disk_activity = data.activity and theme.text or theme.muted,
      disk = disk_color,
      disk_space = disk_color,
    }
    local overall_color = theme.text
    for _, color in ipairs({ colors.cpu, colors.temperature, colors.ram }) do
      if color == theme.error then
        overall_color = theme.error
        break
      elseif color == theme.warning then
        overall_color = theme.warning
      end
    end
    owner:set({ label = { string = "" }, icon = { color = overall_color } })
    for name, value in pairs(values) do
      rows[name]:set({ label = { string = value, color = colors[name] } })
    end
    for index, row in ipairs(consumers) do
      local app = data.consumers[index]
      row:set({
        icon = { string = app and app.name or "—" },
        label = {
          string = app and string.format("%.1f%% / %.2f GiB", app.cpu, app.memory / 2^30) or "—",
          color = usage_color(app and math.max(app.cpu, app.memory / data.total * 100), 70, 90),
        },
      })
    end
  end

  local busy = false
  local function receive_system(result, code)
    busy = false
    local data = code == 0 and system.parse(result)
    if data then
      show_system(data)
    else
      show_unavailable()
    end
  end

  local function refresh()
    if busy then return end
    busy = true
    sbar.exec(system.command, receive_system)
  end

  popup.on_open = refresh
  owner:subscribe({ "routine", "forced", "system_woke" }, refresh)
  refresh()
end
