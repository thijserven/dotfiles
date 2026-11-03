-- Reconcile workspaces after login, display changes and AeroSpace restarts.
local aerospace = require("services.aerospace")

return function(sbar, theme)
  sbar.add("event", "aerospace_workspace_change")
  sbar.add("event", "aerospace_mode_change")
  sbar.add("event", "aerospace_service_help")
  local service = sbar.add("item", "aerospace.service", {
    position = "left",
    drawing = false,
    label = 'Press "b" for keybindings or "esc" to exit',
  })
  local popup = require("ui.popup")(sbar, theme, service, "aerospace.service")
  popup.defer_open = true
  service:set({ popup = { align = "left" } })
  popup.spacer("top", popup.top_padding)
  popup.header("title", "Service keybindings", 480)
  popup.separator(480)
  local rows = {}
  local bindings_generation = 0

  popup.on_close = function()
    bindings_generation = bindings_generation + 1
  end

  popup.on_open = function()
    bindings_generation = bindings_generation + 1
    local requested = bindings_generation
    for _, name in ipairs(rows) do sbar.remove(name) end
    rows = {}
    local status = popup.columns("status", "", "Loading…", 110, 370)
    rows[1] = "aerospace.service.status"

    sbar.exec("aerospace config --get mode.service.binding --json", function(result, code)
      if requested ~= bindings_generation or not popup.opened then return end
      local function bottom_padding()
        popup.spacer("bottom")
        rows[#rows + 1] = "aerospace.service.padding.bottom"
        popup.ready()
      end

      if code ~= 0 or type(result) ~= "table" then
        status:set({ label = { string = "Could not read service bindings" } })
        bottom_padding()
        return
      end

      local bindings = aerospace.bindings(result)
      if #bindings == 0 then
        status:set({ label = { string = "No service bindings found" } })
        bottom_padding()
        return
      end

      sbar.remove("aerospace.service.status")
      rows = {}
      for index, binding in ipairs(bindings) do
        local name = "binding." .. index
        local row = popup.columns(name, binding.keys, binding.title, 110, 370)
        row:set({ label = { max_chars = 0 } })
        rows[#rows + 1] = "aerospace.service." .. name
      end
      bottom_padding()
    end)
  end

  local service_active = false
  local help_requested = false
  local mode_generation = 0
  local spaces = {}
  local busy = false
  local generation = 0
  local watcher = sbar.add("item", "aerospace.watcher", {
    drawing = false, updates = true, update_freq = 10,
  })

  local function highlight(focused)
    for name, item in pairs(spaces) do
      item:set({ label = { color = name == focused and theme.primary or theme.text } })
    end
  end

  local function add_workspace(name)
    local item = sbar.add("item", "space." .. name, {
      position = "left", label = name, drawing = not service_active,
    })
    item:subscribe("mouse.clicked", function()
      sbar.exec("aerospace workspace " .. aerospace.quote(name))
    end)
    spaces[name] = item
  end

  local function reconcile(result)
    local names, seen = aerospace.workspaces(result)

    for name in pairs(spaces) do
      if not seen[name] then
        sbar.remove("space." .. name)
        spaces[name] = nil
      end
    end

    local moves = { "sketchybar" }
    for _, name in ipairs(names) do
      if not spaces[name] then add_workspace(name) end
      moves[#moves + 1] = "--move " .. aerospace.quote("space." .. name) .. " before front_app"
    end

    -- One ordered command: separate asynchronous moves race each other.
    if #names > 0 then sbar.exec(table.concat(moves, " ")) end
  end

  local function refresh_focus()
    local requested = generation
    sbar.exec("aerospace list-workspaces --focused", function(workspace, code)
      if requested ~= generation or code ~= 0 or type(workspace) ~= "string" then return end
      highlight(workspace:match("[^\r\n]+"))
    end)
  end

  local function receive_workspaces(result, code)
    busy = false
    if code ~= 0 or type(result) ~= "string" or result == "" then return end

    reconcile(result)
    refresh_focus()
  end

  local function refresh_mode()
    mode_generation = mode_generation + 1
    local requested = mode_generation
    sbar.exec("aerospace list-modes --current", function(result, code)
      if requested ~= mode_generation then return end
      local current = code == 0 and type(result) == "string" and result:match("^%s*(%S+)%s*$")
      if not current then
        help_requested = false
        return
      end

      service_active = current == "service"
      if not service_active then popup.close() end
      service:set({ drawing = service_active })
      for _, item in pairs(spaces) do
        item:set({ drawing = not service_active })
      end
      if service_active and help_requested then popup.toggle() end
      help_requested = false
    end)
  end

  local function refresh()
    refresh_mode()
    if busy then return end
    busy = true

    sbar.exec("aerospace list-workspaces --all", receive_workspaces)
  end

  local function workspace_changed(env)
    generation = generation + 1
    if env.FOCUSED_WORKSPACE then highlight(tostring(env.FOCUSED_WORKSPACE)) end
    refresh()
  end

  watcher:subscribe("aerospace_service_help", function()
    help_requested = true
    refresh_mode()
  end)
  watcher:subscribe("aerospace_mode_change", refresh_mode)
  watcher:subscribe("aerospace_workspace_change", workspace_changed)
  watcher:subscribe({ "routine", "forced", "system_woke", "display_change" }, refresh)
end
