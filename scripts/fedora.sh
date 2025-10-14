#!/bin/bash
IFS=$'\n\t'
info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*"; }

confirm() {
    read -r -p "$1 [y/N]: " response </dev/tty
    case "$response" in
        [yY][eE][sS]|[yY]) true ;;
        *) false ;;
    esac
}


info "Updating system..."
sudo dnf -y update
sudo dnf -y upgrade

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
    tldr
    wireguard-tools
    lsd
    bat
    httpie
    sqlite3
)

info "Installing essential packages..."
sudo dnf install -y "${ESSENTIALS[@]}"

if confirm "Install Docker and Docker Compose?"; then
    sudo dnf -y install dnf-plugins-core
    sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable --now docker
    sudo usermod -aG docker $USER
    info "Docker installed and user added to docker group. You may need to log out and back in."
fi

if confirm "Install Kubernetes via kind (local cluster)?"; then
    # Detect architecture
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) KIND_ARCH=amd64 KUBE_ARCH=amd64 ;;
        aarch64) KIND_ARCH=arm64 KUBE_ARCH=arm64 ;;
        *) error "Unsupported architecture: $ARCH"; exit 1 ;;
    esac

    # Install kind
    info "Installing kind..."
    curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.26.0/kind-linux-$KIND_ARCH"
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind

    # Install kubectl
    info "Installing kubectl..."
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/$KUBE_ARCH/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/

    # Optional: Helm
    if confirm "Install Helm (package manager for Kubernetes)?"; then
        info "Installing Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi

    # Optional: k9s
    if confirm "Install k9s (terminal UI for Kubernetes)?"; then
        info "Installing k9s..."
        curl -sS https://webinstall.dev/k9s | bash
    fi

    info "Kind, kubectl (and optional Helm/k9s) installed."
    info "You can now create a local cluster with: kind create cluster"
fi
