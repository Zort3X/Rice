#!/usr/bin/env bash

# Interactive Surgical Gruvbox Installer
# High-performance setup for Hyprland/Sway based on user choices.

set -e

echo "--- Starting Interactive Surgical Install ---"

# 1. Base dependencies for building and AUR access
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm base-devel git

# 2. Install yay (AUR Helper) if not present
if ! command -v yay &> /dev/null; then
    echo "--- Installing yay ---"
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/yay
fi

# 3. Interactive Configuration Questions
echo ""
echo "--- Installation Options ---"
read -p "Choose your Window Manager (1: Hyprland, 2: Sway): " wm_choice
read -p "Choose your Terminal (1: Alacritty, 2: Foot): " term_choice
read -p "Are you on a Laptop? (y/n): " laptop_choice
read -p "Choose your GPU (1: AMD, 2: NVIDIA, 3: Intel, 4: Generic/VM): " gpu_choice

# 4. Building the Package Lists
PACKAGES_GLOBAL=(
    fish neovim tldr btop yazi udisks2 rofi-wayland waybar mako 
    zen-browser-bin vesktop spotify-launcher bluetui wifitui-bin 
    ttf-profont-nerd bibata-cursor-theme-bin ly
)

PACKAGES_HYPRLAND=(
    hyprland hyprpaper hypridle hyprlock hyprshot 
    xdg-desktop-portal-hyprland
)

PACKAGES_SWAY=(
    sway swaybg swayidle swaylock grim slurp 
    xdg-desktop-portal-wlr autotiling
)

PACKAGES_LAPTOP=(
    tlp acpi_call tp_smapi brightnessctl acpi
)

PACKAGES_AMD=(
    mesa lib32-mesa vulkan-radeon rocm-smi-lib
)

PACKAGES_INTEL=(
    mesa lib32-mesa vulkan-intel
)

# Initialize final install list
FINAL_PACKAGES=("${PACKAGES_GLOBAL[@]}")

# Add WM specific packages
if [[ $wm_choice == "1" ]]; then
    echo "--- Selecting Hyprland packages ---"
    FINAL_PACKAGES+=("${PACKAGES_HYPRLAND[@]}")
elif [[ $wm_choice == "2" ]]; then
    echo "--- Selecting Sway packages ---"
    FINAL_PACKAGES+=("${PACKAGES_SWAY[@]}")
fi

# Add Terminal specific packages
if [[ $term_choice == "1" ]]; then
    echo "--- Selecting Alacritty ---"
    FINAL_PACKAGES+=("alacritty")
elif [[ $term_choice == "2" ]]; then
    echo "--- Selecting Foot ---"
    FINAL_PACKAGES+=("foot")
fi

# Add Laptop HW specific packages
if [[ $laptop_choice == "y" || $laptop_choice == "Y" ]]; then
    echo "--- Selecting Laptop HW packages ---"
    FINAL_PACKAGES+=("${PACKAGES_LAPTOP[@]}")
fi

# Add GPU specific packages
case $gpu_choice in
    1)
        echo "--- Selecting AMD GPU packages ---"
        FINAL_PACKAGES+=("${PACKAGES_AMD[@]}")
        ;;
    2)
        echo "--- NVIDIA detected ---"
        echo "Note: NVIDIA drivers vary by GPU generation."
        echo "Please install the driver that best suits your card manually."
        echo "(e.g., nvidia, nvidia-lts, or legacy drivers from AUR)"
        sleep 3
        ;;
    3)
        echo "--- Selecting Intel GPU packages ---"
        FINAL_PACKAGES+=("${PACKAGES_INTEL[@]}")
        ;;
    *)
        echo "--- Using generic graphics drivers ---"
        FINAL_PACKAGES+=("mesa" "lib32-mesa")
        ;;
esac

# 5. Final Installation Execution
echo "--- Installing Selected Packages ---"
yay -S --needed --noconfirm "${FINAL_PACKAGES[@]}"

# 6. Linking Configurations
echo "--- Linking Configurations ---"
DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p ~/.config

# Dynamically link based on selection
CONFIGS=(fish rofi mako fastfetch btop)

[[ $wm_choice == "1" ]] && CONFIGS+=(hypr)
[[ $term_choice == "1" ]] && CONFIGS+=(alacritty)
[[ $term_choice == "2" ]] && CONFIGS+=(foot)

for config in "${CONFIGS[@]}"; do
    if [ -d "$HOME/.config/$config" ]; then
        echo "Backing up existing $config..."
        mv "$HOME/.config/$config" "$HOME/.config/${config}.bak"
    fi
    ln -s "$DOTS_DIR/.config/$config" "$HOME/.config/$config"
done

# Handle Waybar Desktop/Laptop config
if [ -d "$HOME/.config/waybar" ]; then
    echo "Backing up existing waybar..."
    mv "$HOME/.config/waybar" "$HOME/.config/waybar.bak"
fi

if [[ $laptop_choice == "y" || $laptop_choice == "Y" ]]; then
    echo "--- Setting Waybar Laptop config ---"
    ln -s "$DOTS_DIR/.config/waybar_laptop" "$HOME/.config/waybar"
else
    echo "--- Setting Waybar Desktop config ---"
    ln -s "$DOTS_DIR/.config/waybar_desktop" "$HOME/.config/waybar"
fi

# 7. Setting Fish as default shell
if [[ $SHELL != "/usr/bin/fish" ]]; then
    echo "--- Setting Fish as default shell ---"
    chsh -s /usr/bin/fish
fi

# 8. Setting up ly display manager
echo "--- Enabling ly display manager ---"
sudo systemctl enable ly.service

echo "--- Install Complete ---"
echo "System will automatically reboot in 5 seconds..."
sleep 5
reboot
