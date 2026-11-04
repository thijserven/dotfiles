-- Adapted from upstream SbarLua volume: native volume_change + async AppleScript.
local function percentage(value)
  local number = tonumber(value)
  if not number or number ~= number or number < 0 or number > 100 then return end
  return math.floor(number)
end

return function(sbar, theme)
  local volume = require("ui.status_icon")(sbar, "volume", {
    update_freq = 5,
    icon = { string = "􀊩", font = "SF Pro:Regular:16.0" },
  })
  local popup = require("ui.popup")(sbar, theme, volume, "volume")
  popup.defer_open = true
  popup.keyboard_state("audio-popup")
  popup.spacer("top", popup.top_padding)

  local function open_settings()
    popup.close()
    sbar.exec("open 'x-apple.systempreferences:com.apple.Sound-Settings.extension'")
  end

  local toggle_mute
  local mute_available = true
  local title = popup.header("title", popup.title(utf8.char(0xf028), "Audio"), 240, {
    icon = "",
    width = 38,
    on_click = function() toggle_mute() end,
    on_title_click = open_settings,
  })
  -- Match speaker's 18px outer inset on switch's right edge.
  title:set({ padding_right = 18, icon = { width = 208 } })
  local show_switch = require("ui.switch")(title, theme)
  show_switch(false)

  popup.spacer("header", 9)
  for index, hint in ipairs({ "+ → Volume up", "− → Volume down", "M → Mute" }) do
    local keys = sbar.add("item", "volume.keys." .. index, popup.row(22))
    keys:set({ label = { string = hint, font = popup.fonts.caption, color = theme.muted } })
  end
  popup.separator(252, "hints")

  local slider = sbar.add("slider", "volume.slider", 198, popup.row(40))
  slider:set({
    label = { drawing = true, string = "0%", width = 48, align = "right", padding_left = 0, padding_right = 6 },
    slider = {
      highlight_color = theme.primary,
      knob = { string = "􀀁", font = "SF Pro:Regular:20.0", color = theme.text, y_offset = 0 },
      background = { height = 8, color = theme.surface, corner_radius = 4 },
    },
  })

  popup.separator(252)
  local heading = sbar.add("item", "volume.device", popup.row())
  heading:set({
    label = { string = "Output devices", color = theme.muted, font = popup.fonts.body },
  })
  popup.spacer("bottom")

  local level = 0
  local function show(value)
    local number = percentage(value)
    if not number then return end
    level = number
    local icon = level == 0 and "􀊣" or "􀊩"
    volume:set({ icon = icon })
    title:set({ icon = { string = popup.title(utf8.char(level == 0 and 0xf026 or 0xf028), "Audio") } })
    slider:set({ slider = { percentage = level }, label = level .. "%" })
  end

  local function receive_volume(result, code)
    if code ~= 0 or type(result) ~= "string" then return end

    local muted, value = result:match("^(%a+):(%d+)")
    if muted ~= "true" and muted ~= "false" then return end

    local is_muted = muted == "true"
    show(is_muted and 0 or value)
    show_switch(not is_muted, mute_available)
  end

  sbar.add("event", "audio_mute_state")
  volume:subscribe("audio_mute_state", function(env)
    if env.MUTED ~= "true" and env.MUTED ~= "false" then return end
    show_switch(env.MUTED == "false", mute_available)
    if env.MUTED == "true" then show(0) end
  end)

  local refreshing = false
  local function refresh()
    if refreshing then return end
    refreshing = true
    sbar.exec([[osascript -e 'set settings to get volume settings
      return (output muted of settings as text) & ":" & (output volume of settings as text)']], function(result, code)
      refreshing = false
      receive_volume(result, code)
    end)
  end

  local last_refresh = 0
  local function volume_changed(env)
    show(env.INFO)
    local now = os.time()
    if popup.opened and now ~= last_refresh then
      last_refresh = now
      refresh()
    end
  end

  volume:subscribe("volume_change", volume_changed)
  volume:subscribe({ "forced", "system_woke" }, refresh)

  local function set_volume(env)
    local value = percentage(env.PERCENTAGE)
    if not value then return end
    sbar.exec("osascript -e 'set volume output volume " .. value .. " without output muted'", function(_, code)
      if code == 0 then
        show(value)
        show_switch(true, mute_available)
      end
    end)
  end

  slider:subscribe("mouse.clicked", set_volume)

  local function scroll_volume(env)
    local delta = tonumber(env.SCROLL_DELTA)
    if not delta or delta ~= delta or math.abs(delta) > 100 then return end
    local value = math.max(0, math.min(100, level + delta * 5))
    sbar.exec("osascript -e 'set volume output volume " .. math.floor(value) .. "'")
  end

  volume:subscribe("mouse.scrolled", scroll_volume)

  toggle_mute = function()
    if not mute_available then return end
    sbar.exec("SwitchAudioSource -t output -m toggle", function(_, code)
      if code == 0 then
        refresh()
      else
        mute_available = false
        show_switch(nil, false)
      end
    end)
  end

  -- Closing/reopening invalidates outstanding device-list callbacks.
  local generation = 0
  local rows = {}
  local device_ids = {}

  popup.on_close = function()
    generation = generation + 1
  end

  local function select_device(id)
    sbar.exec("SwitchAudioSource -t output -i " .. id, function(_, code)
      if code == 0 then
        mute_available = true
        for _, row in pairs(rows) do
          row:set({ icon = { color = theme.text }, label = { color = theme.text } })
        end
        if rows[id] then
          rows[id]:set({ icon = { color = theme.primary }, label = { color = theme.primary } })
        end
        refresh()
      else
        heading:set({ label = "Could not switch output" })
      end
    end)
  end

  sbar.add("event", "audio_select_output")
  volume:subscribe("audio_select_output", function(env)
    if not popup.opened then return end
    local index = tonumber(env.INDEX)
    local id = index and device_ids[index]
    if id then select_device(id) end
  end)

  local function add_device(id)
    local row = popup.columns("output." .. id, "", "", 222, 30)
    row:subscribe("mouse.clicked", function() select_device(id) end)
    rows[id] = row
    return row
  end

  local function highlight_device(request)
    sbar.exec("SwitchAudioSource -c -t output -f json", function(current, code)
      if request ~= generation or code ~= 0 or type(current) ~= "table" then return end
      local row = rows[tostring(current.id)]
      if row then row:set({ icon = { color = theme.primary }, label = { color = theme.primary } }) end
    end)
  end

  local function refresh_devices(request)
    -- SwitchAudioSource emits one JSON object per line; jq folds it into one array.
    sbar.exec("SwitchAudioSource -a -t output -f json | jq -s '.'", function(devices, code)
      if request ~= generation then return end
      if code ~= 0 or type(devices) ~= "table" or #devices == 0 then
        heading:set({ label = "Output devices unavailable" })
        popup.ready()
        return
      end
      heading:set({ label = "Output devices" })
      for _, device in ipairs(devices) do
        local id = tostring(device.id or "")
        if id:match("^%d+$") and #id < 20 and type(device.name) == "string" then
          device_ids[#device_ids + 1] = id
          local row = rows[id] or add_device(id)
          row:set({
            drawing = true,
            icon = { string = device.name, color = theme.text, max_chars = 28 },
            label = { string = tostring(#device_ids), color = theme.text },
          })
        end
      end
      -- Popup order follows insertion, not global --move order. Append spacer last.
      sbar.remove("volume.padding.bottom")
      popup.spacer("bottom")
      highlight_device(request)
      popup.ready()
    end)
  end

  popup.on_open = function()
    mute_available = true
    generation = generation + 1
    for id in pairs(rows) do sbar.remove("volume.output." .. id) end
    rows = {}
    device_ids = {}
    heading:set({ label = "Output devices" })
    refresh()
    refresh_devices(generation)
  end
end
