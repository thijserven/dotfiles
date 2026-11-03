return function(sbar)
  local ok, icons = pcall(require, "helpers.icon_map")
  if not ok then icons = {} end

  local app = sbar.add("item", "front_app", {
    position = "left",
    icon = { drawing = true, string = "􀆊", font = "SF Pro:Semibold:13.0" },
  })

  local function find_icon(name)
    if icons[name] then return icons[name] end

    for pattern, glyph in pairs(icons) do
      if pattern:sub(-1) == "*" then
        local prefix = pattern:sub(1, -2)
        if name:sub(1, #prefix) == prefix then return glyph end
      end
    end
  end

  local function update(name)
    local icon = find_icon(name)
    app:set({
      label = {
        string = icon or "􀑓",
        font = icon and "sketchybar-app-font:Regular:16.0" or "SF Pro:Regular:20.0",
      },
    })
  end

  -- Ignore stale queries when a newer app-switch event already arrived.
  local generation = 0

  local function app_switched(env)
    generation = generation + 1
    update(tostring(env.INFO or ""))
  end

  app:subscribe("front_app_switched", app_switched)

  local function refresh()
    local requested = generation
    sbar.exec("aerospace list-windows --focused --format '%{app-name}'", function(result, code)
      if code ~= 0 or requested ~= generation or type(result) ~= "string" then return end
      update(result:gsub("[\r\n]+$", ""))
    end)
  end

  app:subscribe({ "forced", "system_woke" }, refresh)
end
