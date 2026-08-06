#!/bin/bash
# awesome mod+a: restore the current tag's 'minimized' windows, which mod+n
# parked in that tag's special:min<tag> workspace

ws=$(hyprctl activeworkspace -j | jq -r '.id')
hyprctl clients -j | jq -r --arg min "special:min$ws" '.[] | select(.workspace.name == $min) | .address' |
while read -r addr; do
    hyprctl dispatch movetoworkspacesilent "$ws,address:$addr"
done
