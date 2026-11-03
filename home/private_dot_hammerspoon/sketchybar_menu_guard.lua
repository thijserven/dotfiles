-- Keep cursor out of native menu-bar auto-reveal zone. Hold Option to bypass.
local guard = {}

local REVEAL_ZONE_HEIGHT = 4
local frames = {}

local function refreshScreens()
  frames = {}

  for _, screen in ipairs(hs.screen.allScreens()) do
    frames[#frames + 1] = screen:fullFrame()
  end
end

local function handleMouseMoved(event)
  if event:getFlags().alt then
    return false
  end

  local point = event:location()

  for _, frame in ipairs(frames) do
    local insideWidth = point.x >= frame.x and point.x < frame.x + frame.w
    local insideRevealZone = point.y >= frame.y and point.y < frame.y + REVEAL_ZONE_HEIGHT

    if insideWidth and insideRevealZone then
      -- Modify delivered event only: cursor warps cause horizontal edge stutter.
      point.y = frame.y + REVEAL_ZONE_HEIGHT
      event:location(point)
      break
    end
  end

  return false
end

-- Keep tap and watcher alive through the returned module.
refreshScreens()
guard.screens = hs.screen.watcher.new(refreshScreens):start()
guard.tap = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, handleMouseMoved):start()

return guard
