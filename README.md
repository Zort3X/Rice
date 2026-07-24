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

## ⚠️ Read This If You're Not Me

This rice was built for one specific person's machine and habits first, and made reusable second. Before you run it, know the following:

- **AUR packages can go stale.** Names like `zen-browser-bin`, `wifitui-bin`, and `swaylock-effects-git` occasionally get renamed or orphaned upstream. If `install.sh` fails partway through package install, check `install.log` for the exact package that failed and look it up on [aur.archlinux.org](https://aur.archlinux.org) — it's usually a rename, not a real problem.
- **The firewall (ufw) denies all incoming by default.** Only SSH + Tailscale's port get opened, and only if you answer "yes" to that prompt. If you run other services (game servers, Syncthing, Samba, etc.), you'll need to open those ports yourself afterward, e.g. `sudo ufw allow 8384`.
- **Tailscale needs a manual `tailscale up`** after install — the script installs and enables the service but doesn't authenticate it for you.
- **Nvidia users:** the script edits `/etc/mkinitcpio.conf` and rebuilds your initramfs. This is safe on a genuinely fresh Arch install (the intended use case). If you're running this on an already-configured system, back up `/etc/mkinitcpio.conf` first.
- **GRUB theming only applies if you actually use GRUB.** systemd-boot and other bootloaders are detected and skipped automatically — no action needed either way.
- **Personal touches you'll probably want to change:**
  - Default keyboard layout is `us,bg` (Bulgarian) — edit `kb_layout`/`kb_variant` in `hypr/hyprland.conf` or `xkb_layout`/`xkb_variant` in `sway/config` if that's not you.
  - Sway's exit-confirmation dialog has a swear word in the button text (`'Fuck this shit.'` in `sway/config`) — harmless, but cosmetic and easy to change.
  - The desktop-profile Hyprland monitor config (`.config/desktop/hypr/monitor.conf`) is calibrated to the author's exact panel (`DP-1 @ 200Hz`). Run `hyprctl monitors all` after first login and edit that file if yours doesn't match. Laptop profile uses a generic auto-detect rule and needs no changes.
- **No automatic rollback.** If something fails mid-install, the script stops, logs exactly where in `install.log`, and it's safe to just run it again — completed steps won't be redone or broken.
- **Old configs aren't deleted, just moved.** Anything `install.sh` replaces gets relocated into `~/.rice-backup-<timestamp>/` instead of being erased. Feel free to `rm -rf ~/.rice-backup-*` once you're confident you don't need them.
- **Want to see what it'll do before it touches anything?** Run `./install.sh --dry-run` first.

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
Follow the interactive prompts to select your Window Manager, hardware profile, GPU driver, and optional SSH server installation.
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
