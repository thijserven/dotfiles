local shortcuts = { entries = {}, enabled = false }

function shortcuts.register(name, popup, owner)
  if not shortcuts.enabled then return end

  -- Right-side insertion grows inward; reverse registration gives visual order.
  table.insert(shortcuts.entries, 1, { name = name, popup = popup, owner = owner })
end

function shortcuts.start(sbar)
  sbar.add("event", "hyper_hints")
  sbar.add("event", "popup_toggle")
  local listener = sbar.add("item", "popup.shortcuts", { drawing = false })
  listener:subscribe("popup_toggle", function(env)
    local slot = tonumber(env.SLOT)
    local entry = slot and slot % 1 == 0 and slot >= 1 and slot <= 10 and shortcuts.entries[slot]
    if not entry then return end

    for _, other in ipairs(shortcuts.entries) do
      if other ~= entry and other.popup.opened then other.popup.close() end
    end
    entry.popup.toggle()
  end)

  local hints = {}
  listener:subscribe("hyper_hints", function(env)
    for _, hint in ipairs(hints) do hint:set({ drawing = env.STATE == "on" }) end
  end)

  local rows = {}
  for slot, entry in ipairs(shortcuts.entries) do
    if slot > 10 then break end
    if entry.owner then
      local hint = sbar.add("item", "hyper.hint." .. entry.name, {
        position = "right",
        drawing = false,
        width = 0,
        padding_left = 0,
        padding_right = 0,
        y_offset = -7,
        icon = { drawing = false },
        label = {
          drawing = true,
          string = slot == 10 and "0" or tostring(slot),
          font = "Hack Nerd Font:Bold:9.0",
          align = "right",
          -- Balanced padding keeps number visible and properly positioned.
          padding_left = 8,
          padding_right = 2,
        },
      })
      -- Zero-width item overlays owner's lower-right edge without shifting layout.
      sbar.exec("sketchybar --move hyper.hint." .. entry.name .. " before " .. entry.name)
      hints[#hints + 1] = hint
    end
    rows[#rows + 1] = string.format(
      '{"title":"%s","keys":"hyper + %s","category":"SketchyBar"}',
      type(entry.popup.title) == "string" and entry.popup.title or ("Toggle " .. entry.name .. " popup"),
      slot == 10 and "0" or tostring(slot)
    )
  end

  -- Fixed runtime path, never overwrite chezmoi-managed shortcut sources.
  local data = "[" .. table.concat(rows, ",") .. "]\n"
  sbar.exec('set -e\nmkdir -p "$HOME/.cache/sketchybar"\ncat > "$HOME/.cache/sketchybar/keybindings.json.tmp" <<\'SHORTCUTS\'\n'
    .. data .. 'SHORTCUTS\nmv "$HOME/.cache/sketchybar/keybindings.json.tmp" "$HOME/.cache/sketchybar/keybindings.json"')
end

return shortcuts
