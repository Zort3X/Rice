#!/usr/bin/env bash

# Surgical Gruvbox Swayidle Desktop Config
# 10m: Lock | 15m: Off

swayidle -w \
    timeout 600 "swaylock" \
    timeout 900 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
    before-sleep "swaylock"
