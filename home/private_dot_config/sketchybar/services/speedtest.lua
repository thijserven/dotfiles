-- Own process state, not UI. Cancellation keeps run locked until process exits.
local shell = require("services.shell")

return function(sbar, notify)
  local running, cancelled, directory = false, false, nil
  local helper = 'sh "$HOME/.config/sketchybar/services/network_speedtest.sh" '
  local speedtest = {}
  local progress_busy = false
  local progress = sbar.add("item", "network_speedtest_progress", {
    drawing = false,
    updates = "on",
    update_freq = 1,
  })

  progress:subscribe("routine", function()
    if not running or cancelled or not directory or progress_busy then
      return
    end

    local current = directory
    progress_busy = true
    sbar.exec(helper .. "progress " .. shell.quote(current), function(result, code)
      progress_busy = false
      -- Ignore reads that finish after cancellation, completion, or a new run.
      if not running or cancelled or directory ~= current or code ~= 0
        or type(result) ~= "table" then
        return
      end

      local phase = result.type
      if (phase == "download" or phase == "upload") and type(result[phase]) == "table"
        and type(result[phase].bandwidth) == "number" then
        notify("progress", result)
      end
    end)
  end)

  local function cancel_process()
    if directory then
      sbar.exec(helper .. "cancel " .. shell.quote(directory))
    end
  end

  local function finish(result, code)
    running, directory = false, nil
    if cancelled then
      return
    end

    if code ~= 0 or type(result) ~= "table" or type(result.download) ~= "table"
      or type(result.upload) ~= "table" or type(result.download.bandwidth) ~= "number"
      or type(result.upload.bandwidth) ~= "number" then
      notify("failed")
      return
    end
    notify("complete", result)
  end

  local function start_process(result, code)
    if code ~= 0 or type(result) ~= "string" or not result:match("^/[%w/_.%-]+%s*$") then
      running = false
      if not cancelled then
        notify("start_failed")
      end
      return
    end

    directory = result:gsub("%s+$", "")
    -- Click may arrive before mktemp callback. Helper records early cancellation.
    if cancelled then
      cancel_process()
    end
    sbar.exec(helper .. "run " .. shell.quote(directory), finish)
  end

  function speedtest.start()
    if running then
      return
    end
    running, cancelled = true, false
    notify("running")
    sbar.exec("mktemp -d -t sketchybar-speedtest", start_process)
  end

  function speedtest.cancel()
    if not running or cancelled then
      return
    end
    cancelled = true
    notify("cancelled")
    cancel_process()
  end

  function speedtest.toggle()
    if running then
      speedtest.cancel()
    else
      speedtest.start()
    end
  end

  return speedtest
end
