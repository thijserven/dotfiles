local system = {}

system.command = [[
/usr/bin/top -l 2 -s 1 -n 0 | /usr/bin/grep 'CPU usage'
/usr/bin/vm_stat
/usr/sbin/sysctl hw.memsize vm.loadavg vm.swapusage
/usr/bin/memory_pressure -Q
]]

function system.parse(text)
  if type(text) ~= "string" then return nil end

  local cpu
  for idle in text:gmatch("CPU usage:[^\n]-([%d.]+)%% idle") do
    cpu = 100 - tonumber(idle)
  end
  local page_size = tonumber(text:match("page size of (%d+) bytes"))
  local total = tonumber(text:match("hw.memsize: (%d+)"))
  local function pages(name)
    return tonumber(text:match(name .. ":%s+(%d+)%."))
  end
  local active, wired, compressed = pages("Pages active"), pages("Pages wired down"), pages("Pages occupied by compressor")
  if not cpu or not page_size or not total or total <= 0 or not active or not wired or not compressed then
    return nil
  end

  return {
    cpu = math.max(0, math.min(100, cpu)),
    total = total,
    used = (active + wired + compressed) * page_size,
    compressed = compressed * page_size,
    load = text:match("vm.loadavg: { ([^}]+) }") or "—",
    swap = text:match("vm.swapusage:[^\n]-used = ([%d.]+[MGT])") or "—",
    available = tonumber(text:match("System%-wide memory free percentage: (%d+)%%")),
  }
end

return system
