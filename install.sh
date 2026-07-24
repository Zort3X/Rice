#!/usr/bin/env bash
#
# Gruvbox Rice Installer v4
# Usage:
#   ./install.sh                          interactive mode
#   ./install.sh --wm=hypr --gpu=amd --laptop --ssh --yes
#   ./install.sh --dotfiles-only --wm=hypr --laptop
#   ./install.sh --update --wm=hypr --gpu=amd --yes    (skip full -Syu)
#   ./install.sh --dry-run --wm=hypr --gpu=amd --laptop --ssh
#
set -euo pipefail

# --- Globals ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/install.log"
DOTFILES_ONLY=false
ASSUME_YES=false
UPDATE_MODE=false
DRY_RUN=false
SUDO_KEEPALIVE_PID=""
BACKUP_DIR=""

# --- Logging ---
log()      { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
log_warn() { echo "[$(date '+%H:%M:%S')] WARNING: $*" | tee -a "$LOG_FILE" >&2; }
log_err()  { echo "[$(date '+%H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2; }

error_handler() {
    local line=$1
    log_err "Script failed at line $line. See $LOG_FILE for full output."
    log_err "The system may be partially configured. Re-running is safe; already-applied steps will just be redone."
    exit 1
}
trap 'error_handler $LINENO' ERR

cleanup_on_exit() {
    [[ -n "$SUDO_KEEPALIVE_PID" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
}
trap cleanup_on_exit EXIT

# --- CLI parsing ---
print_help() {
    cat <<EOF
Gruvbox Rice Installer v4

Options:
  --wm=hypr|sway         Window manager
  --gpu=amd|nvidia|intel|vm   GPU driver set
  --laptop               Enable laptop profile (power tools)
  --ssh                  Install/enable SSH + Tailscale + fail2ban
  --dotfiles-only        Only re-sync dotfiles, skip package install/services
  --update               Skip full system upgrade (-Syu), just sync package/config state
  --dry-run              Show what would happen, make no changes to the system
  --yes                  Skip the confirmation prompt (unattended)
  -h, --help             Show this help

Old configs that get replaced are moved (not deleted) into a single
~/.rice-backup-<timestamp>/ directory so they're easy to find and wipe later.
EOF
}

for arg in "$@"; do
    case "$arg" in
        --wm=*)         wm_flag="${arg#*=}" ;;
        --gpu=*)        gpu_flag="${arg#*=}" ;;
        --laptop)       laptop_flag=true ;;
        --ssh)          ssh_flag=true ;;
        --dotfiles-only) DOTFILES_ONLY=true ;;
        --update)       UPDATE_MODE=true ;;
        --dry-run)      DRY_RUN=true ;;
        --yes)          ASSUME_YES=true ;;
        -h|--help)      print_help; exit 0 ;;
        *) log_warn "Unknown flag: $arg (ignored)" ;;
    esac
done

# --- Pre-flight checks ---
check_disk_space() {
    local avail_kb avail_gb
    avail_kb=$(df --output=avail / | tail -1)
    avail_gb=$((avail_kb / 1024 / 1024))
    if (( avail_gb < 5 )); then
        log_err "Only ${avail_gb}GB free on /. At least 5GB recommended for packages + AUR builds."
        exit 1
    fi
    log "Disk space OK (${avail_gb}GB free on /)."
}

check_sudo_group() {
    if ! groups "$USER" | grep -qE '\bwheel\b'; then
        log_warn "$USER is not in the 'wheel' group. sudo may fail below."
        log_warn "Fix (as root, before continuing): usermod -aG wheel $USER && reboot or re-login."
    fi
}

