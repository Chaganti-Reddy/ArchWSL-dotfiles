#!/bin/env bash
set -u
set -o pipefail

# -------------------------- CONFIGURATION --------------------------
LOG_FILE="$HOME/.cache/dotfiles-wsl-install.log"
CHECKPOINT_DIR="$HOME/.cache/setup_checkpoints_wsl"
DOTFILES_DIR="$HOME/dotfiles"

MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-py311_24.11.1-0-Linux-x86_64.sh"
INSTALLER_NAME="Miniconda3.sh"

mkdir -p "$CHECKPOINT_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# -------------------------- COLORS & UTILS --------------------------
BOLD=$(tput bold)
RESET=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
BLUE=$(tput setaf 4)
CYAN=$(tput setaf 6)

exec > >(tee -a "$LOG_FILE") 2>&1

die()     { echo -e "${BOLD}${RED}ERROR:${RESET} $*" >&2; exit 1; }
info()    { echo -e "${BOLD}${BLUE}INFO:${RESET} $*"; }
success() { echo -e "${BOLD}${GREEN}SUCCESS:${RESET} $*"; }
warning() { echo -e "${BOLD}${CYAN}WARNING:${RESET} $*"; }

prompt() {
    local message="${1:-}"
    local default="${2:-}"
    local input
    read -rp "$message [default: $default]: " input
    echo "${input:-$default}"
}

# -------------------------- CHECKPOINT SYSTEM --------------------------
run_task() {
    local task_name="$1"
    local task_id
    task_id=$(echo "$task_name" | tr -c '[:alnum:]' '_')
    shift

    if [ -f "$CHECKPOINT_DIR/$task_id" ]; then
        success "Skipping '$task_name' (Already Completed)."
        return 0
    fi

    echo -e "\n${BOLD}${CYAN}>>> RUNNING: $task_name${RESET}"
    "$@"
    local status=$?

    if [ $status -eq 0 ]; then
        touch "$CHECKPOINT_DIR/$task_id"
        success "'$task_name' done."
    else
        die "'$task_name' FAILED. Fix the error and re-run to resume."
    fi
}

