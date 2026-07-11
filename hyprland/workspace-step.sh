#!/bin/bash
# workspace prev/next ($1 = -1/+1, $2 = optional dispatcher, default "workspace")
# clamped to tags [1,9], as in awesome but without wrap

ws=$(hyprctl activeworkspace -j | jq -r '.id')
next=$((ws + $1))
[ "$next" -ge 1 ] && [ "$next" -le 9 ] && hyprctl dispatch "${2:-workspace}" "$next"
