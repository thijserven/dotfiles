local brightness = {}
local cli = dofile(os.getenv("HOME") .. "/.config/sketchybar/services/brightness.lua")
local function executable(name)
  return hs.execute(cli.path .. "command -v " .. name):match("^%s*(/[^%s]+)")
end
local display_binary, keyboard_binary = executable("brightness"), executable("mac-brightnessctl")
local display_id, keyboard_hardware
local binary = hs.execute("PATH=/opt/homebrew/bin:/usr/local/bin:$PATH command -v sketchybar"):match("^%s*(/[^%s]+)")
local values, pending, deltas, desired = {}, {}, {}, {}
local error_state = false
local task, event_task, event_pending
local held, repeat_timer, repeat_after = {}, nil, 0
local dragging, finishing = false, false
local input, awaiting_commit = "refresh", false
local enabled, keyboard_enabled = false, false
local generation, selected, down = 0, nil, nil
local last_commit = 0
local query_task, commit_timer
local refresh_needed = false

local function percentage(value)
  value = tonumber(value)
  if value and value == value and value >= 0 and value <= 100 then
    return math.floor(value + 0.5)
  end
end

local function send_event()
  if event_task or not event_pending or not binary then return end
  local arguments = event_pending
  event_pending = nil
  event_task = hs.task.new(binary, function()
    event_task = nil
    send_event()
  end, arguments)
  if event_task and not event_task:start() then event_task = nil end
end

