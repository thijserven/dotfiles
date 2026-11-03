-- Tap Caps Lock for Escape; hold for Hyper. Defer Firefox until release.
local capsLock = require("caps_lock")
local sketchybar = require("sketchybar")
local hyper = {}

local types = hs.eventtap.event.types
local keys = hs.keycodes.map
local modifiers = { cmd = true, alt = true, ctrl = true, shift = true }

local held, used = false, false
local pressed = {}
local firefoxPressed = false

local function queueFirefox()
  if hyper.firefoxTimer then
    return
  end

  -- Option held at startup makes Firefox enter Troubleshoot Mode.
  hyper.firefoxTimer = hs.timer.doEvery(0.02, function()
    local flags = hs.eventtap.checkKeyboardModifiers()
    if held or firefoxPressed or flags.cmd or flags.alt or flags.ctrl or flags.shift then
      return
    end

    hyper.firefoxTimer:stop()
    hyper.firefoxTimer = nil
    if not hs.application.launchOrFocusByBundleID("org.mozilla.firefox") then
      hs.printf("Firefox launch failed")
    end
  end)
end

local function showHints(show)
  sketchybar.trigger("hyper_hints", "STATE=" .. (show and "on" or "off"), "Hyper hints failed")
end

local function handleHyperKey(isKeyDown)
  if isKeyDown then
    if not held then
      held, used = true, false
      showHints(true)
    end
  else
    local sendEscape = held and not used
    held, used = false, false
    showHints(false)

    local popup_keys = package.loaded.sketchybar_audio_keys
    if sendEscape and not (type(popup_keys) == "table" and popup_keys.visibility and popup_keys.visibility["popup-open"]) then
      -- Mark tap-generated Escape so popup handling leaves Hyper taps alone.
      for _, down in ipairs({ true, false }) do
        hs.eventtap.event.newKeyEvent({}, "escape", down)
          :setProperty(hs.eventtap.event.properties.eventSourceUserData, 0x48595045)
          :post()
      end
    end
  end
end

local function handleKey(event)
  local key = event:getKeyCode()
  local isKeyDown = event:getType() == types.keyDown

  if key == keys.f18 then
    handleHyperKey(isKeyDown)
    return true
  end

  if key == keys.b and (held or firefoxPressed) then
    used = true
    firefoxPressed = isKeyDown
    if isKeyDown then
      queueFirefox()
    end
    return true
  end

  -- Keep matching flags on key-up even if Caps Lock was released first.
  if held or pressed[key] then
    used = true
    pressed[key] = isKeyDown or nil
    event:setFlags(modifiers)
  end

  return false
end

local function handleWake(event)
  if event == hs.caffeinate.watcher.systemDidWake then
    held, used = false, false
    pressed = {}
    firefoxPressed = false
    if hyper.firefoxTimer then
      hyper.firefoxTimer:stop()
      hyper.firefoxTimer = nil
    end
    showHints(false)
    capsLock.remap()
  end
end

local function handleUSB(event)
  if event.eventType == "added" then
    capsLock.remap()
  end
end

-- Keep taps, timers and watchers alive through the returned module.
hyper.tap = hs.eventtap.new({ types.keyDown, types.keyUp }, handleKey):start()
hyper.wake = hs.caffeinate.watcher.new(handleWake):start()
hyper.usb = hs.usb.watcher.new(handleUSB):start()

capsLock.remap()

return hyper
