#!/usr/bin/env bash

# Surgical Gruvbox Swayidle Laptop Config
# 5m: Dim | 10m: Lock | 15m: Suspend | 50m: Hibernate

swayidle -w \
    timeout 300 'brightnessctl -s set 10%' resume 'brightnessctl -r' \
    timeout 600 "swaylock" \
    timeout 900 'systemctl suspend' \
    timeout 3000 'systemctl hibernate' \
    before-sleep "swaylock"
