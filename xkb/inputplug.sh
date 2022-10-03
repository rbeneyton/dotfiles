#!/bin/bash

# make xkb settings robust to plug/unplug of keyboard (triggered by kvm switch)
# usage: $ inputplug -d -0 -c /.../inputplug.sh

event=$1 id=$2 type=$3
echo $(basename ${BASH_SOURCE[0]}) " for display $DISPLAY got event " "$@"
[ "$event" != "XIDeviceEnabled" ] && (echo fail1 ; exit 0)
[ "$type" != "XISlaveKeyboard" ] && (echo fail2 ; exit 0)

# currently same settings for all keyboards (amazon basics, ajazz, keychron...) but trivial to customize via dotter
CONF=${HOME}/.config/xkb
# xkbcomp -i "$id" -I${CONF} -R${CONF} ${CONF}/keymap/keymap.xkb $DISPLAY &> /dev/null
# RB temp manual force before comp
# setxkbmap -layout us -option compose:lalt,ctrl:nocaps,shift:both_capslock_cancel,lv3:menu_switch
# TODO switch via dotter/keyboard label
xkbcomp -I${CONF} -R${CONF} ${CONF}/keymap/keymap.xkb $DISPLAY &> /tmp/inputplug.sh.log
# check effect via $ xkbcomp -xkb $DISPLAY /tmp/xkbmap
