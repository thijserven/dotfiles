local state = require("ui.state")
local cli = require("services.brightness")

local function percentage(value)
  local number = tonumber(value)
  if not number or number ~= number or number < 0 or number > 100 then return end
  return math.floor(number + 0.5)
end

return function(sbar, theme)
  local brightness = require("ui.status_icon")(sbar, "brightness", {
    drawing = false,
    update_freq = 5,
    icon = { string = "􀆮", font = "SF Pro:Regular:16.0" },
  })
  local popup = require("ui.popup")(sbar, theme, brightness, "brightness")
  popup.defer_open = true
  popup.keyboard_state("brightness-popup")
  local keyboard_state_path = os.getenv("HOME") .. "/.cache/sketchybar/brightness-keyboard-popup"
  local available = false
  local keyboard_available = false
  local dragging = false
  local revision = 0
  local commit_sequence = os.time() * 1000000

  local function publish_keyboard_state()
    state.publish(keyboard_state_path, popup.opened and keyboard_available)
  end

  local function row(height)
    local properties = popup.row(height)
    properties.width = 252
    return properties
  end

  popup.spacer("top", popup.top_padding)
  local title = popup.header("title", popup.title(utf8.char(0xf185), "Brightness"), 246)
  title:set({ width = 252 })
  popup.spacer("header", 9)
  local display_hints = {}
  for index, hint in ipairs({ "+ → Screen brightness up", "− → Screen brightness down" }) do
    local row = sbar.add("item", "brightness.keys." .. index, row(22))
    row:set({ label = { string = hint, font = popup.fonts.caption, color = theme.muted, width = 240, align = "left" } })
    display_hints[#display_hints + 1] = row
  end
  popup.separator(252, "hints")

  local error_row
  local function add_slider(target)
    local slider = sbar.add("slider", "brightness." .. target .. ".slider", 198, row(40))
    slider:set({
      label = { drawing = true, string = "—", width = 48, align = "right", padding_left = 0, padding_right = 6 },
      slider = {
        highlight_color = theme.primary,
        knob = { string = "􀀁", font = "SF Pro:Regular:20.0", color = theme.text, y_offset = 0 },
        background = { height = 8, color = theme.surface, corner_radius = 4 },
      },
    })
    -- Final click also covers presses too short for Hammerspoon's drag sampler.
    -- IPC keeps release writes in the same serialized queue as live drag writes.
    slider:subscribe("mouse.clicked", function(env)
      local value = percentage(env.PERCENTAGE)
      if not value or not available or target == "keyboard" and not keyboard_available then return end
      revision = revision + 1
      commit_sequence = commit_sequence + 1
      local command = string.format('require("brightness_controls").commit("%s", %d, %.0f)', target, value, commit_sequence)
      sbar.exec("/Applications/Hammerspoon.app/Contents/Frameworks/hs/hs -c '" .. command .. "'", function(_, code)
        if code ~= 0 then
          dragging = false
          error_row:set({ drawing = true, label = "Hammerspoon control unavailable" })
        end
      end)
    end)
    return slider
  end

  local display_slider = add_slider("display")

  local separator = popup.separator(252, "keyboard")
  local keyboard_hints = {}
  for index, hint in ipairs({ "] → Backlight brightness up", "[ → Backlight brightness down" }) do
    local row = sbar.add("item", "brightness.keyboard.keys." .. index, row(22))
    row:set({ label = { string = hint, font = popup.fonts.caption, color = theme.muted, width = 240, align = "left" } })
    keyboard_hints[#keyboard_hints + 1] = row
  end
  local keyboard_separator = popup.separator(252, "keyboard.hints")
  local keyboard_slider = add_slider("keyboard")
  error_row = sbar.add("item", "brightness.error", row(28))
  error_row:set({ drawing = false, label = { string = "Brightness change failed", color = theme.muted } })
  popup.spacer("bottom")

  local function show_keyboard(show)
    keyboard_available = show
    for _, row in ipairs({ separator, keyboard_separator, keyboard_slider }) do
      row:set({ drawing = show })
    end
    for _, row in ipairs(keyboard_hints) do row:set({ drawing = show }) end
    publish_keyboard_state()
  end
  show_keyboard(false)

  local function show_display(value)
    display_slider:set({ slider = { percentage = value }, label = value .. "%" })
  end

  local function show_keyboard_level(value)
    keyboard_slider:set({ slider = { percentage = value }, label = value .. "%" })
  end

  local refreshing = false
  local function refresh()
    if refreshing or dragging then return end
    refreshing = true
    local request = revision
    sbar.exec(cli.path .. "brightness -l", function(result, code)
      if request ~= revision or dragging then refreshing = false return end
      local display
      if code == 0 then display = cli.display(result) end
      available = display ~= nil
      brightness:set({ drawing = available })
      publish_keyboard_state()
      if not available then
        refreshing = false
        show_keyboard(false)
        popup.close()
        return
      end
      show_display(display)
      sbar.exec(cli.hardware_command, function(hardware, hardware_code)
        if request ~= revision or dragging then refreshing = false return end
        if hardware_code ~= 0 or not cli.keyboard_hardware(hardware) then
          refreshing = false
          show_keyboard(false)
          error_row:set({ drawing = false })
          popup.ready()
          return
        end
        sbar.exec(cli.path .. "mac-brightnessctl", function(output, keyboard_code)
          refreshing = false
          if request ~= revision or dragging then return end
          local keyboard
          if keyboard_code == 0 then keyboard = cli.keyboard(output) end
          show_keyboard(keyboard ~= nil)
          if keyboard then show_keyboard_level(keyboard) end
          error_row:set({ drawing = false })
          popup.ready()
        end)
      end)
    end)
  end

  sbar.add("event", "brightness_state")
  brightness:subscribe("brightness_state", function(env)
    revision = revision + 1
    if env.DRAGGING then dragging = env.DRAGGING == "true" end
    local display, keyboard = percentage(env.DISPLAY), percentage(env.KEYBOARD)
    -- Write acknowledgements must not move a knob ahead of the drag sampler.
    if display and available then
      if env.POINTER == "true" or env.INPUT == "pointer" then
        display_slider:set({ label = display .. "%" })
      else
        show_display(display)
      end
    end
    if keyboard and keyboard_available then
      if env.POINTER == "true" or env.INPUT == "pointer" then
        keyboard_slider:set({ label = keyboard .. "%" })
      else
        show_keyboard_level(keyboard)
      end
    end
    if env.ERROR then
      error_row:set({ drawing = env.ERROR == "true", label = "Brightness change failed" })
    end
    if available then popup.ready() end
  end)

  popup.on_open = function()
    if not available then
      popup.close()
      return
    end
    publish_keyboard_state()
    refresh()
  end
  popup.on_close = publish_keyboard_state
  brightness:subscribe({ "routine", "forced", "system_woke", "display_change", "brightness_change" }, function()
    publish_keyboard_state()
    refresh()
  end)
  refresh()
end
