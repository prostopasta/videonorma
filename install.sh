#!/usr/bin/env bash
# videonorma installer — cross-distro, self-contained
# Tested: Ubuntu 22.04+, Debian 12+, Fedora 38+, Arch Linux, openSUSE Tumbleweed
# Requires: bash 4+, internet access (to install ffmpeg-normalize via pipx)
#
# Usage: bash install.sh [--cli-only]
#   --cli-only   Install CLI tool only, skip file manager integration

set -euo pipefail

CLI_ONLY=false
[[ "${1:-}" == "--cli-only" ]] && CLI_ONLY=true

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[info]${RESET}  $*"; }
ok()      { echo -e "${GREEN}[ok]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[warn]${RESET}  $*"; }
die()     { echo -e "${RED}[error]${RESET} $*" >&2; exit 1; }
section() { echo -e "\n${BOLD}── $* ──${RESET}"; }

# ── Detect package manager ────────────────────────────────────────────────────
detect_pm() {
    if   command -v apt-get &>/dev/null; then echo "apt"
    elif command -v dnf     &>/dev/null; then echo "dnf"
    elif command -v pacman  &>/dev/null; then echo "pacman"
    elif command -v zypper  &>/dev/null; then echo "zypper"
    else echo "unknown"
    fi
}

PM=$(detect_pm)
[[ "$PM" == "unknown" ]] && die "No supported package manager found (apt/dnf/pacman/zypper). Install dependencies manually."

# ── Package name map per distro ───────────────────────────────────────────────
pkg_ffmpeg()      { case $PM in apt) echo "ffmpeg";; dnf) echo "ffmpeg";; pacman) echo "ffmpeg";; zypper) echo "ffmpeg";; esac; }
pkg_pipx()        { case $PM in apt) echo "pipx";; dnf) echo "pipx";; pacman) echo "python-pipx";; zypper) echo "python3-pipx";; esac; }
pkg_notify()      { case $PM in apt) echo "libnotify-bin";; dnf) echo "libnotify";; pacman) echo "libnotify";; zypper) echo "libnotify-tools";; esac; }
pkg_xdg()         { case $PM in apt) echo "xdg-utils";; dnf) echo "xdg-utils";; pacman) echo "xdg-utils";; zypper) echo "xdg-utils";; esac; }
pkg_zenity()      { case $PM in apt) echo "zenity";; dnf) echo "zenity";; pacman) echo "zenity";; zypper) echo "zenity";; esac; }

install_pkg() {
    local pkg="$1"
    info "Installing $pkg..."
    case $PM in
        apt)    sudo apt-get install -y "$pkg" -qq ;;
        dnf)    sudo dnf install -y "$pkg" -q ;;
        pacman) sudo pacman -S --noconfirm "$pkg" ;;
        zypper) sudo zypper install -y "$pkg" >/dev/null ;;
    esac
}

check_or_install() {
    local cmd="$1" pkg="$2" required="${3:-required}"
    if command -v "$cmd" &>/dev/null; then
        ok "$cmd found ($(command -v "$cmd"))"
    elif [[ "$required" == "required" ]]; then
        warn "$cmd not found — installing $(bold "$pkg")..."
        install_pkg "$pkg"
        ok "$cmd installed"
    else
        warn "$cmd not found — optional, skipping (install $pkg manually if needed)"
    fi
}

bold() { echo -e "${BOLD}$*${RESET}"; }

# ── Detect file manager ───────────────────────────────────────────────────────
detect_file_manager() {
    if   command -v nautilus &>/dev/null; then echo "nautilus"
    elif command -v nemo     &>/dev/null; then echo "nemo"
    elif command -v caja     &>/dev/null; then echo "caja"
    elif command -v dolphin  &>/dev/null; then echo "dolphin"
    elif command -v thunar   &>/dev/null; then echo "thunar"
    else echo "unknown"
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}videonorma installer${RESET}"
echo "─────────────────────────────────────────────"
info "Package manager : $PM"
info "CLI-only mode   : $CLI_ONLY"

section "Checking required dependencies"

# ffmpeg — required
check_or_install ffmpeg "$(pkg_ffmpeg)" required

# On Fedora, ffmpeg may not be in default repos (needs RPM Fusion)
if [[ "$PM" == "dnf" ]] && ! command -v ffmpeg &>/dev/null; then
    warn "ffmpeg not found after install attempt."
    warn "On Fedora/RHEL you may need RPM Fusion:"
    warn "  sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-\$(rpm -E %fedora).noarch.rpm"
    warn "  sudo dnf install -y ffmpeg"
    die "Please install ffmpeg manually and re-run this script."
fi

# pipx — required
check_or_install pipx "$(pkg_pipx)" required

# Ensure pipx path is set up
pipx ensurepath --force >/dev/null 2>&1 || true

section "Installing ffmpeg-normalize"
if command -v ffmpeg-normalize &>/dev/null; then
    ok "ffmpeg-normalize already installed ($(ffmpeg-normalize --version 2>&1 | head -1))"
else
    info "Installing ffmpeg-normalize via pipx..."
    pipx install ffmpeg-normalize
    ok "ffmpeg-normalize installed"
fi

section "Installing normalize-audio CLI"
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/normalize-audio" "$INSTALL_DIR/normalize-audio"
chmod +x "$INSTALL_DIR/normalize-audio"
ok "normalize-audio → $INSTALL_DIR/normalize-audio"

