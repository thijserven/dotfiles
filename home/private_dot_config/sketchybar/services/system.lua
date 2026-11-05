local system = {}
local previous_io

system.command = [[
export LC_ALL=C
/usr/bin/top -l 2 -s 1 -n 0 | /usr/bin/grep 'CPU usage'
/usr/bin/vm_stat
/usr/sbin/sysctl hw.memsize
/bin/df -k /System/Volumes/Data
/usr/sbin/ioreg -r -c IOBlockStorageDriver -l
if command -v macmon >/dev/null 2>&1; then
  macmon pipe -s 1 2>/dev/null
fi
/bin/ps -axo %cpu=,rss=,comm=
]]

local function parse_disk(text)
  local disk_total, disk_available = text:match("\n/dev/%S+%s+(%d+)%s+%d+%s+(%d+)[^\n]-/System/Volumes/Data")
  disk_total, disk_available = tonumber(disk_total), tonumber(disk_available)
  if disk_total and disk_total > 0 and disk_available and disk_available <= disk_total then
    -- APFS free space is shared; include space occupied by other container volumes.
    return { total = disk_total * 1024, used = (disk_total - disk_available) * 1024 }
  end
end

local function parse_consumers(text)
  local apps = {}
  for line in text:gmatch("[^\n]+") do
    local usage, rss, command = line:match("^%s*([%d.]+)%s+(%d+)%s+(.+)$")
    local name = command and command:match("/([^/]+)%.app/")
    if name and tonumber(usage) then
      local app = apps[name] or { name = name, cpu = 0, memory = 0 }
      app.cpu = app.cpu + tonumber(usage)
      app.memory = app.memory + tonumber(rss) * 1024
      apps[name] = app
    end
  end
  local consumers = {}
  for _, app in pairs(apps) do consumers[#consumers + 1] = app end
  table.sort(consumers, function(a, b)
    if a.cpu ~= b.cpu then return a.cpu > b.cpu end
    if a.memory ~= b.memory then return a.memory > b.memory end
    return a.name < b.name
  end)

  return { consumers[1], consumers[2], consumers[3] }
end

local function parse_activity(text)
  local sample = { read = 0, write = 0, devices = {}, time = os.time() }
  for id in text:gmatch("<class IOBlockStorageDriver, id (0x%x+),") do
    sample.devices[#sample.devices + 1] = id
  end
  table.sort(sample.devices)
  sample.devices = table.concat(sample.devices, ",")
  local count = 0
  for stats in text:gmatch('"Statistics"%s*=%s*({[^\n]+})') do
    local read = tonumber(stats:match('"Bytes %(Read%)"=(%d+)'))
    local write = tonumber(stats:match('"Bytes %(Write%)"=(%d+)'))
    if read and write then
      sample.read = sample.read + read
      sample.write = sample.write + write
      count = count + 1
    end
  end
  local activity
  if count > 0 and sample.devices ~= "" then
    if previous_io and previous_io.devices == sample.devices and sample.time > previous_io.time
      and sample.read >= previous_io.read and sample.write >= previous_io.write then
      local elapsed = sample.time - previous_io.time
      activity = {
        read = (sample.read - previous_io.read) / elapsed / 2^20,
        write = (sample.write - previous_io.write) / elapsed / 2^20,
      }
    end
    previous_io = sample
  else
    previous_io = nil
  end

  return activity
end

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

  local active = pages("Pages active")
  local wired = pages("Pages wired down")
  local compressed = pages("Pages occupied by compressor")
  if not cpu or not page_size or not total or total <= 0 or not active or not wired or not compressed then
    return nil
  end

  local temperature = tonumber(text:match('"cpu_temp_avg"%s*:%s*([%d.]+)'))

  return {
    cpu = math.max(0, math.min(100, cpu)),
    temperature = temperature and temperature > 0 and temperature < 150 and temperature or nil,
    total = total,
    used = (active + wired + compressed) * page_size,
    disk = parse_disk(text),
    activity = parse_activity(text),
    consumers = parse_consumers(text),
  }
end

return system
