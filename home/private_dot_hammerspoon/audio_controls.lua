local sketchybar = require("sketchybar")
local audio = {}
local pending_delta, pending_mute = 0, false
local audio_timer, repeat_timer
local held_volume = {}
local repeat_after = 0

local function publish_mute(muted)
  sketchybar.trigger("audio_mute_state", "MUTED=" .. tostring(muted))
end

local function apply_audio()
  audio_timer = nil
  local delta, mute = pending_delta, pending_mute
  pending_delta, pending_mute = 0, false
  local device = hs.audiodevice.defaultOutputDevice()
  if not device then
    return
  end

  if mute then
    local muted = device:muted()
    if muted ~= nil and device:setMuted(not muted) then
      publish_mute(not muted)
    end
  end

  if delta ~= 0 then
    local level = device:volume()
    if level then
      device:setVolume(math.max(0, math.min(100, level + delta)))
      if device:muted() and device:setMuted(false) then
        publish_mute(false)
      end
    end
  end
end

function audio.adjust(action)
  if action == "mute" then
    pending_mute = not pending_mute
  else
    pending_delta = math.max(-100, math.min(100, pending_delta + action))
  end

  if not audio_timer then
    audio_timer = hs.timer.doAfter(0, apply_audio)
  end
end

local function remove_held(id)
  for i = #held_volume, 1, -1 do
    if held_volume[i].id == id then
      table.remove(held_volume, i)
    end
  end
end

local function repeat_volume()
  local latest = held_volume[#held_volume]
  if latest and hs.timer.absoluteTime() / 1e9 >= repeat_after then
    audio.adjust(latest.delta)
  end
end

function audio.press(id, delta)
  remove_held(id)
  held_volume[#held_volume + 1] = { id = id, delta = delta }
  audio.adjust(delta)
  repeat_after = hs.timer.absoluteTime() / 1e9 + 0.3
  if not repeat_timer then
    repeat_timer = hs.timer.doEvery(0.075, repeat_volume)
  end
end

function audio.release(id)
  remove_held(id)
  if #held_volume == 0 and repeat_timer then
    repeat_timer:stop()
    repeat_timer = nil
  end
end

function audio.stop_repeat()
  held_volume = {}
  if repeat_timer then
    repeat_timer:stop()
    repeat_timer = nil
  end
end

return audio
