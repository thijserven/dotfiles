local sketchybar = {}
local tasks = {}
local command = "PATH=/opt/homebrew/bin:/usr/local/bin:$PATH exec sketchybar --trigger "

-- Events and arguments are internal constants, never user input.
function sketchybar.trigger(event, arguments, failure)
  local task
  task = hs.task.new("/bin/sh", function(code, _, stderr)
    tasks[task] = nil
    if code ~= 0 and failure then
      hs.printf("%s: %s", failure, stderr)
    end
  end, { "-c", command .. event .. (arguments and " " .. arguments or "") })

  if task then
    tasks[task] = true
    if not task:start() then
      tasks[task] = nil
    end
  end
end

return sketchybar
