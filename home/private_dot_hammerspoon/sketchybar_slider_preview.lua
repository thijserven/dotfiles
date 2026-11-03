local preview = {}
local binary = hs.execute("PATH=/opt/homebrew/bin:/usr/local/bin:$PATH command -v sketchybar"):match("^%s*(/[^%s]+)")
local task
local last_percentage

function preview.update(visibility)
  if not visibility["audio-popup"] or not hs.eventtap.checkMouseButtons().left then
    last_percentage = nil
    return
  end
  if task or not binary then
    return
  end

  task = hs.task.new(binary, function(code, output)
    if code ~= 0 then
      task = nil
      return
    end

    local ok, item = pcall(hs.json.decode, output)
    local value = ok and type(item) == "table" and type(item.slider) == "table"
      and tonumber(item.slider.percentage)
    if not value or value ~= value or value < 0 or value > 100
      or value == last_percentage or not visibility["audio-popup"]
      or not hs.eventtap.checkMouseButtons().left then
      task = nil
      return
    end

    last_percentage = value
    task = hs.task.new(binary, function() task = nil end, {
      "--set", "volume.slider", "label=" .. math.floor(value) .. "%",
    })
    if task then
      task:start()
    end
  end, { "--query", "volume.slider" })
  if task then
    task:start()
  end
end

return preview