# -------------------------- 1) MINICONDA --------------------------
install_miniconda() {
    info "Setting up Miniconda..."

    source ~/.bashrc 2>/dev/null || true

    if command -v conda &>/dev/null; then
        success "Conda already installed at $(command -v conda). Skipping."
        return 0
    fi

    info "Downloading Miniconda installer..."
    wget -q --show-progress -O "$INSTALLER_NAME" "$MINICONDA_URL"

    info "Running the Miniconda installer..."
    bash "$INSTALLER_NAME" -b -u -p "$HOME/miniconda"

    info "Cleaning up installer..."
    rm "$INSTALLER_NAME"

    SHELL_CONFIGS=()
    [[ -f "$HOME/.bashrc" ]] && SHELL_CONFIGS+=("$HOME/.bashrc")
    [[ -f "$HOME/.zshrc" ]]  && SHELL_CONFIGS+=("$HOME/.zshrc")
    [[ ${#SHELL_CONFIGS[@]} -eq 0 ]] && die "Neither .bashrc nor .zshrc found."

    CONDA_BLOCK='
# >>> conda initialize >>>
__conda_setup="$('$HOME/miniconda/bin/conda' shell.${SHELL##*/} hook 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$HOME/miniconda/etc/profile.d/conda.sh" ]; then
        . "$HOME/miniconda/etc/profile.d/conda.sh"
    else
        export PATH="$HOME/miniconda/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<'

    for config in "${SHELL_CONFIGS[@]}"; do
        if ! grep -q "conda initialize" "$config"; then
            info "Adding Conda init to $config..."
            echo "$CONDA_BLOCK" >> "$config"
        else
            success "Conda init already present in $config."
        fi
    done

    if [[ "$SHELL" == *"bash"* ]]; then
        eval "$($HOME/miniconda/bin/conda shell.bash hook)"
    elif [[ "$SHELL" == *"zsh"* ]]; then
        eval "$($HOME/miniconda/bin/conda shell.zsh hook)"
    else
        die "Unsupported shell. Cannot initialize Conda."
    fi

    conda --version
    python --version

    success "Miniconda setup complete."
    info "Python: $(python --version) | Conda: $(conda --version)"
    sleep 2
}

install_pip_packages() {
    info "Setting up PIP packages..."

    if [[ -n "${CONDA_DEFAULT_ENV:-}" ]]; then
        info "Conda active (Env: $CONDA_DEFAULT_ENV)."
    elif [ -f "$HOME/miniconda/etc/profile.d/conda.sh" ]; then
        info "Activating Conda base..."
        source "$HOME/miniconda/etc/profile.d/conda.sh"
        conda activate base || { warning "Failed to activate Conda. Skipping pip."; return 0; }
    else
        warning "Conda not found. Skipping pip install to protect system Python."
        return 0
    fi

    local pip_packages=(
        "pynvim" "numpy" "pandas" "matplotlib" "seaborn" "scikit-learn" "jupyterlab"
        "ipykernel" "ipywidgets" "python-prctl" "inotify-simple" "psutil" "libclang"
        "keras" "daemon" "beautifulsoup4" "requests" "flask" "streamlit"
        "zxcvbn" "pyaml" "pymupdf" "ruff-lsp" "python-lsp-server" "semgrep"
        "transformers" "spacy" "nltk" "sentencepiece" "pipreqs" "feedparser"
        "pypdf2" "fuzzywuzzy" "sentence-transformers" "langchain-ollama"
        "tensorflow" "torch" "torchvision" "torchaudio"
    )

    local packages_to_install=()
    for package in "${pip_packages[@]}"; do
        local clean_name="${package%%[*}"
        if ! pip show "$clean_name" &>/dev/null; then
            packages_to_install+=("$package")
        fi
    done

    if [ ${#packages_to_install[@]} -gt 0 ]; then
        info "Installing ${#packages_to_install[@]} packages..."
        pip install "${packages_to_install[@]}" || warning "Some packages failed to install."
    else
        success "All pip packages already installed."
    fi

    success "PIP setup complete."
}

# -------------------------- 2) PACMAN CONFIG --------------------------
step_pacman_config() {
    info "Configuring pacman..."
    if ! grep -q "ILoveCandy" /etc/pacman.conf; then
        sudo sed -i '/^ParallelDownloads/d' /etc/pacman.conf
        sudo sed -i "/#UseSyslog/a ILoveCandy\nParallelDownloads=10\nColor" /etc/pacman.conf
        success "pacman.conf updated."
    else
        success "pacman.conf already configured."
    fi
}

# -------------------------- 3) PARU --------------------------
step_install_paru() {
    if command -v paru &>/dev/null; then
        success "paru already installed."
        return 0
    fi

    info "Installing paru AUR helper..."
    cd ~/Downloads || return 1
    sudo pacman -Syyu --noconfirm git base-devel rustup
    rustup default stable
    rm -rf paru
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    rm -rf paru
    cd "$DOTFILES_DIR"
    success "paru installed."
}

# -------------------------- 4) SYSTEM BASE (WSL-safe) --------------------------
step_system_base() {
    info "Installing base CLI packages..."

    local pkgs=(
        # Core utils
        bash-completion git curl wget base-devel stow
        # File & text tools
        tree tar time unrar unzip zip rsync atool dos2unix 7zip
        bat eza fd ripgrep fzf jq yq xmlstarlet figlet lolcat
        glow pandoc man-db man-pages ncdu progress trash-cli
        # Dev tools
        python-pip python-psutil shellcheck shfmt prettier stylua
        luacheck lua51 gdb meld parallel translate-shell
        perl-image-exiftool
        # Langs & build
        go rustup cargo
        # LSPs & formatters
        pyright python-black lua-language-server bash-language-server
        vscode-css-languageserver vscode-html-languageserver
        typescript-language-server jedi-language-server ccls
        rust-analyzer rust-src
        # Git extras
        lazygit git-lfs
        # System info
        btop fastfetch sysstat
        # Wakatime
        wakatime
        # ZSH
        zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting zoxide
        # Atuin
        atuin
    )

    paru -S --needed --noconfirm "${pkgs[@]}"

    rustup default stable
    rustup component add rust-analyzer clippy rust-src

    success "Base packages installed."
}

# -------------------------- 5) GIT & ZSH --------------------------
step_git_zsh_setup() {
    info "Configuring Git..."
    git config --global user.name "Chaganti-Reddy"
    git config --global user.email "chagantivenkataramireddy4@gmail.com"
    git config --global core.editor "nvim"
    git config --global core.autocrlf input
    git config --global init.defaultBranch main
    git config --global pull.rebase true
    git config --global credential.helper "cache --timeout=3601"
    git config --global color.ui auto
    git config --global alias.st status
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.unstage 'reset HEAD --'
    git config --global log.decorate true
    git config --global push.default simple
    git config --global push.autoSetupRemote true
    success "Git configured."

    info "Setting up ZSH..."

    # Install Oh-My-Zsh if not present
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        info "Installing Oh-My-Zsh..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    else
        success "Oh-My-Zsh already installed."
    fi

    # Change shell to zsh
    if [[ "$SHELL" != "/bin/zsh" ]]; then
        sudo chsh -s /bin/zsh "$USER"
        info "Shell changed to zsh. Re-login or run: exec zsh"
    fi

    # Run dotfiles zsh install script if present
    if [ -f "$DOTFILES_DIR/install_zsh.sh" ]; then
        bash "$DOTFILES_DIR/install_zsh.sh"
    fi

    # Stow zsh config
    rm -f ~/.zshrc
    cd "$DOTFILES_DIR" || return
    stow -R zsh

    # Copy custom theme if present
    local theme_src="$DOTFILES_DIR/Extras/Extras/archcraft-dwm.zsh-theme"
    local theme_dest="$HOME/.oh-my-zsh/themes/archcraft-dwm.zsh-theme"
    if [ -f "$theme_src" ]; then
        mkdir -p "$(dirname "$theme_dest")"
        cp "$theme_src" "$theme_dest"
        success "ZSH theme copied."
    fi

    success "ZSH setup complete."
}

# -------------------------- 6) NODE / NVM --------------------------
step_nodejs() {
    info "Installing NVM + Node..."
    if [ -d "$HOME/.nvm" ]; then
        success "NVM already installed."
        return 0
    fi
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    success "NVM installed. Run 'nvm install --lts' after re-login."
}

# -------------------------- 7) EDITORS --------------------------
step_editors() {
    info "Installing editors..."
    paru -S --needed --noconfirm vim neovim tree-sitter-cli tree-sitter-bash tree-sitter-rust aspell
    success "Editors installed."
}

# -------------------------- 8) ENCRYPTION / GPG / PASS --------------------------
step_encryption() {
    info "Setting up GPG + pass..."
    paru -S --needed --noconfirm gnupg ccrypt git-remote-gcrypt

    mkdir -p ~/.gnupg
    chmod 700 ~/.gnupg

    if ! grep -q "default-cache-ttl" ~/.gnupg/gpg-agent.conf 2>/dev/null; then
        echo "default-cache-ttl 150"  >> ~/.gnupg/gpg-agent.conf
        echo "max-cache-ttl 150"      >> ~/.gnupg/gpg-agent.conf
        gpgconf --kill gpg-agent
        success "GPG agent configured."
    else
        success "GPG agent already configured."
    fi
}

# -------------------------- 9) SSH SETUP --------------------------
step_ssh_setup() {
    info "Setting up SSH..."

    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    if [ ! -f ~/.ssh/id_ed25519 ]; then
        info "Generating ED25519 SSH key..."
        ssh-keygen -t ed25519 -C "chagantivenkataramireddy4@gmail.com" -f ~/.ssh/id_ed25519 -N ""
        success "SSH key generated at ~/.ssh/id_ed25519"
        info "Add this public key to GitHub:"
        echo ""
        cat ~/.ssh/id_ed25519.pub
        echo ""
    else
        success "SSH key already exists."
    fi

    # Ensure ssh-agent config in shell
    if [ -f "$HOME/.bashrc" ] && ! grep -q "ssh-agent" "$HOME/.bashrc"; then
        cat >> "$HOME/.bashrc" << 'EOF'

# SSH Agent (WSL)
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi
EOF
    fi
}

# -------------------------- 10) LAZYDOCKER --------------------------
step_lazydocker() {
    info "Installing LazyDocker..."
    if command -v lazydocker &>/dev/null; then
        success "LazyDocker already installed."
        return 0
    fi
    paru -S --needed --noconfirm lazydocker-bin
    success "LazyDocker installed."
}

# -------------------------- 11) ANI-CLI + MPV (WSL2 note) --------------------------
# NOTE: ani-cli and mpv CAN work in WSL2 but require a display.
#   - Windows 11 with WSLg: works out of the box (GUI apps supported).
#   - Windows 10: needs an X server like VcXsrv or Xming running on Windows,
#     and DISPLAY=:0 set in your shell.
# ani-cli itself (fetching/streaming) works headlessly fine either way.
step_ani_mpv() {
    info "Installing ani-cli + mpv..."
    warning "mpv GUI playback in WSL2 requires WSLg (Win11) or an X server (Win10)."
    warning "ani-cli fetching/URL extraction works in all cases."
    paru -S --needed --noconfirm mpv ani-cli-git yt-dlp-git
    success "ani-cli + mpv installed."
}

# -------------------------- 12) STOW DOTFILES (WSL-safe subset) --------------------------
step_stow_wsl() {
    cd "$DOTFILES_DIR" || die "dotfiles dir not found at $DOTFILES_DIR"

    # Remove stock configs that will be replaced by stow
    rm -f ~/.bashrc

    # WSL-safe stow targets — no GUI/compositor/display-server configs
    local folders=(
        bash             # bash config
        nvim             # neovim
        vim              # vim
        BTOP             # btop
        fastfetch        # fastfetch
        atuin            # atuin shell history
        yazi             # yazi file manager
        pandoc           # pandoc defaults
        latexmkrc        # latex
        enchant          # spell check
        ytfzf            # ytfzf youtube downloader
    )

    for folder in "${folders[@]}"; do
        if [ -d "$DOTFILES_DIR/$folder" ]; then
            info "Stowing $folder..."
            stow -R "$folder"
        else
            warning "Skipping '$folder' — directory not found in dotfiles."
        fi
    done

    # System-level configs (WSL-safe ones only)
    if [ -d "Extras/Extras/etc" ]; then
        [ -f "Extras/Extras/etc/nanorc" ]     && sudo cp Extras/Extras/etc/nanorc /etc/nanorc
        [ -f "Extras/Extras/etc/bash.bashrc" ] && sudo cp Extras/Extras/etc/bash.bashrc /etc/bash.bashrc
        [ -f "Extras/Extras/etc/DIR_COLORS" ]  && sudo cp Extras/Extras/etc/DIR_COLORS /etc/DIR_COLORS
    fi

    # Wakatime config decrypt (if present)
    if [ -f "Extras/Extras/.wakatime.cfg.cpt" ]; then
        cp Extras/Extras/.wakatime.cfg.cpt ~/
        ccrypt -d ~/.wakatime.cfg.cpt || warning "Wakatime decrypt skipped."
    fi

    success "Dotfiles stowed (WSL subset)."
}

# -------------------------- EXECUTION --------------------------
clear
echo -e "${BOLD}${BLUE}Starting WSL Arch Setup (User: karna)${RESET}"
echo -e "${BOLD}${CYAN}Log: $LOG_FILE${RESET}\n"

run_task "Pacman Config"        step_pacman_config
run_task "Install Paru"         step_install_paru
run_task "System Base"          step_system_base
run_task "Git & ZSH"            step_git_zsh_setup
run_task "Node/NVM"             step_nodejs
run_task "Editors"              step_editors
run_task "Encryption/GPG"       step_encryption
run_task "SSH Setup"            step_ssh_setup
run_task "LazyDocker"           step_lazydocker
run_task "Ani-CLI + MPV"        step_ani_mpv
run_task "Miniconda"            install_miniconda
run_task "Pip Packages"         install_pip_packages
run_task "Stow Dotfiles"        step_stow_wsl

success "WSL Setup Finished."
echo -e "\n${BOLD}${CYAN}Next steps:${RESET}"
echo "  1. exec zsh  (or re-login) to activate zsh"
echo "  2. nvm install --lts  (to install Node LTS)"
echo "  3. Add ~/.ssh/id_ed25519.pub to GitHub → https://github.com/settings/keys"
echo "  4. For mpv/ani-cli GUI: ensure WSLg is active (Win11) or start VcXsrv (Win10)"
