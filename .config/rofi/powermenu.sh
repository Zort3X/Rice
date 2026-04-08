#!/usr/bin/env bash

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
		hyprlock
        ;;
    $suspend)
		systemctl suspend
        ;;
    $logout)
		hyprctl dispatch exit
        ;;
esac
