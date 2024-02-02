#!/usr/bin/env bash

SRC=~/.mozilla/firefox/.dotter/chrome/userChrome.css
INCLUDE=~/.mozilla/firefox/.dotter/chrome/include
# grab all profiles
for i in ~/.mozilla/firefox/*/prefs.js
do
    DIR=$(dirname $i)
    mkdir -p $DIR/chrome
    ln -fs $SRC $DIR/chrome/userChrome.css
    rm -rf $DIR/chrome/include
    ln -fs $INCLUDE $DIR/chrome/include
done
