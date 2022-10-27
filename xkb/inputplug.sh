#!/bin/bash

shopt -s expand_aliases
source ~/.bashrc

# make xkb settings robust/customizable on plug/unplug of keyboard (and triggered by kvm switch)
# usage: $ inputplug -d -0 -c /.../inputplug.sh

event=$1 id=$2 type=$3
echo $(datefull) ":" $(basename ${BASH_SOURCE[0]}) "for display $DISPLAY got event" "$@"
[ "$event" != "XIDeviceEnabled" ] && exit 1
[ "$type" != "XISlaveKeyboard" ] && exit 1

# currently same settings for all keyboards (amazon basics, ajazz, keychron...) but trivial to customize via dotter
CONF=${HOME}/.config/xkb
# xkbcomp -i "$id" -I${CONF} -R${CONF} ${CONF}/keymap/keymap.xkb $DISPLAY &> /dev/null
# RB temp manual force before comp
# setxkbmap -layout us -option compose:lalt,ctrl:nocaps,shift:both_capslock_cancel,lv3:menu_switch
# TODO switch via dotter/keyboard label?
echo $(datefull) ":" "apply..."
xkbcomp -I${CONF} -R${CONF} ${CONF}/keymap/keymap.xkb $DISPLAY
# check effect via $ xkbcomp -xkb $DISPLAY /tmp/xkbmap
