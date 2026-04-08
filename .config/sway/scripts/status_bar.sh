#!/bin/bash

get_vol() {
    local line muted
    line=$(pactl get-sink-volume @DEFAULT_SINK@)
    local vol="${line#*/ }"
    vol="${vol%%%*}%"
    muted=$(pactl get-sink-mute @DEFAULT_SINK@)
    [[ "$muted" == *"yes" ]] && printf "vol: %s (m)" "$vol" || printf "vol: %s" "$vol"
}

get_bat() {
    local cap status
    cap=$(< /sys/class/power_supply/BAT0/capacity)
    status=$(< /sys/class/power_supply/BAT0/status)
    [[ "$status" == "Charging" ]] && printf "ac:  %s" "${cap}%" || printf "bat: %s" "${cap}%"
}

get_bl() {
    local cur max
    cur=$(< /sys/class/backlight/*/brightness)
    max=$(< /sys/class/backlight/*/max_brightness)
    printf "bl:  %s" "$(( cur * 100 / max ))%"
}

while true; do
    CLK=$(date +'%H:%M %A, %b %d' | tr '[:upper:]' '[:lower:]')
    printf "%s   %s   %s   %s\n" "$CLK" "$(get_vol)" "$(get_bat)" "$(get_bl)"
    sleep 3
done
