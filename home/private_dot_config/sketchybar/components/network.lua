local format = require("services.network")
local shell = require("services.shell")

return function(sbar, theme)
  local network = require("ui.status_icon")(sbar, "network", {
    update_freq = 3,
    icon = { string = utf8.char(0xf092e) },
  })
  local popup = require("ui.popup")(sbar, theme, network, "network")
  popup.defer_open = true

  local function row(name, left, right, height)
    local item = popup.columns(name, left, right, 150, 150, height or 24)
    item:set({ label = { max_chars = 28 } })
    return item
  end

  popup.spacer("top", popup.top_padding)
  local speedtest
  local heading = popup.header("heading", "Network", 300, {
    icon = utf8.char(0xf04c5),
    width = 40,
    on_click = function() speedtest.toggle() end,
  })
  heading:set({ label = { font = "Hack Nerd Font:Regular:22.0" } })
  popup.spacer("header", 9)
  popup.hints({
    "P → Copy public IP address",
    "G → Copy gateway IP address",
    "L → Copy local IP address",
    "T → Test internet speed",
  })
  popup.separator(300)
  local service = row("service", "Reading network…")

  local function stat(name, title)
    local item = row(name, title, "—")
    item:set({ icon = { color = theme.muted }, label = { color = theme.text } })
    return item
  end

  local latency = stat("latency", "Ping")
  local loss_row = stat("loss", "Packet loss")
  local traffic = stat("traffic", "Receiving")
  local sending = stat("sending", "Sending")
  local totals = stat("totals", "Downloaded")
  local uploaded = stat("uploaded", "Uploaded")
  local copy_icon = utf8.char(0xf0c5)
  local public_address = stat("public_address", "Public IP")
  local gateway = stat("gateway", "Gateway")
  local address = stat("address", "Local IP")

  local function ip_value(ip)
    return ip and (ip .. " " .. copy_icon) or "—"
  end
  local ip_address, public_ip, gateway_ip
  local public_busy = false

  local function copy_ip(item, ip)
    if not ip then return end
    sbar.exec("printf '%s' " .. shell.quote(ip) .. " | /usr/bin/pbcopy")
    item:set({ label = { color = theme.primary } })
    sbar.animate("linear", 60, function()
      item:set({ label = { color = theme.text } })
    end)
  end

  address:subscribe("mouse.clicked", function() copy_ip(address, ip_address) end)
  public_address:subscribe("mouse.clicked", function() copy_ip(public_address, public_ip) end)

  local function refresh_public_ip()
    if public_busy then return end
    public_busy = true
    -- Only opening the popup contacts ipify; routine local sampling stays offline.
    sbar.exec("/usr/bin/curl --fail --silent --max-time 5 https://api.ipify.org", function(result, code)
      public_busy = false
      public_ip = code == 0 and type(result) == "string" and result:match("^%d+%.%d+%.%d+%.%d+$") or nil
      public_address:set({ label = { string = ip_value(public_ip) } })
    end)
  end
  gateway:subscribe("mouse.clicked", function() copy_ip(gateway, gateway_ip) end)
  local test = stat("test", "Download speed")
  local test_upload = stat("test_upload", "Upload speed")
  popup.spacer("bottom")

  local function pair(item, left, right)
    item:set({ icon = { string = left }, label = { string = right or "" } })
  end

  local busy, previous = false, nil

  local function show_network(data)
    local icon = format.icon(data)
    network:set({ icon = { string = icon } })
    heading:set({ icon = { string = popup.title(icon, format.value(data.kind)) } })

    local name = data.name
    if data.kind == "Wi-Fi" then
      local ssid = data.wifi.ssid
      name = type(ssid) == "string" and ssid ~= "" and ssid or "SSID hidden by macOS"
    end

    pair(service, format.value(name), format.value(data.interface))
    pair(traffic, "Receiving", format.rate(data, previous, "rx"))
    pair(sending, "Sending", format.rate(data, previous, "tx"))
    pair(totals, "Downloaded", format.bytes(data.rx))
    pair(uploaded, "Uploaded", format.bytes(data.tx))
    local ip = data.ipv4
    if type(ip) ~= "string" or ip == "" then ip = data.ipv6 end
    ip_address = type(ip) == "string" and ip ~= "" and ip or nil
    address:set({ label = { string = ip_value(ip_address) } })
    gateway_ip = type(data.router) == "string" and data.router ~= "" and data.router or nil
    gateway:set({ label = { string = ip_value(gateway_ip) } })
    previous = data
  end

  local command = 'sh "$HOME/.config/sketchybar/services/network.sh"'

  local function receive_network(data, code)
    busy = false
    if code ~= 0 or type(data) ~= "table" or type(data.wifi) ~= "table" then
      previous = nil
      ip_address = nil
      gateway_ip = nil
      network:set({ icon = { string = utf8.char(0xf092e) } })
      heading:set({ icon = { string = "Network unavailable" } })
      pair(service, "Could not read network state")
      for _, item in ipairs({ traffic, sending, totals, uploaded, address, gateway }) do
        item:set({ label = { string = "—" } })
      end
      popup.ready()
      return
    end

    show_network(data)
    popup.ready()
  end

  local function refresh()
    if busy then return end
    busy = true

    sbar.exec(command, receive_network)
  end

  local function show_test(state, result)
    heading:set({ label = { color = state == "running" and theme.primary or theme.text } })
    if state == "running" then
      test:set({ label = { string = "Running…" } })
      test_upload:set({ label = { string = "Running…" } })
      pair(latency, "Ping", "—")
      pair(loss_row, "Packet loss", "—")
    elseif state == "complete" then
      test:set({ label = { string = format.speed(result.download.bandwidth) } })
      test_upload:set({ label = { string = format.speed(result.upload.bandwidth) } })
      local ping = type(result.ping) == "table" and tonumber(result.ping.latency)
      local loss = tonumber(result.packetLoss)
      pair(latency, "Ping", ping and string.format("%.1f ms", ping) or "—")
      pair(loss_row, "Packet loss", loss and string.format("%.1f%%", loss) or "—")
    elseif state == "cancelled" then
      test:set({ label = { string = "Cancelled" } })
      test_upload:set({ label = { string = "Cancelled" } })
    else
      local messages = {
        start_failed = "Could not start", failed = "Failed; try Terminal",
      }
      test:set({ label = { string = messages[state] or "Failed" } })
      test_upload:set({ label = { string = "—" } })
    end
  end

  speedtest = require("services.speedtest")(sbar, show_test)
  sbar.add("event", "network_test_toggle")
  network:subscribe("network_test_toggle", function()
    if popup.opened then speedtest.toggle() end
  end)

  local function copy_shortcut(event, item, current_ip)
    sbar.add("event", event)
    network:subscribe(event, function()
      if popup.opened then copy_ip(item, current_ip()) end
    end)
  end

  -- Resolve addresses when pressed, not when registering shortcuts.
  copy_shortcut("network_copy_local_ip", address, function() return ip_address end)
  copy_shortcut("network_copy_public_ip", public_address, function() return public_ip end)
  copy_shortcut("network_copy_gateway_ip", gateway, function() return gateway_ip end)

  popup.keyboard_state("network-popup")
  network:subscribe({ "routine", "forced", "system_woke", "wifi_change" }, refresh)
  popup.on_open = function()
    refresh()
    public_ip = nil
    public_address:set({ label = { string = "Reading…" } })
    refresh_public_ip()
  end
end
