#!/usr/bin/env zsh
# Lenovo / Arch quick‑health probe – READ‑ONLY

set -euo pipefail

print_header() { print -P "%F{cyan}\n==== $1 ====%f" ; }
have() { command -v "$1" >/dev/null 2>&1 }

print_header "HOST & KERNEL"
uname -a
grep '^PRETTY_NAME' /etc/os-release | cut -d= -f2-

print_header "CPU / MEM / TEMPS"
lscpu | grep -E 'Model name|Architecture|CPU\(s\)'
free -h
have sensors && sensors | head -n 20 || echo "lm_sensors not installed"

print_header "GPU"
lspci | grep -E 'VGA|3D'

print_header "AUDIO"
have aplay       && aplay -l          || echo "aplay (alsa-utils) missing"
have pactl       && pactl list short sinks || echo "pactl (pipewire-pulse) missing"
if have speaker-test; then
  echo "-- Playing 440 Hz sine for 1 cycle per channel …"
  speaker-test -t sine -f 440 -c 2 -l 1 >/dev/null 2>&1
else
  echo "speaker-test missing (alsa-utils)"
fi

print_header "BRIGHTNESS"
if [[ -d /sys/class/backlight ]]; then
  for dev in /sys/class/backlight/*; do
    echo "$dev → $(< $dev/brightness) / $(< $dev/max_brightness)"
  done
else
  echo "No /sys/class/backlight interface detected"
fi
have brightnessctl && brightnessctl info || true

print_header "DISPLAYS"
have xrandr  && xrandr -q | grep -A1 ' connected' \
            || have swaymsg && swaymsg -t get_outputs

print_header "POWER / BATTERY"
have acpi && acpi -b || upower -i $(upower -e | grep battery) | grep -E 'state|percentage|time'

print_header "NET-IFACES"
ip -brief addr
have nmcli && nmcli device status
have ping && ping -c 3 1.1.1.1 | tail -n2

print_header "WI-FI SCAN (first 10 APs)"
have nmcli && nmcli -t -f SSID,SIGNAL dev wifi list | head

print_header "INPUT DEVICES (libinput)"
if have libinput; then
  libinput list-devices 2>/dev/null | grep -E 'Device|Kernel|Capabil' \
    || sudo -n libinput list-devices 2>/dev/null | grep -E 'Device|Kernel|Capabil' \
    || echo "libinput: need sudo and no passwordless sudo available"
else
  echo "libinput not installed (needed for KB/mouse/touchscreen details)"
fi

print_header "LOGIN SESSIONS"
who ; echo ; w -h

print_header "SERVICES (failed)"
systemctl --failed --no-legend || true

echo -e "\n%F{green}✓ System probe finished - review the output above.%f"