preflight() {
    log "--- Pre-flight checks ---"

    if [[ $EUID -eq 0 ]]; then
        log_err "Do not run this script as root. Run as your normal user; it will call sudo when needed."
        exit 1
    fi

    if [[ ! -d "$SCRIPT_DIR/.config" ]]; then
        log_err "No .config directory found next to this script ($SCRIPT_DIR). Are you running from inside the cloned repo?"
        exit 1
    fi

    if ! curl -sSf --max-time 5 https://archlinux.org >/dev/null 2>&1; then
        log_err "No network connectivity (couldn't reach archlinux.org). Check your connection and try again."
        exit 1
    fi

    if ! command -v pacman &> /dev/null; then
        log_err "pacman not found. This script is Arch-only."
        exit 1
    fi

    check_sudo_group
    $DOTFILES_ONLY || check_disk_space

    log "Pre-flight checks passed."
}

# --- Sudo: ask once, keep alive for the rest of the run ---
init_sudo() {
    log "Requesting sudo access (asked once — kept alive for the rest of the run)..."
    sudo -v
    ( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
    SUDO_KEEPALIVE_PID=$!
}

# --- Pacman keyring (only touches anything if it's actually uninitialized) ---
init_keyring() {
    if [[ -z "$(sudo pacman-key --list-keys 2>/dev/null)" ]]; then
        log "Pacman keyring looks uninitialized, setting it up..."
        sudo pacman-key --init
        sudo pacman-key --populate archlinux
    fi
}

# --- GPU auto-detect (informational warning only, never blocks) ---
detect_gpu() {
    command -v lspci &> /dev/null || { echo ""; return; }
    local info
    info=$(lspci 2>/dev/null | grep -Ei 'vga|3d|display' || true)
    if echo "$info" | grep -qi nvidia; then echo "nvidia"
    elif echo "$info" | grep -qi amd; then echo "amd"
    elif echo "$info" | grep -qi intel; then echo "intel"
    else echo ""
    fi
}

warn_gpu_mismatch() {
    local chosen="" detected
    case $gpu_choice in
        1) chosen="amd" ;;
        2) chosen="nvidia" ;;
        3) chosen="intel" ;;
        4) chosen="vm" ;;
    esac
    detected=$(detect_gpu)
    if [[ -n "$detected" && "$chosen" != "vm" && "$detected" != "$chosen" ]]; then
        log_warn "lspci detected a '$detected' GPU, but you selected '$chosen'. Double-check this matches your hardware before proceeding (see README hardware compatibility notes)."
    fi
}

# --- Setup Variables ---
ask_yn() {
    local prompt="$1" default="$2" answer
    while true; do
        read -rp "$prompt " answer
        answer="${answer:-$default}"
        case "$answer" in
            [Yy]) echo "y"; return ;;
            [Nn]) echo "n"; return ;;
            *) echo "Please answer y or n." >&2 ;;
        esac
    done
}

setup_vars() {
    log "--- Gruvbox Rice Installer ---"
    echo "!! NOTE: Tailscale requires manual 'tailscale up' after install !!"
    echo "!! First time running this? See 'Read This If You're Not Me' in README.md !!"

    if [[ -n "${wm_flag:-}" ]]; then
        case "$wm_flag" in
            hypr) wm_choice=1 ;;
            sway) wm_choice=2 ;;
            *) log_err "Invalid --wm value: $wm_flag (use hypr or sway)"; exit 1 ;;
        esac
    else
        while true; do
            read -rp "WM (1: Hyprland, 2: Sway): " wm_choice
            [[ "$wm_choice" == "1" || "$wm_choice" == "2" ]] && break
            echo "Please enter 1 or 2."
        done
    fi

    if [[ "${laptop_flag:-false}" == "true" ]]; then
        laptop_choice="y"
    else
        laptop_choice=$(ask_yn "Is this a laptop? (y/n):" "n")
    fi

    if ! $DOTFILES_ONLY; then
        if [[ -n "${gpu_flag:-}" ]]; then
            case "$gpu_flag" in
                amd) gpu_choice=1 ;;
                nvidia) gpu_choice=2 ;;
                intel) gpu_choice=3 ;;
                vm) gpu_choice=4 ;;
                *) log_err "Invalid --gpu value: $gpu_flag (use amd, nvidia, intel, or vm)"; exit 1 ;;
            esac
        else
            while true; do
                read -rp "GPU (1: AMD, 2: NVIDIA, 3: Intel, 4: VM): " gpu_choice
                [[ "$gpu_choice" =~ ^[1-4]$ ]] && break
                echo "Please enter a number 1-4."
            done
        fi
        warn_gpu_mismatch
    fi

    if [[ "${ssh_flag:-false}" == "true" ]]; then
        ssh_choice="y"
    elif ! $DOTFILES_ONLY; then
        ssh_choice=$(ask_yn "Install SSH & Tailscale? (y/n):" "n")
    else
        ssh_choice="n"
    fi

    [[ "$laptop_choice" =~ ^[Yy]$ ]] && profile="laptop" || profile="desktop"
    [[ "$wm_choice" == "1" ]] && wm="hypr" || wm="sway"
    [[ "$wm" == "hypr" ]] && term="alacritty" || term="foot"
}

