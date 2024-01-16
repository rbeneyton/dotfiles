#!/usr/bin/env bash

SRC=~/.mozilla/firefox/.dotter/chrome/userChrome.css
# grab all profiles
for i in ~/.mozilla/firefox/*/prefs.js
do
    DIR=$(dirname $i)
    mkdir -p $DIR/chrome
    ln -fs $SRC $DIR/chrome/userChrome.css
done
