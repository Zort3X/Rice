#!/usr/bin/env bash

# Stop on error, exit if any command fails
set -e

# --- Setup Variables ---
setup_vars() {
    echo "--- Gruvbox Rice Installer ---"
    read -p "WM (1: Hyprland, 2: Sway): " wm_choice
    read -p "Is this a laptop? (y/n): " laptop_choice
    read -p "GPU (1: AMD, 2: NVIDIA, 3: Intel, 4: VM): " gpu_choice
    read -p "Install SSH & Tailscale? (y/n): " ssh_choice
    
    # Logic for profiles
    [[ "$laptop_choice" =~ ^[Yy]$ ]] && profile="laptop" || profile="desktop"
    [[ "$wm_choice" == "1" ]] && wm="hypr" || wm="sway"
    [[ "$wm" == "hypr" ]] && term="alacritty" || term="foot"
}

# --- Build Package Lists ---
build_pkgs() {
    # Base packages
    pkgs=(fish neovim tldr btop yazi udisks2 rofi-wayland mako zen-browser-bin vesktop spotify-launcher pipemixer bluetui wifitui-bin ttf-profont-nerd bibata-cursor-theme-bin ly earlyoom zram-generator gamemode lib32-gamemode fastfetch cliphist irqbalance wl-clipboard 7zip)
    
    # Conditional logic
    [[ "$ssh_choice" =~ ^[Yy]$ ]] && pkgs+=(openssh tailscale)
    [[ "$wm" == "hypr" ]] && pkgs+=(hyprland hyprpaper hypridle hyprlock hyprshot xdg-desktop-portal-hyprland)
    [[ "$wm" == "sway" ]] && pkgs+=(swayfx swaybg swayidle swaylock-effects-git grim slurp xdg-desktop-portal-wlr autotiling)
    [[ "$profile" == "laptop" ]] && pkgs+=(tlp acpi_call tp_smapi brightnessctl acpi x86_energy_perf_policy)
    
    case $gpu_choice in
        1) pkgs+=(mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver) ;;
        2) pkgs+=(nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings egl-wayland libva-nvidia-driver) ;;
        3) pkgs+=(mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver libva-intel-driver libva-utils) ;;
    esac
    pkgs+=("$term")
}

# --- Install & Cleanup ---
sys_init() {
    sudo pacman -Syu --needed --noconfirm base-devel git
    
    # Safe install of yay using mktemp
    if ! command -v yay &> /dev/null; then
        local build_dir=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$build_dir"
        (cd "$build_dir" && makepkg -si --noconfirm)
        rm -rf "$build_dir"
    fi
    
    yay -S --needed "${pkgs[@]}"
}

cleanup_system() {
    echo "--- Cleaning orphans ---"
    local orphans=$(pacman -Qdtq)
    if [[ -n "$orphans" ]]; then
        sudo pacman -Rns --noconfirm $orphans
    fi
}

# --- Configurations (Services) ---
conf_services() {
    sudo systemctl enable NetworkManager ufw earlyoom irqbalance udisks2 ly@tty1.service
    
    [[ "$profile" == "laptop" ]] && sudo systemctl enable tlp
    [[ "$ssh_choice" =~ ^[Yy]$ ]] && sudo systemctl enable sshd tailscaled
    
    # UFW
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    [[ "$ssh_choice" =~ ^[Yy]$ ]] && sudo ufw allow ssh
    sudo ufw --force enable
    
    # ZRAM
    echo "zram-size = min(ram / 2, 4096)" | sudo tee /etc/systemd/zram-generator.conf > /dev/null
    
    # Shell
    sudo chsh -s /usr/bin/fish "$USER"
}

# --- Main Flow ---
setup_vars
build_pkgs
sys_init
cleanup_system
conf_services

echo "--- Installation Complete ---"
read -p "Reboot now? (y/n): " reboot_choice
[[ "$reboot_choice" =~ ^[Yy]$ ]] && reboot
