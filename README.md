# Gruvbox Rice

A flexible, Gruvbox-themed configuration baseline designed to support a wide range of system architectures and hardware generations.

⚠️ **WARNING: Hardware Calibration Required**
These configurations serve as a generic baseline. If you are using different hardware generations (e.g., brand-new Intel GPUs or very old AMD processors), please review the driver selections in `install.sh`. You may need to swap specific packages to ensure full compatibility.

---

## 📖 Project Philosophy
This repository is a personal hobbyist project born from my own learning journey.
- **Development Style**: I am an amateur developer building these configurations to the best of my current knowledge. Setups are optimized for my specific workflow.
- **Maintenance**: This is not a full-time job. I do not provide daily updates or guaranteed maintenance.
- **Support**: If you encounter a bug, feel free to open a ticket. I may look into it if I have time, but I cannot guarantee a fix.

---

## 🔧 Hardware Compatibility
- **NVIDIA Environments**: Includes configurations for Wayland stability. Ensure `nvidia-drm.modeset=1` is in your boot parameters.
- **Modern AMD CPUs**: Tuned for performance scaling and efficiency (e.g., Zen 4+).
- **Legacy Intel**: Includes stable drivers (like `intel-media-driver`) for older G4400 and X230 architectures.

---

## 🚀 Installation
Ensure you are on a fresh Arch installation with `git` installed.

### 1. Clone & Audit
```bash
git clone https://github.com/Zort3X/Rice.git
cd Rice
nano install.sh # Review package lists
```

### 2. Execute
```bash
chmod +x install.sh
./install.sh
```

---

## ⌨️ Essential Keybinds
| Action | Keybind |
| :--- | :--- |
| Terminal | `$mod + Enter` |
| Launcher (Rofi) | `$mod + D` |
| Kill Window | `$mod + Q` |
| Focus Navigation | `$mod + Arrow Keys` |
| Move Window | `$mod + Shift + Arrow Keys` |
| Switch Workspace | `$mod + [1-9]` |
| Exit WM | `$mod + Shift + E` |

---

## ✅ Post-Install Checklist
1. **Monitor Resolution**: Verify settings in `~/.config/hypr/hyprland.conf` or `~/.config/sway/config`.
2. **Keyboard Layout**: Confirm layout in the WM input section (Default: `us,bg`).
3. **Appearance**: Check cursor theme and GTK settings for consistency.

---

## 🎨 Design Reference
- **Theme**: Gruvbox (Main accent: green)
- **GRUB Theme**: [OldBIOS](https://github.com/Blaysht/grub_bios_theme) by Blaysht.

- README calibrated: true
