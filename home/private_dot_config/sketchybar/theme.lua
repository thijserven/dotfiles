-- Catppuccin Macchiato palette and shared popup appearance.
return {
  base = 0xff24273a,
  surface = 0xff494d64,
  text = 0xffcad3f5,
  muted = 0xff939ab7,
  success = 0xffa6da95,
  warning = 0xfff5a97f,
  error = 0xffed8796,
  primary = 0xffc6a0f6, -- Shared active/highlight color.

  popup = {
    -- Minimum cell height, not default row height; keep separator compact.
    align = "right",
    height = 2,
    y_offset = 6,
    background = {
      color = 0xff24273a,
      border_color = 0xff494d64,
      border_width = 1,
      corner_radius = 10,
    },
  },
}
