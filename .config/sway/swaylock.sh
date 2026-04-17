#!/usr/bin/env bash

# Surgical Gruvbox Swaylock Script
# Precisely matched to Hyprlock aesthetic using swaylock-effects-git

swaylock \
  --screenshots \
  --clock \
  --indicator \
  --indicator-radius 160 \
  --indicator-thickness 20 \
  --effect-blur 7x5 \
  --effect-vignette 0.5:0.5 \
  --ring-color b8bb26 \
  --key-hl-color fe8019 \
  --bs-hl-color fb4934 \
  --text-color b8bb26 \
  --text-caps-lock-color fabd2f \
  --line-color 00000000 \
  --inside-color 282828aa \
  --separator-color 00000000 \
  --fade-in 0.2 \
  --font "ProFont IIx Nerd Font Bold" \
  --font-size 120 \
  --ring-ver-color 83a598 \
  --inside-ver-color 282828aa \
  --ring-wrong-color fb4934 \
  --inside-wrong-color 282828aa \
  --ring-clear-color 8ec07c \
  --inside-clear-color 282828aa \
  --datestr "Hi there, $USER" \
  --timestr "%H:%M" \
  --ignore-empty-password