confirm_selections() {
    echo
    log "--- Selections ---"
    local mode="Full install"
    $DOTFILES_ONLY && mode="Dotfiles only"
    $UPDATE_MODE && mode="Update (no full upgrade)"
    $DRY_RUN && mode="$mode [DRY RUN — no changes will be made]"
    echo "  Mode:      $mode"
    echo "  WM:        $wm"
    echo "  Profile:   $profile"
    echo "  Terminal:  $term"
    $DOTFILES_ONLY || echo "  GPU:       $gpu_choice (1=AMD 2=Nvidia 3=Intel 4=VM)"
    echo "  SSH/Tailscale: $ssh_choice"
    echo

    if ! $ASSUME_YES; then
        local proceed
        proceed=$(ask_yn "Proceed with these settings? (y/n):" "y")
        [[ "$proceed" == "y" ]] || { log "Aborted by user."; exit 0; }
    fi
}

# --- Build Package Lists ---
build_pkgs() {
    pkgs=(fish neovim tldr btop yazi udisks2 rofi-wayland waybar mako zen-browser-bin vesktop spotify-launcher pipemixer bluetui wifitui-bin ttf-profont-nerd bibata-cursor-theme-bin ly earlyoom zram-generator gamemode lib32-gamemode fastfetch cliphist irqbalance wl-clipboard 7zip curl)

    [[ "$ssh_choice" =~ ^[Yy]$ ]] && pkgs+=(openssh tailscale fail2ban)
    [[ "$wm" == "hypr" ]] && pkgs+=(hyprland hyprpaper hypridle hyprlock hyprshot xdg-desktop-portal-hyprland)
    [[ "$wm" == "sway" ]] && pkgs+=(swayfx swaybg swayidle swaylock-effects-git grim slurp xdg-desktop-portal-wlr autotiling)
    [[ "$profile" == "laptop" ]] && pkgs+=(tlp acpi_call tp_smapi brightnessctl acpi x86_energy_perf_policy)

    case $gpu_choice in
        1) pkgs+=(mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver) ;;
        2) pkgs+=(nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings egl-wayland libva-nvidia-driver) ;;
        3) pkgs+=(mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver libva-intel-driver libva-utils) ;;
        4) pkgs+=(mesa lib32-mesa) ;;
    esac
    pkgs+=("$term")
}

