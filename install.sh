#!/usr/bin/env bash

set -e

# Interactive Setup
setup_vars() {
    echo "--- Gruvbox Rice Installer ---"
    echo "!! WARNING: Verify drivers in script before proceeding !!"
    echo "!! NOTE: Tailscale requires manual 'tailscale up' after install !!"
    
    read -p "WM (1: Hypr, 2: Sway): " wm
    read -p "Laptop (y/n): " laptop
    read -p "GPU (1: AMD, 2: NVIDIA, 3: Intel, 4: VM): " gpu
    read -p "Install SSH (y/n): " ssh_choice
    
    [[ $wm == "1" ]] && term="alacritty" || term="foot"
    [[ $laptop == "y" || $laptop == "Y" ]] && profile="laptop" || profile="desktop"
    
    echo "- Setup variables initialized: true"
}

build_pkgs() {
    base=(fish neovim tldr btop yazi udisks2 rofi-wayland waybar mako zen-browser-bin vesktop spotify-launcher bluetui wifitui-bin ttf-profont-nerd bibata-cursor-theme-bin ly earlyoom zram-generator gamemode lib32-gamemode fastfetch cliphist irqbalance wl-clipboard 7zip tailscale fail2ban)
    hypr=(hyprland hyprpaper hypridle hyprlock hyprshot xdg-desktop-portal-hyprland)
    sway=(swayfx swaybg swayidle swaylock-effects-git grim slurp xdg-desktop-portal-wlr autotiling)
    port=(tlp acpi_call tp_smapi brightnessctl acpi x86_energy_perf_policy)
    amd=(mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau)
    nv=(nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings egl-wayland libva-nvidia-driver)
    intel=(mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver libva-intel-driver libva-utils)

    list=("${base[@]}")
    [[ $wm == "1" ]] && list+=("${hypr[@]}") || list+=("${sway[@]}")
    [[ $ssh_choice == "y" || $ssh_choice == "Y" ]] && list+=("openssh")
    list+=("$term")
    [[ $profile == "laptop" ]] && list+=("${port[@]}")
    
    case $gpu in
        1) list+=("${amd[@]}") ;;
        2) list+=("${nv[@]}") ;;
        3) list+=("${intel[@]}") ;;
        *) list+=("mesa" "lib32-mesa") ;;
    esac
    
    echo "- Package list built: true"
}

sys_init() {
    sudo pacman -Syu --noconfirm
    sudo pacman -S --needed --noconfirm base-devel git
    
    if ! command -v yay &> /dev/null; then
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay && makepkg -si --noconfirm
        cd - && rm -rf /tmp/yay
    fi
    
    yay -S --needed --noconfirm "${list[@]}"
    echo "- System base initialized: true"
}

conf_gpu() {
    if [[ $gpu == "2" ]]; then
        if [ -f /etc/mkinitcpio.conf ]; then
            sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
            sudo mkinitcpio -P
        fi
        sudo tee /etc/profile.d/nvidia.sh <<EOF
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export LIBVA_DRIVER_NAME=nvidia
EOF
        sudo chmod +x /etc/profile.d/nvidia.sh
    fi
    echo "- GPU configuration applied: true"
}

conf_grub() {
    if [ -f /etc/default/grub ]; then
        echo "--- Installing OldBIOS GRUB Theme ---"
        rm -rf /tmp/grub_theme
        git clone https://github.com/Blaysht/grub_bios_theme.git /tmp/grub_theme
        sudo mkdir -p /boot/grub/themes
        sudo cp -r /tmp/grub_theme/OldBIOS /boot/grub/themes/
        
        sudo sed -i 's/^GRUB_GFXMODE=.*/GRUB_GFXMODE=1920x1080,auto/' /etc/default/grub
        sudo sed -i 's|^#GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/OldBIOS/theme.txt"|' /etc/default/grub
        [[ $gpu == "2" ]] && sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1 /' /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
    echo "- GRUB configuration applied: true"
}

link_dots() {
    dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    mkdir -p ~/.config
    
    core=(alacritty background btop fastfetch fish foot mako rofi swaylock)
    for app in "${core[@]}"; do
        rm -rf "$HOME/.config/$app"
        ln -s "$dir/.config/$app" "$HOME/.config/$app"
    done
    
    if [[ $wm == "1" ]]; then
        rm -rf "$HOME/.config/hypr" && mkdir -p ~/.config/hypr
        ln -s "$dir/.config/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
        ln -s "$dir/.config/hypr/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf"
        ln -s "$dir/.config/hypr/hyprpaper.conf" "$HOME/.config/hypr/hyprpaper.conf"
        ln -s "$dir/.config/$profile/hypr/hypridle.conf" "$HOME/.config/hypr/hypridle.conf"
        rm -rf "$HOME/.config/waybar"
        ln -s "$dir/.config/$profile/waybar_hypr" "$HOME/.config/waybar"
    else
        rm -rf "$HOME/.config/sway" && mkdir -p ~/.config/sway
        ln -s "$dir/.config/sway/config" "$HOME/.config/sway/config"
        # Removed swaylock.sh script linking
        rm -rf "$HOME/.config/waybar"
        ln -s "$dir/.config/$profile/waybar_sway" "$HOME/.config/waybar"
    fi
    echo "- Configuration linking successful: true"
}

conf_services() {
    # Clean service enablement list
    sudo systemctl enable NetworkManager ufw earlyoom irqbalance gamemoded udisks2 ly
    
    # UFW Configuration
    echo "--- Configuring UFW Security ---"
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 41641/udp # Tailscale
    sudo ufw --force enable
    
    # Display Manager Setup
    sudo systemctl disable getty@tty1.service
    
    [[ $profile == "laptop" ]] && sudo systemctl enable tlp
    [[ $ssh_choice == "y" || $ssh_choice == "Y" ]] && sudo systemctl enable sshd
    
    sudo tee /etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
EOF
    
    echo "--- Configuring Fish Shell ---"
    sudo pacman -S --needed --noconfirm curl
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
    fish -c "fisher install franciscolourenco/done"
    
    sudo chsh -s /usr/bin/fish $USER
    
    # Cleanup temp build files
    rm -rf /tmp/yay /tmp/grub_theme
    echo "- Services and shell configured (Temp cleaned): true"
}

setup_vars
build_pkgs
sys_init
conf_gpu
conf_grub
link_dots
conf_services

echo "--- Install Successful: true ---"
sleep 2 && reboot
