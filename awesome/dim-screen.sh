#!/bin/bash

get_brightness() {
    light -G
}

set_brightness() {
    light -S $1
}

trap 'exit 0' TERM INT
trap "set_brightness $(get_brightness); kill %%" EXIT
set_brightness 0
sleep 2147483647 &
wait
