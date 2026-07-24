#!/usr/bin/env bash

# Detect which WM we're actually running under, so Lock/Logout call the
# right binary (hyprlock/hyprctl on Hyprland, swaylock/swaymsg on Sway).
if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    lock_cmd="hyprlock"
    logout_cmd="hyprctl dispatch exit"
elif [ -n "$SWAYSOCK" ]; then
    lock_cmd="swaylock"
    logout_cmd="swaymsg exit"
else
    lock_cmd="loginctl lock-session"
    logout_cmd="loginctl terminate-session $XDG_SESSION_ID"
fi

# Options
shutdown=' Shutdown'
reboot='󰜉 Reboot'
lock=' Lock'
suspend='󰒲 Suspend'
logout='󰍃 Logout'

# Rofi Command
rofi_command="rofi -dmenu -p 'Power' -theme-str 'window {width: 400px;}' -theme-str 'listview {lines: 5;}'"

# Selection
run_rofi() {
	echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | $rofi_command
}

# Execute
chosen="$(run_rofi)"
case ${chosen} in
    $shutdown)
		systemctl poweroff
        ;;
    $reboot)
		systemctl reboot
        ;;
    $lock)
		$lock_cmd
        ;;
    $suspend)
		systemctl suspend
        ;;
    $logout)
		$logout_cmd
        ;;
esac
