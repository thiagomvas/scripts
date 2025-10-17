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
sudo apt -y update

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
sudo apt install -y "${ESSENTIALS[@]}"

if confirm "Install Docker and Docker Compose?"; then
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    
    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
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
    [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64
    [ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-arm64
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

sudo apt install -y rust cargo nodejs golang