# --- Install & Cleanup ---
sys_init() {
    if $DRY_RUN; then
        log "[DRY-RUN] Would init pacman keyring (if needed), run $($UPDATE_MODE && echo 'pacman -S' || echo 'pacman -Syu') base-devel git, install yay if missing, then install ${#pkgs[@]} packages:"
        log "  ${pkgs[*]}"
        return
    fi

    init_keyring

    if $UPDATE_MODE; then
        log "--- Update mode: skipping full system upgrade ---"
        sudo pacman -S --needed --noconfirm base-devel git
    else
        log "--- Updating system & installing base tools ---"
        sudo pacman -Syu --needed --noconfirm base-devel git
    fi

    if ! command -v yay &> /dev/null; then
        log "Installing yay (AUR helper)..."
        local build_dir
        build_dir=$(mktemp -d)
        if ! git clone https://aur.archlinux.org/yay.git "$build_dir"; then
            log_err "Failed to clone yay repo."
            rm -rf "$build_dir"
            exit 1
        fi
        if ! (cd "$build_dir" && makepkg -si --noconfirm); then
            log_err "Failed to build/install yay."
            rm -rf "$build_dir"
            exit 1
        fi
        rm -rf "$build_dir"
    fi

    log "--- Installing packages (${#pkgs[@]} total) ---"
    if ! yay -S --needed --noconfirm "${pkgs[@]}"; then
        log_err "Package install failed. Check above for the specific package (AUR names can go stale/renamed)."
        exit 1
    fi
}

# --- GPU-specific configuration (Nvidia early KMS + env vars) ---
conf_gpu() {
    if [[ "$gpu_choice" == "2" ]]; then
        if $DRY_RUN; then
            log "[DRY-RUN] Would configure Nvidia early KMS modules and /etc/profile.d/nvidia.sh"
            return
        fi
        log "--- Configuring Nvidia ---"
        if [ -f /etc/mkinitcpio.conf ]; then
            sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
            sudo mkinitcpio -P
        fi
        sudo tee /etc/profile.d/nvidia.sh > /dev/null <<'EOF'
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export LIBVA_DRIVER_NAME=nvidia
EOF
        sudo chmod +x /etc/profile.d/nvidia.sh
    fi
}

# --- GRUB theme (only if GRUB is the active bootloader) ---
conf_grub() {
    if [ -f /etc/default/grub ] && command -v grub-mkconfig &> /dev/null; then
        if $DRY_RUN; then
            log "[DRY-RUN] GRUB detected — would install GRUB theme and update /etc/default/grub"
            return
        fi
        log "--- Installing GRUB Theme ---"
        local theme_dir
        theme_dir=$(mktemp -d)
        if git clone https://github.com/Blaysht/grub_bios_theme.git "$theme_dir"; then
            sudo mkdir -p /boot/grub/themes
            sudo cp -r "$theme_dir/OldBIOS" /boot/grub/themes/
            sudo sed -i 's/^GRUB_GFXMODE=.*/GRUB_GFXMODE=1920x1080,auto/' /etc/default/grub
            sudo sed -i 's|^#GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/OldBIOS/theme.txt"|' /etc/default/grub
            [[ "$gpu_choice" == "2" ]] && sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1 /' /etc/default/grub
            sudo grub-mkconfig -o /boot/grub/grub.cfg
        else
            log_warn "Could not clone GRUB theme repo, skipping theme (non-critical)."
        fi
        rm -rf "$theme_dir"
    else
        log "GRUB not detected as active bootloader, skipping theme."
    fi
}

# --- Backup helper: moves an existing path into one shared backup dir ---
backup_path() {
    local target="$1"
    [ -e "$target" ] || return 0

    if [[ -z "$BACKUP_DIR" ]]; then
        BACKUP_DIR="$HOME/.rice-backup-$(date '+%Y%m%d_%H%M%S')"
        mkdir -p "$BACKUP_DIR"
        log "Backing up replaced configs into $BACKUP_DIR (delete anytime: rm -rf ~/.rice-backup-*)"
    fi

    local rel="${target#"$HOME"/}"
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    mv "$target" "$BACKUP_DIR/$rel"
}

