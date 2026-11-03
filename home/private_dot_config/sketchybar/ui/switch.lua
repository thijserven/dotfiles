-- Native label background forms track; padded thumb moves without changing width.
return function(item, theme)
  local width, thumb, inset = 38, 21, 1

  item:set({
    label = {
      string = "●",
      font = "Helvetica:Regular:28.0",
      color = theme.text,
      width = width,
      align = "left",
      max_chars = 0,
      padding_right = 0,
      background = {
        drawing = true,
        height = 23,
        corner_radius = theme.popup.background.corner_radius,
        color = theme.surface,
      },
    },
  })

  local active, enabled = false, true

  local function color(value)
    return enabled and value or ((value & 0x00ffffff) | 0x66000000)
  end

  return function(on, available)
    if on ~= nil then
      active = on
    end

    if available ~= nil then
      enabled = available
    end

    item:set({
      label = {
        padding_left = active and width - thumb - inset or inset,
        color = color(theme.text),
        background = { color = color(active and theme.primary or theme.surface) },
      },
    })
  end
end