local function publish(failed, levels)
  local arguments = {
    "--trigger", "brightness_state",
    "DRAGGING=" .. tostring(dragging),
    "POINTER=" .. tostring(input == "pointer"),
    "INPUT=" .. input,
    "COMMIT=" .. string.format("%.0f", last_commit),
  }
  for _, target in ipairs({ "display", "keyboard" }) do
    if levels ~= false and values[target] ~= nil then
      arguments[#arguments + 1] = target:upper() .. "=" .. values[target]
    end
  end
  if failed ~= nil then error_state = failed end
  arguments[#arguments + 1] = "ERROR=" .. tostring(error_state)
  event_pending = arguments
  send_event()
end

local function settle()
  if finishing and not down and not awaiting_commit and not task and not next(pending) and not next(deltas) then
    finishing, dragging = false, false
    publish()
  end
end

local drain
local function run(command, arguments, callback)
  task = command and hs.task.new(command, function(code, output, stderr)
    task = nil
    callback(code, output, stderr)
    drain()
  end, arguments)
  if not task or not task:start() then
    task = nil
    callback(-1, "", "Could not start brightness command")
    drain()
  end
end

local function fail(stderr)
  hs.printf("Brightness control failed: %s", stderr or "unknown error")
  publish(true)
end

local function clear_display()
  pending.display, desired.display, deltas.display = nil, nil, nil
  for index = #held, 1, -1 do
    if held[index].target == "display" then table.remove(held, index) end
  end
  if #held == 0 and repeat_timer then
    repeat_timer:stop()
    repeat_timer = nil
  end
  if selected == "display" then
    generation = generation + 1
    selected, down = nil, nil
    awaiting_commit = false
    finishing = true
  end
  settle()
end

local function read_levels(callback)
  run(display_binary, { "-l" }, function(code, output)
    values.display, display_id = nil, nil
    if code == 0 then values.display, display_id = cli.display(output) end
    run("/usr/sbin/ioreg", cli.hardware_arguments, function(hardware_code, hardware)
      keyboard_hardware = hardware_code == 0 and cli.keyboard_hardware(hardware)
      values.keyboard = nil
      if not keyboard_hardware then callback() return end
      run(keyboard_binary, {}, function(keyboard_code, result)
        if keyboard_code == 0 then values.keyboard = cli.keyboard(result) end
        callback()
      end)
    end)
  end)
end

drain = function()
  if task then return end
  if refresh_needed or next(deltas) then
    refresh_needed = false
    read_levels(function()
      if not dragging and not awaiting_commit then input = "refresh" end
      for target, delta in pairs(deltas) do
        local value = values[target]
        if value and (target ~= "display" or enabled) then
          if pending[target] == nil and desired[target] == nil then
            pending[target] = math.max(0, math.min(100, value + delta))
            desired[target] = pending[target]
          end
        end
      end
      deltas = {}
      publish(values.display == nil)
    end)
    return
  end
  if not enabled then clear_display() end
  for _, target in ipairs({ "display", "keyboard" }) do
    if pending[target] ~= nil then
      local value = pending[target]
      pending[target] = nil
      local command = target == "display" and display_binary or keyboard_binary
      local arguments = { string.format("%.2f", value / 100) }
      if target == "display" then
        if not display_id then
          desired[target] = nil
          fail("Built-in display unavailable")
          drain()
          return
        end
        arguments = { "-d", display_id, arguments[1] }
      elseif not keyboard_hardware or values.keyboard == nil then
        desired[target] = nil
        fail("Built-in keyboard backlight unavailable")
        drain()
        return
      end
      run(command, arguments, function(code, output, stderr)
        if target == "keyboard" and not output:match("^Brightness set to: %d+%.%d+%s*$") then code = -1 end
        if desired[target] == value then desired[target] = nil end
        if code == 0 then
          values[target] = value
          publish(false)
        else
          values[target] = nil
          fail(stderr)
        end
      end)
      return
    end
  end

  settle()
end

function brightness.set(target, value, source)
  value = percentage(value)
  if (target ~= "display" and target ~= "keyboard") or not value then return false end
  if target == "display" and not enabled then return false end
  deltas[target] = nil
  if source and (source == "pointer" or not dragging) then input = source end
  if not dragging then
    dragging, finishing = true, true
    publish(nil, false)
  end
  pending[target], desired[target] = value, value
  drain()
  return true
end

local function finish_drag()
  local was_selected = selected ~= nil
  generation = generation + 1
  selected, down = nil, nil
  if was_selected then
    awaiting_commit = true
    if commit_timer then commit_timer:stop() end
    -- Releases outside the slider may never deliver a component click command.
    commit_timer = hs.timer.doAfter(1, function()
      commit_timer = nil
      awaiting_commit = false
      settle()
    end)
  end
  if dragging then
    finishing = true
    settle()
  end
end

function brightness.commit(target, value, sequence)
  sequence = tonumber(sequence)
  if not sequence or sequence ~= sequence or sequence > 9007199254740991
    or sequence <= last_commit or sequence % 1 ~= 0 then return false end
  value = percentage(value)
  if (target ~= "display" and target ~= "keyboard") or not value then return false end
  if target == "display" and not enabled then return false end
  -- A delayed release must not cancel a newer pointer gesture.
  if down and hs.eventtap.checkMouseButtons().left then return false end
  last_commit = sequence
  -- A release command supersedes all in-flight slider queries, never CLI writes.
  generation = generation + 1
  selected, down = nil, nil
  if commit_timer then
    commit_timer:stop()
    commit_timer = nil
  end
  awaiting_commit = false
  input = "pointer"
  dragging, finishing = true, true
  publish(nil, false)
  return brightness.set(target, value, "pointer")
end

local function adjust(target, delta)
  if target == "display" and not enabled then return end
  local value
  if not refresh_needed then value = desired[target] or pending[target] or values[target] end
  if value then
    brightness.set(target, math.max(0, math.min(100, value + delta)), "keyboard")
  else
    if input ~= "pointer" or not dragging then input = "keyboard" end
    if not dragging then
      dragging, finishing = true, true
      publish(nil, false)
    end
    deltas[target] = math.max(-100, math.min(100, (deltas[target] or 0) + delta))
    drain()
  end
end

local function remove_held(id)
  for index = #held, 1, -1 do
    if held[index].id == id then table.remove(held, index) end
  end
end

function brightness.press(id, target, delta)
  if target ~= "display" and target ~= "keyboard" then return false end
  if target == "display" and not enabled then return false end
  if #held == 0 then
    values = {}
    refresh_needed = true
  end
  remove_held(id)
  held[#held + 1] = { id = id, target = target, delta = delta }
  adjust(target, delta)
  repeat_after = hs.timer.absoluteTime() / 1e9 + 0.3
  if not repeat_timer then
    repeat_timer = hs.timer.doEvery(0.075, function()
      local latest = held[#held]
      if latest and hs.timer.absoluteTime() / 1e9 >= repeat_after then
        adjust(latest.target, latest.delta)
      end
    end)
  end
end

function brightness.release(id)
  remove_held(id)
  if #held == 0 and repeat_timer then
    repeat_timer:stop()
    repeat_timer = nil
  end
end

function brightness.stop_repeat()
  held = {}
  if repeat_timer then
    repeat_timer:stop()
    repeat_timer = nil
  end
end

local function contains(item, point)
  for _, frame in pairs(item.bounding_rects or {}) do
    if type(frame) == "table" and type(frame.origin) == "table" and type(frame.size) == "table" then
      local x, y = tonumber(frame.origin[1]), tonumber(frame.origin[2])
      local width, height = tonumber(frame.size[1]), tonumber(frame.size[2])
      if x and y and width and height and point.x >= x and point.x <= x + width
        and point.y >= y and point.y <= y + height then return true end
    end
  end
  return false
end

local function sample(target, token, selecting)
  if target == "display" and not enabled then
    if selecting and keyboard_enabled then sample("keyboard", token, true) end
    return
  end
  if query_task or not binary then return end
  query_task = hs.task.new(binary, function(code, output)
    query_task = nil
    if code ~= 0 or token ~= generation or not down or not enabled
      or not hs.eventtap.checkMouseButtons().left then return end
    if target == "display" and not enabled then return end
    if target == "keyboard" and not keyboard_enabled then return end
    local ok, item = pcall(hs.json.decode, output)
    if not ok or type(item) ~= "table" then return end
    if selecting then
      if not contains(item, down) then
        if target == "display" and keyboard_enabled then sample("keyboard", token, true) end
        return
      end
      selected, dragging, finishing = target, true, false
      input = "pointer"
      publish(nil, false)
    end
    if selected ~= target then return end
    local value = type(item.slider) == "table" and percentage(item.slider.percentage)
    if value and value ~= (desired[target] or pending[target] or values[target]) then brightness.set(target, value, "pointer") end
  end, { "--query", "brightness." .. target .. ".slider" })
  if query_task and not query_task:start() then query_task = nil end
end

brightness.mouse = hs.eventtap.new({ hs.eventtap.event.types.leftMouseDown, hs.eventtap.event.types.leftMouseUp }, function(event)
  if event:getType() == hs.eventtap.event.types.leftMouseUp then
    finish_drag()
  elseif enabled then
    generation = generation + 1
    if commit_timer then
      commit_timer:stop()
      commit_timer = nil
    end
    awaiting_commit = false
    event_pending = nil
    down, selected = event:location(), nil
    sample("display", generation, true)
  end
  return false
end):start()

function brightness.update(visibility, bar_alive)
  local was_enabled = enabled
  enabled = bar_alive and visibility["brightness-popup"] == true
  if enabled and not was_enabled then
    refresh_needed = true
    drain()
  end
  keyboard_enabled = enabled and visibility["brightness-keyboard-popup"] == true
  if not enabled then clear_display() end
  if not enabled then
    brightness.stop_repeat()
    if down or dragging and not finishing then finish_drag() end
    return
  end
  if not keyboard_enabled then
    for index = #held, 1, -1 do
      if held[index].target == "keyboard" then brightness.release(held[index].id) end
    end
  end
  if selected == "keyboard" and not keyboard_enabled then finish_drag() end
  if down and hs.eventtap.checkMouseButtons().left then
    sample(selected or "display", generation, not selected)
  elseif down then
    finish_drag()
  end
end

return brightness