# --- Distribute dotfiles from the repo into ~/.config ---
distribute_dots() {
    if $DRY_RUN; then
        log "[DRY-RUN] Would back up existing ~/.config entries into ~/.rice-backup-<timestamp>/ and copy dotfiles for wm=$wm profile=$profile term=$term"
        return
    fi

    log "--- Distributing Dotfiles ---"
    mkdir -p ~/.config

    local core=(background btop fish mako rofi swaylock)
    core+=("$term")

    for app in "${core[@]}"; do
        backup_path "$HOME/.config/$app"
        if [ -d "$SCRIPT_DIR/.config/$app" ]; then
            cp -r "$SCRIPT_DIR/.config/$app" "$HOME/.config/$app"
        else
            log_warn "No .config/$app found in repo, skipping."
        fi
    done

    backup_path "$HOME/.config/fastfetch"
    if [ -d "$SCRIPT_DIR/.config/$profile/fastfetch" ]; then
        cp -r "$SCRIPT_DIR/.config/$profile/fastfetch" "$HOME/.config/fastfetch"
    fi

    if [[ "$wm" == "hypr" ]]; then
        backup_path "$HOME/.config/hypr"
        mkdir -p ~/.config/hypr
        for f in hyprland.conf hyprlock.conf hyprpaper.conf; do
            [ -f "$SCRIPT_DIR/.config/hypr/$f" ] && cp "$SCRIPT_DIR/.config/hypr/$f" "$HOME/.config/hypr/$f"
        done
        if [ -f "$SCRIPT_DIR/.config/$profile/hypr/hypridle.conf" ]; then
            cp "$SCRIPT_DIR/.config/$profile/hypr/hypridle.conf" "$HOME/.config/hypr/hypridle.conf"
        fi
        if [ -f "$SCRIPT_DIR/.config/$profile/hypr/monitor.conf" ]; then
            cp "$SCRIPT_DIR/.config/$profile/hypr/monitor.conf" "$HOME/.config/hypr/monitor.conf"
        else
            log_warn "No monitor.conf found for profile '$profile', Hyprland will fall back to its own auto-detection."
        fi
        backup_path "$HOME/.config/waybar"
        if [ -d "$SCRIPT_DIR/.config/$profile/waybar_hypr" ]; then
            cp -r "$SCRIPT_DIR/.config/$profile/waybar_hypr" "$HOME/.config/waybar"
        fi
    else
        backup_path "$HOME/.config/sway"
        mkdir -p ~/.config/sway
        [ -f "$SCRIPT_DIR/.config/sway/config" ] && cp "$SCRIPT_DIR/.config/sway/config" "$HOME/.config/sway/config"
        if [ -f "$SCRIPT_DIR/.config/$profile/sway/idle.conf" ]; then
            cp "$SCRIPT_DIR/.config/$profile/sway/idle.conf" "$HOME/.config/sway/idle.conf"
        else
            log_warn "No idle.conf found for profile '$profile', sway idle behavior will be undefined until you add one."
        fi
        backup_path "$HOME/.config/waybar"
        if [ -d "$SCRIPT_DIR/.config/$profile/waybar_sway" ]; then
            cp -r "$SCRIPT_DIR/.config/$profile/waybar_sway" "$HOME/.config/waybar"
        fi
    fi
}

cleanup_system() {
    log "--- Checking for orphaned packages ---"
    local orphans
    orphans=$(pacman -Qdtq 2>/dev/null || true)
    if [[ -n "$orphans" ]]; then
        if $DRY_RUN; then
            log "[DRY-RUN] Would remove orphans: $orphans"
        else
            sudo pacman -Rns --noconfirm $orphans
        fi
    else
        log "No orphaned packages."
    fi
}

