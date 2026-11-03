local state = {}

function state.publish(path, opened)
  -- Readers must see complete old or new state, never a truncated lease.
  local temporary = path .. ".tmp"
  local file = io.open(temporary, "w")
  if not file then return false end
  local written = file:write(opened and tostring(os.time()) or "closed")
  local closed = file:close()
  if not written or not closed then
    os.remove(temporary)
    return false
  end
  local renamed = os.rename(temporary, path)
  if not renamed then os.remove(temporary) end
  return renamed ~= nil
end

return state
