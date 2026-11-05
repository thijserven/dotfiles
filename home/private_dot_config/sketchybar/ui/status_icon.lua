-- Shared geometry keeps numbered hints beside each status icon.
return function(sbar, name, properties)
  properties.position = "right"
  properties.width = 36
  properties.label = { drawing = false }
  properties.icon.drawing = true
  properties.icon.font = properties.icon.font or "Hack Nerd Font:Regular:18.0"
  properties.icon.width = properties.width
  properties.icon.align = "center"
  properties.icon.padding_left = properties.icon.padding_left or 0
  properties.icon.padding_right = properties.icon.padding_right or 0

  return sbar.add("item", name, properties)
end