# --- Configurations (Services) ---
conf_services() {
    if $DRY_RUN; then
        log "[DRY-RUN] Would enable services, configure ufw, write zram config, set up fish/Fisher, chsh to fish"
        return
    fi

    log "--- Configuring Services ---"

    sudo systemctl disable getty@tty1.service 2>/dev/null || true
    sudo systemctl enable NetworkManager ufw earlyoom irqbalance udisks2 ly@tty1.service

    [[ "$profile" == "laptop" ]] && sudo systemctl enable tlp
    if [[ "$ssh_choice" =~ ^[Yy]$ ]]; then
        sudo systemctl enable sshd tailscaled fail2ban
    fi

    log "--- Configuring UFW ---"
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    if [[ "$ssh_choice" =~ ^[Yy]$ ]]; then
        sudo ufw allow ssh
        sudo ufw allow 41641/udp # Tailscale
    fi
    sudo ufw --force enable

    sudo tee /etc/systemd/zram-generator.conf > /dev/null <<'EOF'
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
EOF

    log "--- Configuring Fish Shell ---"
    if ! fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"; then
        log_warn "Fisher install failed (network issue?). Retry manually: fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'"
    elif ! fish -c "fisher install franciscolourenco/done"; then
        log_warn "Fisher plugin 'done' failed to install. Retry manually: fish -c 'fisher install franciscolourenco/done'"
    fi

    sudo chsh -s /usr/bin/fish "$USER"
}

# --- Post-install verification: did the important stuff actually take? ---
check_install() {
    log "--- Post-Install Verification ---"
    local all_ok=true

    local svc_list=(NetworkManager ufw earlyoom irqbalance udisks2 ly@tty1.service)
    [[ "$profile" == "laptop" ]] && svc_list+=(tlp)
    [[ "$ssh_choice" =~ ^[Yy]$ ]] && svc_list+=(sshd tailscaled fail2ban)

    for svc in "${svc_list[@]}"; do
        if systemctl is-enabled --quiet "$svc" 2>/dev/null; then
            echo "  [OK]   $svc enabled"
        else
            echo "  [FAIL] $svc not enabled"
            all_ok=false
        fi
    done

    local bins=(fish waybar "$term")
    [[ "$wm" == "hypr" ]] && bins+=(Hyprland) || bins+=(sway)
    for b in "${bins[@]}"; do
        if command -v "$b" &> /dev/null; then
            echo "  [OK]   $b found on PATH"
        else
            echo "  [FAIL] $b not found on PATH"
            all_ok=false
        fi
    done

    if $all_ok; then
        log "All post-install checks passed."
    else
        log_warn "Some checks above failed — review them. The install may still mostly work, but those items need a manual look."
    fi
}

# --- Main Flow ---
{
    echo ""
    echo "===================================================================="
    echo "Run started: $(date)"
    echo "===================================================================="
} >> "$LOG_FILE"

preflight
setup_vars
confirm_selections

if $DOTFILES_ONLY; then
    distribute_dots
    if $DRY_RUN; then
        log "--- Dry run complete. No changes were made. ---"
    else
        log "--- Dotfiles synced. No packages or services were touched. ---"
        [[ -n "$BACKUP_DIR" ]] && log "Old configs saved to: $BACKUP_DIR"
    fi
    exit 0
fi

$DRY_RUN || init_sudo
build_pkgs
sys_init
conf_gpu
conf_grub
distribute_dots
cleanup_system
conf_services

if $DRY_RUN; then
    log "--- Dry run complete. No changes were made to the system. ---"
    exit 0
fi

check_install

log "--- Installation Complete ---"
[[ -n "$BACKUP_DIR" ]] && log "Old configs saved to: $BACKUP_DIR (delete anytime with: rm -rf ~/.rice-backup-*)"

echo
echo "Post-install checklist:"
if [[ "$wm" == "hypr" ]]; then
    echo "  1. Monitor resolution — check ~/.config/hypr/monitor.conf"
    echo "     (find your real output name/modes with: hyprctl monitors all)"
else
    echo "  1. Monitor resolution — check ~/.config/sway/config (Sway auto-detects by default)"
    echo "     (find your real output name/modes with: swaymsg -t get_outputs)"
fi
echo "  2. Keyboard layout — confirm in the WM input section (default: us,bg)"
echo "  3. Appearance — check cursor theme and GTK settings for consistency"
echo

echo "You can now safely remove this Rice directory if desired."
reboot_choice=$(ask_yn "Reboot now? (y/n):" "n")
[[ "$reboot_choice" == "y" ]] && reboot
