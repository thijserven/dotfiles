-- Native Caps Lock -> F18 mapping. Preserve mappings owned by other tools.
local capsLock = {}

local CAPS_LOCK = 0x700000039
local F18 = 0x70000006d

local READ_MAPPINGS = [[
value=$(/usr/bin/hidutil property --get UserKeyMapping) || exit
if [ "$value" = '(null)' ]; then
  printf '[]'
else
  printf '%s' "$value" | /usr/bin/plutil -convert json -o - -- -
fi
]]

local function handleMappingWritten(status)
  if status ~= 0 then
    hs.printf("Hyper: cannot map Caps Lock to F18")
  end
end

local function handleMappingsRead(code, output)
  if code ~= 0 then
    hs.printf("Hyper: cannot read HID mappings")
    return
  end

  local ok, properties = pcall(hs.json.decode, output)

  if not ok or type(properties) ~= "table" then
    hs.printf("Hyper: invalid HID mappings")
    return
  end

  local mappings = {}

  for _, mapping in ipairs(properties) do
    local source = tonumber(mapping.HIDKeyboardModifierMappingSrc)
    local destination = tonumber(mapping.HIDKeyboardModifierMappingDst)

    if not source or not destination then
      hs.printf("Hyper: invalid HID mapping")
      return
    end

    if source ~= CAPS_LOCK then
      mappings[#mappings + 1] = {
        HIDKeyboardModifierMappingSrc = source,
        HIDKeyboardModifierMappingDst = destination,
      }
    end
  end

  mappings[#mappings + 1] = {
    HIDKeyboardModifierMappingSrc = CAPS_LOCK,
    HIDKeyboardModifierMappingDst = F18,
  }

  hs.task.new("/usr/bin/hidutil", handleMappingWritten, {
    "property",
    "--set",
    hs.json.encode({ UserKeyMapping = mappings }),
  }):start()
end

function capsLock.remap()
  hs.task.new("/bin/sh", handleMappingsRead, { "-c", READ_MAPPINGS }):start()
end

return capsLock
