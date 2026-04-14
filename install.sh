#!/usr/bin/env bash

# Interactive Surgical Gruvbox Installer
# High-performance setup for Hyprland/SwayFX based on user choices.

set -e

echo "--- Starting Interactive Surgical Install ---"

# 1. Interactive Configuration Questions (FRONT-LOADED)
echo ""
echo "--- Installation Options ---"
read -p "Choose your Window Manager (1: Hyprland, 2: SwayFX): " wm_choice
read -p "Are you on a Laptop? (y/n): " laptop_choice
read -p "Choose your GPU (1: AMD, 2: NVIDIA, 3: Intel, 4: Generic/VM): " gpu_choice

# Auto-set Terminal based on WM choice
if [[ $wm_choice == "1" ]]; then
    term_choice="1" # Alacritty for Hyprland
else
    term_choice="2" # Foot for Sway
fi

# 2. Building the Package Lists (PRE-PROCESS)
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
    swayfx swaybg swayidle swaylock grim slurp jq 
    xdg-desktop-portal-wlr autotiling
)

PACKAGES_LAPTOP=(
    tlp acpi_call tp_smapi brightnessctl acpi
)

PACKAGES_AMD=(
    mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon 
    libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau
)

PACKAGES_NVIDIA=(
    nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings 
    egl-wayland libva-nvidia-driver
)

PACKAGES_INTEL=(
    mesa lib32-mesa vulkan-intel lib32-vulkan-intel 
    intel-media-driver libva-intel-driver libva-utils
)

# Initialize final install list
FINAL_PACKAGES=("${PACKAGES_GLOBAL[@]}")

# Add WM specific packages
if [[ $wm_choice == "1" ]]; then
    echo "--- Selecting Hyprland packages ---"
    FINAL_PACKAGES+=("${PACKAGES_HYPRLAND[@]}")
elif [[ $wm_choice == "2" ]]; then
    echo "--- Selecting SwayFX packages ---"
    FINAL_PACKAGES+=("${PACKAGES_SWAY[@]}")
fi

# Add Terminal specific packages (Assigned automatically)
if [[ $term_choice == "1" ]]; then
    echo "--- Selecting Alacritty (Hyprland default) ---"
    FINAL_PACKAGES+=("alacritty")
elif [[ $term_choice == "2" ]]; then
    echo "--- Selecting Foot (Sway default) ---"
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
        echo "--- Selecting NVIDIA GPU packages ---"
        FINAL_PACKAGES+=("${PACKAGES_NVIDIA[@]}")
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

# 3. Base dependencies for building and AUR access
echo "--- Updating System and Installing Base Dependencies ---"
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm base-devel git

# 4. Install yay (AUR Helper) if not present
if ! command -v yay &> /dev/null; then
    echo "--- Installing yay ---"
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/yay
fi

# 5. Final Installation Execution
echo "--- Installing Selected Packages ---"
yay -S --needed --noconfirm "${FINAL_PACKAGES[@]}"

# 6. NVIDIA Specific Configuration
if [[ $gpu_choice == "2" ]]; then
    echo "--- Performing NVIDIA Post-Install Setup ---"
    
    # Kernel Parameters (Targeting GRUB)
    if [ -f /etc/default/grub ]; then
        echo "Updating GRUB kernel parameters..."
        if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
            sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1 /' /etc/default/grub
            sudo grub-mkconfig -o /boot/grub/grub.cfg
        fi
    fi

    # mkinitcpio modules
    if [ -f /etc/mkinitcpio.conf ]; then
        echo "Updating mkinitcpio modules..."
        sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
        sudo mkinitcpio -P
    fi

    # Environment Variables for Wayland/NVIDIA
    echo "Setting up NVIDIA environment variables..."
    sudo tee /etc/profile.d/nvidia-wayland.sh <<EOF
export GB_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
EOF
    sudo chmod +x /etc/profile.d/nvidia-wayland.sh
fi

# 7. Linking Configurations
echo "--- Linking Configurations ---"
DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p ~/.config

# Dynamically link based on selection
CONFIGS=(fish rofi mako fastfetch btop)

[[ $wm_choice == "1" ]] && CONFIGS+=(hypr)
[[ $wm_choice == "2" ]] && CONFIGS+=(sway)
[[ $term_choice == "1" ]] && CONFIGS+=(alacritty)
[[ $term_choice == "2" ]] && CONFIGS+=(foot)

for config in "${CONFIGS[@]}"; do
    if [ -d "$HOME/.config/$config" ]; then
        echo "Backing up existing $config..."
        mv "$HOME/.config/$config" "$HOME/.config/${config}.bak"
    fi
    ln -s "$DOTS_DIR/.config/$config" "$HOME/.config/$config"
done

# Handle Waybar Desktop/Laptop config (WM specific)
if [ -d "$HOME/.config/waybar" ]; then
    echo "Backing up existing waybar..."
    mv "$HOME/.config/waybar" "$HOME/.config/waybar.bak"
fi

if [[ $wm_choice == "2" ]]; then
    # Sway Waybar
    if [[ $laptop_choice == "y" || $laptop_choice == "Y" ]]; then
        echo "--- Setting Sway Waybar Laptop config ---"
        ln -s "$DOTS_DIR/.config/sway_waybar_laptop" "$HOME/.config/waybar"
    else
        echo "--- Setting Sway Waybar Desktop config ---"
        ln -s "$DOTS_DIR/.config/sway_waybar_desktop" "$HOME/.config/waybar"
    fi
else
    # Hyprland Waybar
    if [[ $laptop_choice == "y" || $laptop_choice == "Y" ]]; then
        echo "--- Setting Hyprland Waybar Laptop config ---"
        ln -s "$DOTS_DIR/.config/waybar_laptop" "$HOME/.config/waybar"
    else
        echo "--- Setting Hyprland Waybar Desktop config ---"
        ln -s "$DOTS_DIR/.config/waybar_desktop" "$HOME/.config/waybar"
    fi
fi

# 8. Setting Fish as default shell
if [[ $SHELL != "/usr/bin/fish" ]]; then
    echo "--- Setting Fish as default shell ---"
    chsh -s /usr/bin/fish
fi

# 9. Setting up ly display manager
echo "--- Enabling ly display manager ---"
sudo systemctl enable ly.service

echo "--- Install Complete ---"
echo "System will automatically reboot in 5 seconds..."
sleep 5
reboot
