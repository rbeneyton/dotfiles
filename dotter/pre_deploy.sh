#!/usr/bin/env bash

# deterministic symlink to firefox default profile
rm -f ~/.mozilla/firefox/link.default
ln -s ~/.mozilla/firefox/*.default ~/.mozilla/firefox/link.default
