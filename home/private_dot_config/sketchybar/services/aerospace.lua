local aerospace = {}

local function workspace_order(left, right)
  local left_number, right_number = tonumber(left), tonumber(right)
  if left_number and right_number and left_number ~= right_number then
    return left_number < right_number
  end

  if (left_number ~= nil) ~= (right_number ~= nil) then
    return left_number ~= nil
  end

  return left < right
end

function aerospace.quote(value)
  return "'" .. value:gsub("'", "'\\''") .. "'"
end

function aerospace.workspaces(result)
  local names, seen = {}, {}
  for name in result:gmatch("[^\r\n]+") do
    -- SbarLua item names have a 63-byte ceiling, including "space.".
    if #name <= 57 and not seen[name] then
      names[#names + 1] = name
      seen[name] = true
    end
  end
  table.sort(names, workspace_order)
  return names, seen
end

-- Match Vicinae's AeroSpace action titles and key notation.
local function action_title(command)
  if command:match("^%s*exec%-and%-forget%s+sketchybar%s+%-%-trigger%s+aerospace_service_help%s*$") then
    return "Toggle service mode keybindings list"
  end

  local titles = {}
  for action in command:gmatch("[^;]+") do
    local parts = {}
    for part in action:gmatch("%S+") do
      if part:sub(1, 2) ~= "--" then
        parts[#parts + 1] = part
      end
    end
    local title
    if parts[1] == "mode" and parts[2] then
      title = parts[2] == "main" and "Return to normal shortcuts"
        or "Switch to " .. parts[2] .. " shortcuts"
    elseif parts[1] == "move-workspace-to-monitor" and parts[2] then
      title = "Move workspace to " .. parts[2] .. " monitor"
    else
      title = table.concat(parts, " "):gsub("[-_]+", " "):lower():gsub("^%w", string.upper)
    end
    if not (parts[1] == "mode" and parts[2] == "main") then
      titles[#titles + 1] = title
    end
  end
  return table.concat(titles, " - ")
end

local function format_keys(keys)
  local aliases = {
    slash = "/", comma = ",", period = ".", dot = ".", semicolon = ";", colon = ":",
    apostrophe = "'", quote = '"', backslash = "\\", backtick = "`", minus = "-", hyphen = "-",
    equal = "=", equals = "=", leftbracket = "[", rightbracket = "]", leftbrace = "{", rightbrace = "}",
    command = "cmd", alt = "opt", option = "opt", super = "hyper",
    escape = "esc", backspace = "delete", delete = "⌫", control = "ctrl",
  }
  local tokens, hyper = {}, false
  for key in keys:gmatch("[^-]+") do
    local token = aliases[key:lower()] or key
    tokens[#tokens + 1] = token
    hyper = hyper or token == "hyper"
  end
  if hyper then
    local filtered = { "hyper" }
    for _, token in ipairs(tokens) do
      if token ~= "hyper" and token ~= "ctrl" and token ~= "opt" and token ~= "shift" then
        filtered[#filtered + 1] = token
      end
    end
    tokens = filtered
  end
  return table.concat(tokens, " + ")
end

function aerospace.bindings(result)
  local keys, bindings = {}, {}
  for key, command in pairs(result) do
    if type(key) == "string" and type(command) == "string" then
      keys[#keys + 1] = key
    end
  end
  table.sort(keys)
  for _, key in ipairs(keys) do
    bindings[#bindings + 1] = { keys = format_keys(key), title = action_title(result[key]) }
  end
  return bindings
end

return aerospace
