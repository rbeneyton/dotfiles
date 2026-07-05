#!/bin/bash
# awesome mod+a: restore all 'minimized' (special:min) windows onto the current workspace

ws=$(hyprctl activeworkspace -j | jq -r '.id')
hyprctl clients -j | jq -r '.[] | select(.workspace.name == "special:min") | .address' |
while read -r addr; do
    hyprctl dispatch movetoworkspacesilent "$ws,address:$addr"
done
