-- Pure formatting and counter math; sampling stays in network.sh.
local network = {}

function network.value(value)
  return (value == nil or value == "") and "—" or tostring(value)
end

function network.bytes(value, suffix)
  if type(value) ~= "number" then return "—" end

  local units = { "B", "KB", "MB", "GB", "TB" }
  local unit = 1
  while value >= 1000 and unit < #units do
    value = value / 1000
    unit = unit + 1
  end

  return string.format("%.1f %s%s", value, units[unit], suffix or "")
end

function network.speed(bandwidth)
  return string.format("%.2f Mbit/s", bandwidth * 8 / 1e6)
end

function network.rate(current, previous, counter)
  if not previous or previous.interface ~= current.interface
    or type(current.time) ~= "number" or type(previous.time) ~= "number"
    or current.time <= previous.time or type(current[counter]) ~= "number"
    or type(previous[counter]) ~= "number" or current[counter] < previous[counter] then
    return "—"
  end

  return network.bytes((current[counter] - previous[counter]) / (current.time - previous.time), "/s")
end

function network.icon(data)
  if data.kind == "Ethernet" then return utf8.char(0xf0200) end
  if data.kind == "Other" then return utf8.char(0xf06f3) end
  if data.kind ~= "Wi-Fi" then return utf8.char(0xf092e) end

  local rssi = tonumber(data.wifi.rssi) or -100
  return utf8.char(rssi >= -55 and 0xf0928 or rssi >= -67 and 0xf0925 or rssi >= -75 and 0xf0922 or 0xf091f)
end

return network
