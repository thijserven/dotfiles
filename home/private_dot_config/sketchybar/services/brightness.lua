-- Shared read-only parsers; both SketchyBar and Hammerspoon use the same CLI contract.
local brightness = {}
brightness.path = "PATH=/opt/homebrew/bin:/usr/local/bin:$PATH "
brightness.hardware_command = "/usr/sbin/ioreg -r -c IOResources -d 1 -l"
brightness.hardware_arguments = { "-r", "-c", "IOResources", "-d", "1", "-l" }

local function level(value)
  value = tonumber(value)
  if value and value == value and value >= 0 and value <= 1 then
    return math.floor(value * 100 + 0.5)
  end
end

function brightness.display(output)
  if type(output) ~= "string" then return end
  local displays, levels, indices = {}, {}, {}
  for line in output:gmatch("[^\r\n]+") do
    local index, flags, id = line:match("^display (%d+): (.-), ID (0x%x+)$")
    if index then
      local number = tonumber(id)
      indices[tonumber(index)] = id
      if flags:match("%f[%a]built%-in%f[%A]") and flags:match("%f[%a]online%f[%A]")
        and number and number > 0 and number <= 0xffffffff then
        displays[#displays + 1] = { index = index, id = id }
      end
    else
      local display, value = line:match("^display (%d+): brightness (%d+%.%d+)$")
      if display then levels[display] = level(value) end
    end
  end
  -- CLI -d matches both IDs and indices; reject IDs that also select another display.
  if #displays == 1 and levels[displays[1].index] ~= nil then
    local display = displays[1]
    local collision = indices[tonumber(display.id)]
    if not collision or collision == display.id then
      return levels[display.index], display.id
    end
  end
end

function brightness.keyboard_hardware(output)
  return type(output) == "string" and output:match('\n%s*"KeyboardBacklight" = Yes%s*\n') ~= nil
end

function brightness.keyboard(output)
  if type(output) ~= "string" then return end
  return level(output:match("^Current brightness: (%d+%.%d+)%s*$"))
end

return brightness
