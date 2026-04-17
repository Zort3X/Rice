# Gruvbox Rice

⚠️ **WARNING: Hardware-Specific Calibration**
This repository is a personal project optimized for a specific hardware ecosystem. It includes drivers and kernel parameters tailored for NVIDIA (GT 1030), AMD (7800X3D), and legacy Intel (X230 Laptop) systems.
- **NVIDIA Users**: Ensure `nvidia-drm.modeset=1` is active in GRUB to prevent Wayland initialization failure.
- **Legacy Intel**: Driver choices (e.g., `intel-media-driver`) are calibrated for stability on older intel CPUs.
- **Package Selection**: Software lists are subjective and functional for my workflow. Review `install.sh` before execution.

## Palette
- Theme: Gruvbox Dark (Main accent: Green)

## Essential Keybinds
| Action | Keybind |
| :--- | :--- |
| Terminal | `$mod + Enter` |
| Launcher (Rofi) | `$mod + D` |
| Kill App | `$mod + Q` |
| Focus Window | `$mod + Arrow Keys` |
| Move Window | `$mod + Shift + Arrow Keys` |
| Switch Workspace | `$mod + [1-9]` |
| Move to Workspace | `$mod + Shift + [1-9]` |
| Exit WM | `$mod + Shift + E` |

## Post-Install Checklist
- Verify monitor resolution in `~/.config/hypr/hyprland.conf` or `~/.config/sway/config`.
- Confirm keyboard layout in the WM input section (default: us,bg).
- Check `seat0` cursor theme configuration.

## Credits
- GRUB Theme: [OldBIOS](https://github.com/Blaysht/grub_bios_theme) by Blaysht.
