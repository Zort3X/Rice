# 🛠️ Surgical Gruvbox Dotfiles

A high-performance, hardware-aware desktop environment built on the **Gruvbox** palette. Designed for efficiency, clarity, and "surgical" precision.

![Gruvbox](https://img.shields.io/badge/Theme-Gruvbox-orange?style=for-the-badge)
![Arch Linux](https://img.shields.io/badge/OS-Arch%20Linux-blue?style=for-the-badge&logo=arch-linux)
![License](https://img.shields.io/badge/License-GPL--3.0-green?style=for-the-badge)

---

## 🔬 The Philosophy
Most dotfiles are "bloated." **Surgical Gruvbox** is different. Every module, color choice, and font size is calibrated to provide maximum information density with zero distractions.

- **Font:** [ProFont IIx Nerd Font](https://github.com/ryanoasis/nerd-fonts) (The pixel-perfect choice for high-density layouts).
- **Colors:** Deep Gruvbox background (`#282828`) with high-contrast **Orange** and **Aqua** accents.
- **Hardware-Aware:** One installer for both Laptop and Desktop profiles.

---

## 📦 Components
| Component | Software | Description |
| :--- | :--- | :--- |
| **WM** | Hyprland / Sway | Tiling Wayland Compositors |
| **Bar** | Waybar | Minimalist, hardware-specific status bar |
| **Terminal** | Alacritty | GPU-accelerated terminal |
| **Menu** | Rofi | Application launcher & power menu |
| **Notify** | Mako | Clean notification daemon |
| **Login** | Ly | Lightweight TUI display manager |
| **Shell** | Fish | User-friendly, interactive shell |

---

## 🚀 Installation

The installer is interactive and will ask you about your hardware (GPU, Laptop/Desktop) to ensure the correct drivers and configurations are linked.

```bash
git clone https://github.com/YOUR_USERNAME/Rice.git
cd Rice
chmod +x install.sh
./install.sh
```

> [!IMPORTANT]
> The installer handles GPU drivers for AMD and Intel automatically. NVIDIA users will be prompted to install their specific drivers manually after reboot.

---

## 🛠️ Management (Git Guide)

To keep your repo updated or upload changes, follow these steps:

### 1. Check your status
```bash
git status
```

### 2. Stage your changes
Add everything to the next commit:
```bash
git add .
```

### 3. Commit
Save your changes with a surgical message:
```bash
git commit -m "feat: update waybar colors to surgical aqua"
```

### 4. Push to GitHub
Upload your local commits to the cloud:
```bash
git push origin main
```

---

## 🎨 Palette Reference
- **Background:** `#282828`
- **Text:** `#ebdbb2`
- **Primary Accent:** `#fe8019` (Orange)
- **Secondary Accent:** `#8ec07c` (Aqua)
- **Status Accent:** `#b8bb26` (Green)
- **The "Secret" Accent:** `#d3869b` (Purple)

---

*“Measure twice, rice once.”*
