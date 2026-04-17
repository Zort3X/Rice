#!/usr/bin/env bash

# Interactive Surgical Gruvbox Installer
# High-performance setup for Hyprland/SwayFX based on user choices.

set -e

echo "--- Starting Interactive Surgical Install ---"
echo "!! WARNING !!"
echo "Before proceeding, please verify the packages and drivers defined in this script."
echo "Each system is unique; ensure these drivers match your specific hardware."
echo "If you're unsure, check 'lspci' or 'lsusb' output first."
echo "Press ENTER to acknowledge and continue, or CTRL+C to abort."
read -r

# 1. Interactive Configuration Questions
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

# 2. Building the Package Lists
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
    swayfx swaybg swayidle swaylock-effects-git grim slurp jq 
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

# Add Terminal specific packages
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

# 3. Base dependencies
echo "--- Updating System and Installing Base Dependencies ---"
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm base-devel git

# 4. Install yay
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

# 6. Post-Installation Configuration
DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# NVIDIA Specific Configuration
if [[ $gpu_choice == "2" ]]; then
    echo "--- Performing NVIDIA Post-Install Setup ---"
    if [ -f /etc/mkinitcpio.conf ]; then
        sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
        sudo mkinitcpio -P
    fi
    sudo tee /etc/profile.d/nvidia-wayland.sh <<EOF
export GB_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
EOF
    sudo chmod +x /etc/profile.d/nvidia-wayland.sh
fi

# GRUB Configuration
if [ -f /etc/default/grub ]; then
    echo "--- Configuring GRUB Theme and Parameters ---"
    if [ -d "$DOTS_DIR/grub_bios_theme/OldBIOS" ]; then
        sudo mkdir -p /boot/grub/themes
        sudo cp -r "$DOTS_DIR/grub_bios_theme/OldBIOS" /boot/grub/themes/
        sudo sed -i 's|^#GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/OldBIOS/theme.txt"|' /etc/default/grub
        if ! grep -q "^GRUB_THEME=" /etc/default/grub; then
            echo 'GRUB_THEME="/boot/grub/themes/OldBIOS/theme.txt"' | sudo tee -a /etc/default/grub
        fi
    fi
    sudo sed -i 's/^GRUB_GFXMODE=.*/GRUB_GFXMODE=1920x1080,auto/' /etc/default/grub
    if [[ $gpu_choice == "2" ]]; then
        if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
            sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1 /' /etc/default/grub
        fi
    fi
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# 7. Linking Configurations
echo "--- Linking Configurations ---"
mkdir -p ~/.config

# Profile Determination
if [[ $laptop_choice == "y" || $laptop_choice == "Y" ]]; then
    PROFILE="laptop"
else
    PROFILE="desktop"
fi

# Link Core Configs (Apps that don't change between profiles)
CORE_APPS=(fish rofi mako btop alacritty foot swaylock)
for app in "${CORE_APPS[@]}"; do
    if [ -d "$HOME/.config/$app" ]; then
        echo "Backing up existing $app..."
        mv "$HOME/.config/$app" "$HOME/.config/${app}.bak"
    fi
    ln -s "$DOTS_DIR/.config/$app" "$HOME/.config/$app"
done

# Profile Specific (Fastfetch)
if [ -d "$HOME/.config/fastfetch" ]; then
    mv "$HOME/.config/fastfetch" "$HOME/.config/fastfetch.bak"
fi
ln -s "$DOTS_DIR/.config/$PROFILE/fastfetch" "$HOME/.config/fastfetch"

# WM Selection
if [[ $wm_choice == "1" ]]; then
    # Hyprland Setup
    echo "--- Setting up Hyprland ---"
    if [ -d "$HOME/.config/hypr" ]; then
        mv "$HOME/.config/hypr" "$HOME/.config/hypr.bak"
    fi
    mkdir -p ~/.config/hypr
    ln -s "$DOTS_DIR/.config/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
    ln -s "$DOTS_DIR/.config/hypr/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf"
    ln -s "$DOTS_DIR/.config/hypr/hyprpaper.conf" "$HOME/.config/hypr/hyprpaper.conf"
    ln -s "$DOTS_DIR/.config/$PROFILE/hypr/hypridle.conf" "$HOME/.config/hypr/hypridle.conf"
    
    if [ -d "$HOME/.config/waybar" ]; then
        mv "$HOME/.config/waybar" "$HOME/.config/waybar.bak"
    fi
    ln -s "$DOTS_DIR/.config/$PROFILE/waybar_hypr" "$HOME/.config/waybar"
else
    # Sway Setup
    echo "--- Setting up SwayFX ---"
    if [ -d "$HOME/.config/sway" ]; then
        mv "$HOME/.config/sway" "$HOME/.config/sway.bak"
    fi
    mkdir -p ~/.config/sway
    ln -s "$DOTS_DIR/.config/sway/config" "$HOME/.config/sway/config"
    ln -s "$DOTS_DIR/.config/sway/swaylock.sh" "$HOME/.config/sway/swaylock.sh" # Legacy script support
    ln -s "$DOTS_DIR/.config/$PROFILE/sway/swayidle.sh" "$HOME/.config/sway/swayidle.sh"
    chmod +x "$HOME/.config/sway/swayidle.sh"
    
    if [ -d "$HOME/.config/waybar" ]; then
        mv "$HOME/.config/waybar" "$HOME/.config/waybar.bak"
    fi
    ln -s "$DOTS_DIR/.config/$PROFILE/waybar_sway" "$HOME/.config/waybar"
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
