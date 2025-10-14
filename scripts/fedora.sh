#!/bin/bash
IFS=$'\n\t'
info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*"; }

confirm() {
    read -r -p "$1 [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY]) true ;;
        *) false ;;
    esac
}

info "Updating system..."
# sudo dnf -y update
# sudo dnf -y upgrade

# ---------------------------------------
# Install essential packages
# ---------------------------------------
ESSENTIALS=(
    git
    curl
    wget
    vim
    btop
    tmux
    bash-completion
    zsh
    neovim
    dotnet-sdk-9.0
    gcc
    make
    dtop
    tldr
    wireguard-tools
    lsd
    bat
    httpie
    sqlite3
)

info "Installing essential packages..."
# sudo dnf install -y "${ESSENTIALS[@]}"
