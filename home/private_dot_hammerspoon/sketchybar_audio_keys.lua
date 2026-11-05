local audio = require("audio_controls")
local brightness = require("brightness_controls")
local sketchybar = require("sketchybar")
local slider_preview = require("sketchybar_slider_preview")
local controls = { bindings = {}, visibility = {} }
local bar_alive = true

local function trigger(event)
  sketchybar.trigger(event, nil, "Popup control failed")
end

local function bind(modifiers, key, source, pressed, released)
  local hotkey = hs.hotkey.new(modifiers, key, pressed, released)
  controls.bindings[#controls.bindings + 1] = { hotkey = hotkey, source = source }
end

local function bind_volume(modifiers, key, delta)
  local id = table.concat(modifiers, "+") .. key
  bind(modifiers, key, "audio-popup", function()
    audio.press(id, delta)
  end, function()
    audio.release(id)
  end)
end

bind_volume({}, "-", -5)
bind_volume({}, "=", 5)
bind_volume({ "shift" }, "=", 5)

local function bind_brightness(modifiers, key, target, delta)
  local id = target .. table.concat(modifiers, "+") .. key
  local source = target == "keyboard" and "brightness-keyboard-popup" or "brightness-popup"
  bind(modifiers, key, source, function()
    brightness.press(id, target, delta)
  end, function()
    brightness.release(id)
  end)
end

bind_brightness({}, "-", "display", -5)
bind_brightness({}, "=", "display", 5)
bind_brightness({ "shift" }, "=", "display", 5)
bind_brightness({}, "[", "keyboard", -5)
bind_brightness({}, "]", "keyboard", 5)
bind({}, "m", "audio-popup", function() audio.adjust("mute") end)
for index = 1, 9 do
  bind({}, tostring(index), "audio-popup", function()
    sketchybar.trigger("audio_select_output", "INDEX=" .. index, "Output selection failed")
  end)
end
bind({}, "t", "network-popup", function() trigger("network_test_toggle") end)
bind({}, "l", "network-popup", function() trigger("network_copy_local_ip") end)
bind({}, "p", "network-popup", function() trigger("network_copy_public_ip") end)
bind({}, "g", "network-popup", function() trigger("network_copy_gateway_ip") end)
bind({}, "escape", "popup-open", function() trigger("popup_close_all") end)

-- Read atomically published state outside keyboard callbacks. A delayed heartbeat
-- must not disable working hotkeys while the popup remains open.
local function update_visibility()
  for _, name in ipairs({ "popup-open", "audio-popup", "network-popup", "brightness-popup", "brightness-keyboard-popup" }) do
    local file = io.open(os.getenv("HOME") .. "/.cache/sketchybar/" .. name, "r")
    if file then
      local state = file:read("*a")
      file:close()
      if state == "closed" then
        controls.visibility[name] = false
      elseif tonumber(state) then
        controls.visibility[name] = true
      end
    end
  end

  if not bar_alive or not controls.visibility["audio-popup"] or controls.visibility["brightness-popup"] then
    audio.stop_repeat()
  end

  for _, binding in ipairs(controls.bindings) do
    local enabled = bar_alive and controls.visibility[binding.source] == true
    if binding.source == "audio-popup" and controls.visibility["brightness-popup"] then enabled = false end
    if (binding.source == "brightness-keyboard-popup" or binding.source == "brightness-popup")
      and not controls.visibility["brightness-popup"] then enabled = false end
    if enabled ~= binding.enabled then
      binding.enabled = enabled
      if enabled then
        binding.hotkey:enable()
      else
        binding.hotkey:disable()
      end
    end
  end
end

-- If the bar exits without publishing closed state, release captured keys.
local user_id = hs.execute("id -u"):match("%d+")
local bar_task
local function check_bar()
  if bar_task then
    return
  end

  bar_task = hs.task.new("/usr/bin/pgrep", function(code)
    bar_task = nil
    bar_alive = code == 0
    update_visibility()
  end, { "-x", "-u", assert(user_id), "sketchybar" })
  if bar_task then
    bar_task:start()
  end
end

controls.slider_timer = hs.timer.doEvery(0.025, function()
  slider_preview.update(controls.visibility, bar_alive)
  brightness.update(controls.visibility, bar_alive)
end)
controls.bar_timer = hs.timer.doEvery(2, check_bar)
controls.timer = hs.timer.doEvery(0.1, update_visibility)
update_visibility()
return controls