# Ensure ~/.local/bin is in PATH
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    warn "$INSTALL_DIR is not in PATH. Adding to ~/.bashrc and ~/.profile..."
    for RC in "$HOME/.bashrc" "$HOME/.profile"; do
        # shellcheck disable=SC2016  # single quotes intentional: $HOME must expand at shell load, not now
        grep -qxF "export PATH=\"\$HOME/.local/bin:\$PATH\"" "$RC" 2>/dev/null || \
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RC"
    done
    export PATH="$INSTALL_DIR:$PATH"
    warn "Restart your terminal (or run: source ~/.bashrc) to use normalize-audio"
fi

# ── Optional: file manager integration ───────────────────────────────────────
if [[ "$CLI_ONLY" == "true" ]]; then
    section "Skipping file manager integration (--cli-only)"
else
    section "Checking optional dependencies (file manager integration)"
    check_or_install notify-send "$(pkg_notify)"  optional
    check_or_install xdg-open   "$(pkg_xdg)"      optional
    check_or_install zenity      "$(pkg_zenity)"   optional

    section "File manager integration"
    FM=$(detect_file_manager)
    info "Detected file manager: $FM"

    install_fm_script() {
        local scripts_dir="$1"
        local script_name="$2"
        mkdir -p "$scripts_dir"
        cat > "$scripts_dir/$script_name" << 'FMSCRIPT'
#!/usr/bin/env bash
# videonorma: file manager script — normalize selected file and open in player
# Works in: Nautilus (GNOME), Nemo (Cinnamon), Caja (MATE)

# Each file manager uses a different env var for selected files
INPUT="${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-${NEMO_SCRIPT_SELECTED_FILE_PATHS:-${CAJA_SCRIPT_SELECTED_FILE_PATHS:-}}}"
INPUT=$(echo "$INPUT" | head -1 | tr -d '\n')

if [[ -z "$INPUT" ]]; then
    if command -v zenity &>/dev/null; then
        zenity --error --text="No file selected." 2>/dev/null || true
    fi
    exit 1
fi

DIR=$(dirname "$INPUT")
BASE=$(basename "$INPUT")
EXT="${BASE##*.}"
NAME="${BASE%.*}"
OUTPUT="$DIR/${NAME}_normalized.${EXT}"

notify() {
    if command -v notify-send &>/dev/null; then
        notify-send "videonorma" "$1" -i video-x-generic -t "${2:-4000}"
    fi
}

open_file() {
    if command -v xdg-open &>/dev/null; then
        xdg-open "$1" &
    fi
}

if [[ -f "$OUTPUT" ]]; then
    notify "Already normalized — opening." 3000
    open_file "$OUTPUT"
    exit 0
fi

notify "Normalizing: $BASE\nThis may take ~30s..." 6000

(
    normalize-audio "$INPUT" > /tmp/videonorma_last.log 2>&1
    if [[ $? -eq 0 ]]; then
        notify "Done: ${NAME}_normalized.${EXT}" 5000
        open_file "$OUTPUT"
    else
        notify "Error during normalization. See /tmp/videonorma_last.log" 8000
    fi
) &
FMSCRIPT
        chmod +x "$scripts_dir/$script_name"
        ok "Installed: $scripts_dir/$script_name"
    }

    case "$FM" in
        nautilus)
            install_fm_script "$HOME/.local/share/nautilus/scripts" "▶ Play normalized"
            info "Right-click a video → Scripts → ▶ Play normalized"
            ;;
        nemo)
            install_fm_script "$HOME/.local/share/nemo/scripts" "▶ Play normalized"
            info "Right-click a video → Scripts → ▶ Play normalized"
            ;;
        caja)
            install_fm_script "$HOME/.config/caja/scripts" "▶ Play normalized"
            info "Right-click a video → Scripts → ▶ Play normalized"
            ;;
        dolphin)
            warn "KDE Dolphin detected. Automatic script installation is not supported."
            warn "You can set up a custom service menu manually:"
            warn "  https://develop.kde.org/docs/apps/dolphin/service-menus/"
            warn "The CLI tool (normalize-audio) is fully functional."
            ;;
        thunar)
            warn "XFCE Thunar detected. Automatic script installation is not supported."
            warn "You can add a Custom Action in Thunar (Edit → Configure custom actions):"
            warn "  Command: normalize-audio %f"
            warn "The CLI tool (normalize-audio) is fully functional."
            ;;
        *)
            warn "File manager not detected or not supported for automatic integration."
            warn "The CLI tool (normalize-audio) works on any desktop environment."
            ;;
    esac
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}─────────────────────────────────────────────${RESET}"
echo -e "${GREEN}${BOLD}videonorma installed successfully!${RESET}"
echo ""
echo "  CLI:  normalize-audio <file> [file2 ...]"
if [[ "$CLI_ONLY" != "true" ]]; then
    FM=$(detect_file_manager)
    case "$FM" in
        nautilus|nemo|caja) echo "  GUI:  Right-click any video → Scripts → ▶ Play normalized" ;;
        dolphin|thunar)     echo "  GUI:  Set up manually (see warnings above)" ;;
    esac
fi
echo ""
echo "  Logs: /tmp/videonorma_last.log"
echo -e "${BOLD}─────────────────────────────────────────────${RESET}"
