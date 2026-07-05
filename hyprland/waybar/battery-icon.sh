#!/bin/bash
# waybar image#bat: battery icon variant (theme.lua battery/battery-charge/battery-low)

d="{{trim (command_output "realpath ~")}}/.config/awesome/data"
s=$(/bin/cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
c=$(/bin/cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
if [ "$s" = "Charging" ]; then
    echo "$d/battery-charge.png"
elif [ "${c:-100}" -le 15 ]; then
    echo "$d/battery-low.png"
else
    echo "$d/battery.png"
fi
