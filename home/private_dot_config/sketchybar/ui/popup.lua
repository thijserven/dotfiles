-- Shared popup layout and mouse lifecycle; widths stay specific to each feature.
local state = require("ui.state")
local popups = {}
local listener
local state_path = os.getenv("HOME") .. "/.cache/sketchybar/popup-open"

local function publish_state()
  local opened = false
  for _, popup in ipairs(popups) do opened = opened or popup.opened end
  state.publish(state_path, opened)
end

return function(sbar, theme, owner, prefix)
  if not listener then
    sbar.add("event", "popup_close_all")
    listener = sbar.add("item", "popup.lifecycle", { drawing = false, update_freq = 5 })
    listener:subscribe("routine", publish_state)
    listener:subscribe("popup_close_all", function()
      for _, popup in ipairs(popups) do
        if popup.opened then popup.close() end
      end
    end)
    publish_state()
  end
  local popup = {
    opened = false,
    top_padding = 10,
    title_gap = "  ",
    fonts = {
      body = "Hack Nerd Font:Regular:13.0",
      title = "Hack Nerd Font:Bold:16.0",
      caption = "Hack Nerd Font:Regular:12.0",
    },
  }
  local position = "popup." .. prefix

  owner:set({ popup = theme.popup })

  local keyboard_state_path

  local function publish_keyboard_state()
    if keyboard_state_path then
      state.publish(keyboard_state_path, popup.opened)
    end
  end

  function popup.keyboard_state(name)
    keyboard_state_path = os.getenv("HOME") .. "/.cache/sketchybar/" .. name
    publish_keyboard_state()
    owner:subscribe("routine", publish_keyboard_state)
  end

  function popup.row(height)
    return {
      position = position,
      padding_left = 12,
      padding_right = 12,
      background = { height = height or 28, color = 0x00000000 },
      icon = { drawing = false },
      label = {
        font = popup.fonts.body,
        padding_left = 6,
        padding_right = 6,
        max_chars = 35,
      },
    }
  end

  function popup.columns(name, left, right, left_width, right_width, height)
    local properties = popup.row(height)

    properties.icon = {
      drawing = true,
      string = left,
      color = theme.muted,
      font = popup.fonts.body,
      width = left_width,
      align = "left",
      padding_left = 6,
      padding_right = 0,
    }
    properties.label = {
      string = right or "",
      font = popup.fonts.body,
      width = right_width,
      align = "right",
      padding_left = 0,
      padding_right = 6,
      max_chars = 35,
    }

    return sbar.add("item", prefix .. "." .. name, properties)
  end

  function popup.title(icon, text)
    return icon .. popup.title_gap .. text
  end

  function popup.header(name, title, width, action)
    local heading = popup.columns(name, title, action and action.icon or "", width - 30, 30, 30)

    heading:set({
      icon = {
        color = theme.text,
        font = { family = "Hack Nerd Font", style = "Bold", size = 16.0, typographical_width = true },
      },
      label = { drawing = action ~= nil, font = popup.fonts.title, color = theme.text },
    })

    if action then
      local function handle_pointer(point, code)
        if code ~= 0 or type(point) ~= "table"
          or type(point.x) ~= "number" or type(point.y) ~= "number" then
          return
        end

        local geometry = heading:query()
        if type(geometry) ~= "table" then
          return
        end

        for _, frame in pairs(geometry.bounding_rects or {}) do
          local x, y = frame.origin[1], frame.origin[2]
          local w, h = frame.size[1], frame.size[2]

          if point.x >= x and point.x < x + w and point.y >= y and point.y < y + h then
            if point.x >= x + w - (action.width or 36) then
              action.on_click()
            else
              action.on_title_click()
            end
            return
          end
        end
      end

      local function handle_click()
        if not action.on_title_click then
          action.on_click()
          return
        end

        -- SketchyBar reports item clicks, not icon/label clicks. Hit-test header slot.
        sbar.exec([[osascript -l JavaScript -e 'ObjC.import("CoreGraphics"); var p = $.CGEventGetLocation($.CGEventCreate(null)); JSON.stringify({x: p.x, y: p.y})']], handle_pointer)
      end

      heading:subscribe("mouse.clicked", handle_click)
    end

    return heading
  end

  function popup.spacer(name, height)
    return sbar.add("item", prefix .. ".padding." .. name, {
      position = position,
      width = 0,
      icon = { drawing = false },
      label = { drawing = false },
      background = { height = height or 12, color = 0x00000000 },
    })
  end

  function popup.separator(width, name)
    local properties = popup.row(21)

    properties.width = width
    properties.icon = {
      drawing = true,
      string = "",
      width = width,
      padding_left = 0,
      padding_right = 0,
      background = { color = theme.surface, height = 1, drawing = true },
    }
    properties.label = { drawing = false }

    return sbar.add("item", prefix .. ".separator" .. (name and "." .. name or ""), properties)
  end

  function popup.close()
    popup.opened = false
    publish_state()
    publish_keyboard_state()
    owner:set({ popup = { drawing = false } })

    if popup.on_close then
      popup.on_close()
    end
  end

  function popup.ready()
    if popup.opened then
      owner:set({ popup = { drawing = true } })
    end
  end

  function popup.toggle()
    if popup.opened then
      popup.close()
      return
    end

    popup.opened = true
    publish_state()
    publish_keyboard_state()

    -- Async content calls ready() after layout settles, avoiding partial first frames.
    if popup.on_open then
      popup.on_open()
    end
    if not popup.defer_open then popup.ready() end
  end

  popups[#popups + 1] = popup
  require("ui.shortcuts").register(prefix, popup, owner)

  owner:subscribe("mouse.exited.global", popup.close)
  owner:subscribe("mouse.clicked", popup.toggle)

  return popup
end
