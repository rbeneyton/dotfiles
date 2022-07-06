#!/bin/bash

# make xkb settings robust to plug/unplug of keyboard (triggered by kvm switch)
# usage: $ inputplug -d -0 -c /.../inputplug.sh

event=$1 id=$2 type=$3
[ "$event" != "XIDeviceEnabled" ] && (echo fail1 ; exit 0)
[ "$type" != "XISlaveKeyboard" ] && (echo fail2 ; exit 0)
echo $(basename ${BASH_SOURCE[0]}) " for display $DISPLAY got event " "$@"

# currently same settings for all keyboards (amazon basics, ajazz, ...) but trivial to discrimate
# customize by host also trivial via dotter
CONF=${HOME}/.config/xkb
# xkbcomp -i "$id" -I${CONF} -R${CONF} ${CONF}/keymap/keymap.xkb $DISPLAY &> /dev/null
# RB temp manual force before comp
setxkbmap -layout us -option compose:lalt,ctrl:nocaps,shift:both_capslock_cancel,lv3:menu_switch
xkbcomp -I${CONF} -R${CONF} ${CONF}/keymap/keymap.xkb $DISPLAY &> /tmp/inputplug.sh.log
