# Force-install Brave browser extensions via macOS managed preferences policy.
# Extensions listed in install/Bravefile will be automatically installed
# and cannot be removed by the user while the policy is in place.

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(dirname "${_SCRIPT_DIR}")}"
unset _SCRIPT_DIR
EXTENSIONS_FILE="${DOTFILES_DIR}/install/Bravefile"
UPDATE_URL="https://clients2.google.com/service/update2/crx"

if [ ! -f "${EXTENSIONS_FILE}" ]; then
  echo "No Bravefile found, skipping."
  return 0 2>/dev/null || exit 0
fi

EXTENSIONS=()
while IFS= read -r line || [ -n "${line}" ]; do
  # Skip comments and blank lines
  [[ "${line}" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${line//[[:space:]]/}" ]] && continue
  EXTENSIONS+=("${line};${UPDATE_URL}")
done < "${EXTENSIONS_FILE}"

if [ "${#EXTENSIONS[@]}" -eq 0 ]; then
  echo "No Brave extensions listed, skipping."
  return 0 2>/dev/null || exit 0
fi

sudo mkdir -p "/Library/Managed Preferences"
sudo python3 - "${EXTENSIONS[@]}" <<'PYTHON'
import sys, plistlib, pathlib

extensions = sys.argv[1:]
plist_path = pathlib.Path("/Library/Managed Preferences/com.brave.Browser.plist")

data = {}
if plist_path.exists():
    with plist_path.open("rb") as f:
        data = plistlib.load(f)

data["ExtensionInstallForcelist"] = extensions

with plist_path.open("wb") as f:
    plistlib.dump(data, f)
PYTHON

# Cache the new settings immediately by killing cfprefsd, which Brave uses to read the policy.
sudo killall cfprefsd 2>/dev/null || true

# Restart Brave to pick up the new settings
if pgrep -xq "Brave Browser"; then
  killall "Brave Browser"
  sleep 1
  open -a "Brave Browser"
fi

echo "Brave: force-install policy set for ${#EXTENSIONS[@]} extension(s)."
