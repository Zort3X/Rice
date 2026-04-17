# Gruvbox Rice

⚠️ WARNING: NVIDIA users must verify `nvidia-drm.modeset=1` in GRUB. Intel/Laptop users must ensure `mesa` and `intel-media-driver` are installed to avoid artifacts.

## Palette
- Theme: Gruvbox Deep
- Accent: Green (#b8bb26)
- Background: #282828

## Essential Keybinds
| Action | Keybind |
| :--- | :--- |
| Terminal | `$mod + Enter` |
| Launcher (Rofi) | `$mod + D` |
| Kill App | `$mod + Q` |
| Lock Screen | `$mod + L` |
| Exit WM | `$mod + Shift + E` |

## Repository Structure
```
~/Rice/
├── install.sh
├── README.md
├── grub_bios_theme/
│   └── OldBIOS/
├── .config/
    ├── alacritty/
    ├── background/
    ├── btop/
    ├── fastfetch/
    ├── fish/
    ├── foot/
    ├── hypr/
    ├── mako/
    ├── rofi/
    ├── sway/
    ├── swaylock/
    ├── desktop/
    │   ├── hypr/
    │   ├── sway/
    │   └── waybar_hypr/
    │   └── waybar_sway/
    └── laptop/
        ├── hypr/
        ├── sway/
        └── waybar_hypr/
        └── waybar_sway/
```

## Post-Install Checklist
- Check `~/.config/hypr/hyprland.conf` or `~/.config/sway/config` for monitor resolution.
- Set keyboard layout (default: us,bg).
- Verify `seat0` cursor theme (Bibata-Modern-Classic).

## Credits
- GRUB Theme: [OldBIOS](https://github.com/Blaysht/grub_bios_theme) by Blaysht.

- Repository documented: true
