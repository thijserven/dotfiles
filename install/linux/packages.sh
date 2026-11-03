#!/bin/bash

set -e

DOTFILES_ROOT="${DOTFILES_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)}"

install_script_tool() {
    local name="$1"
    local cmd="$2"

    if ! command -v "$name" >/dev/null 2>&1; then
        echo "Installing $name via install script..."
        eval "$cmd"
    else
        echo "$name already installed, skipping."
    fi
}

install_arch_packages() {
    sudo pacman -Syu --noconfirm
    local packages
    mapfile -t packages < "$DOTFILES_ROOT/install/linux/packages.arch.txt"
    sudo pacman -S --noconfirm --needed "${packages[@]}"

    # mise (keep shell configuration managed by chezmoi)
    install_script_tool mise "curl -fsSL https://mise.run | MISE_INSTALL_PATH=\$HOME/.local/bin/mise sh"
}

install_github_cli() {
    # gh CLI — official apt repo
    if ! command -v gh >/dev/null 2>&1; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
            | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
            | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update -y
        sudo apt-get install -y gh
    fi
}

install_fzf() {
    # Install from GitHub for `fzf --zsh` support (>= 0.48.0).
    if ! command -v fzf >/dev/null 2>&1; then
        FZF_VERSION=$(curl -s "https://api.github.com/repos/junegunn/fzf/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
        curl -Lo /tmp/fzf.tar.gz "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz"
        tar -xf /tmp/fzf.tar.gz -C /tmp fzf
        sudo install /tmp/fzf /usr/local/bin/fzf
    fi
}

install_lazygit() {
    if ! command -v lazygit >/dev/null 2>&1; then
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
        curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit
        sudo install /tmp/lazygit /usr/local/bin
    fi
}

install_sops() {
    if ! command -v sops >/dev/null 2>&1; then
        SOPS_VERSION=$(curl -s "https://api.github.com/repos/getsops/sops/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
        curl -Lo /tmp/sops "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.amd64"
        sudo install /tmp/sops /usr/local/bin/sops
    fi
}

install_debian_packages() {
    sudo apt-get update -y
    local packages
    mapfile -t packages < "$DOTFILES_ROOT/install/linux/packages.debian.txt"
    sudo apt-get install -y "${packages[@]}"

    install_github_cli
    install_fzf
    install_script_tool starship "curl -sS https://starship.rs/install.sh | sh -s -- --yes"
    install_script_tool zoxide "curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh"
    install_lazygit
    install_script_tool fastfetch "sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch && sudo apt-get update -y && sudo apt-get install -y fastfetch"
    install_script_tool chezmoi "sh -c \"\$(curl -fsLS get.chezmoi.io)\" -- -b \$HOME/.local/bin"
    install_script_tool just "curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to \$HOME/.local/bin"
    install_sops

    # mise (keep shell configuration managed by chezmoi)
    install_script_tool mise "curl -fsSL https://mise.run | MISE_INSTALL_PATH=\$HOME/.local/bin/mise sh"
}

main() {
    # Distro metadata exists only on target Linux hosts.
    # shellcheck source=/dev/null
    . /etc/os-release

    if [ "$ID" = "arch" ]; then
        install_arch_packages
    elif [ "$ID" = "debian" ] || [ "$ID" = "ubuntu" ]; then
        install_debian_packages
    else
        echo "Unsupported distro: $ID. Skipping package install."
    fi
}

main "$@"
