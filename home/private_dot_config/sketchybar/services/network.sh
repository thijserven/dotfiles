#!/bin/sh
# Read local counters only: no speed tests, external requests or privileged tools.
set -eu
export LC_ALL=C

# scutil fields can contain spaces (for example, service names).
field() {
  awk -v key="$1" '$1 == key && $2 == ":" { sub(/^[^:]*: /, ""); print; exit }'
}

read_service() {
  printf 'show Setup:/Network/Service/%s%s\n' "$service" "$1" | /usr/sbin/scutil
}

read_network_state() {
  state=$(/usr/sbin/scutil <<'EOF'
show State:/Network/Global/IPv4
show State:/Network/Global/IPv6
EOF
)
  interface=$(printf '%s\n' "$state" | field PrimaryInterface)
  router=$(printf '%s\n' "$state" | field Router)
  service=$(printf '%s\n' "$state" | field PrimaryService)

  # Validate identifiers before passing them to scutil or interface tools.
  case "$interface" in
    *[!a-zA-Z0-9]*|'')
      interface=''
      ;;
  esac
  case "$service" in
    *[!a-zA-Z0-9-]*|'')
      service=''
      ;;
  esac

  name=''
  hardware=''
  if [ -n "$service" ]; then
    hardware=$(read_service /Interface | field Type)
    name=$(read_service '' | field UserDefinedName)
  fi

}

sample_wifi() {
  wifi=$(/usr/bin/osascript -l JavaScript 2>/dev/null <<'EOF' || printf '{}'
ObjC.import('CoreWLAN');
var w = $.CWWiFiClient.sharedWiFiClient.interface;
JSON.stringify(w.isNil() ? {} : {
  interface: w.interfaceName.js || '', ssid: w.ssid.js || '',
  rssi: Number(w.rssiValue), noise: Number(w.noiseMeasurement),
  rate: Number(w.transmitRate), power: Boolean(w.powerOn)
});
EOF
)
}

sample_interface() {
  ipv4=''
  ipv6=''
  counters=''
  if [ -n "$interface" ]; then
    ipv4=$(/usr/sbin/ipconfig getifaddr "$interface" 2>/dev/null || :)
    ipv6=$(/sbin/ifconfig "$interface" 2>/dev/null | awk '/inet6 / { print $2; exit }')
    # Link row is the aggregate; address rows repeat the same counters.
    counters=$(/usr/sbin/netstat -ibn -I "$interface" | awk '
    /<Link#/ { print $7, $10, $6, $9; exit }')
  fi
}

render_network() {
  jq -n --arg interface "$interface" --arg router "$router" --arg name "$name" \
    --arg ipv4 "$ipv4" --arg ipv6 "$ipv6" --arg hardware "$hardware" \
    --arg counters "$counters" --argjson wifi "$wifi" --argjson time "$(date +%s)" '
  ($counters | split(" ") | map(tonumber?)) as $c |
  {interface: $interface, router: $router, name: $name, ipv4: $ipv4, ipv6: $ipv6,
   kind: (if $interface == "" then "Offline"
     elif $interface == $wifi.interface then "Wi-Fi"
     elif $hardware == "Ethernet" then "Ethernet" else "Other" end),
   wifi: $wifi, time: $time, rx: $c[0], tx: $c[1],
   errors: (if ($c | length) == 4 then $c[2] + $c[3] else null end)}'
}

main() {
  read_network_state
  sample_wifi
  sample_interface
  render_network
}

main
