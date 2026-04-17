# Surgical Gruvbox Rice

A high-performance, hardware-aware desktop environment setup for **Arch Linux**, featuring **Hyprland** and **SwayFX**.

## ⚠️ WARNING
**Before running the installer, please verify the packages and drivers defined in `install.sh`.**
Each system is unique; ensure the selected GPU drivers (NVIDIA, AMD, or Intel) match your specific hardware. Using incorrect drivers can lead to a broken graphical environment.

## Key Features
- **Palette**: Gruvbox (Surgical version)
- **WMs**: Hyprland (Eye-candy) & SwayFX (Stability/Performance)
- **Terminals**: Alacritty (Hyprland) & Foot (SwayFX)
- **Font**: ProFont IIx Nerd Font (Bold, Size 15)
- **Hardware Aware**: Distinct profiles for **Desktop** and **Laptop**.
- **Automated NVIDIA Setup**: Automatic kernel parameter injection and mkinitcpio configuration.

## Repository Structure
All configurations are located in the `.config/` directory:
- `.config/[app]`: Common configurations (Fish, Rofi, Mako, Alacritty, Foot, etc.).
- `.config/hypr/`: Core Hyprland configs (land, lock, paper).
- `.config/sway/`: Core Sway configs (config, lock script).
- `.config/desktop/`: Desktop-specific overrides.
  - `hypr/hypridle.conf`
  - `sway/swayidle.sh`
  - `waybar_hypr/`: Waybar config for Hyprland Desktop.
  - `waybar_sway/`: Waybar config for Sway Desktop.
- `.config/laptop/`: Laptop-specific overrides (Battery, Screen dimming).
  - `hypr/hypridle.conf`
  - `sway/swayidle.sh`
  - `waybar_hypr/`: Waybar config for Hyprland Laptop.
  - `waybar_sway/`: Waybar config for Sway Laptop.

## Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/Rice.git ~/Rice
   ```
2. Run the installer:
   ```bash
   cd ~/Rice
   chmod +x install.sh
   ./install.sh
   ```

## Previews
*(Add screenshots here)*
