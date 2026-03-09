# Exports
export MANPATH="/usr/local/man:$MANPATH"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export LANG=en_US.UTF-8
# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi
export EDITOR='/usr/bin/nvim'
export VISUAL='nvim'
export BROWSER='/usr/bin/firefox'
export PATH="$HOME/bin:/usr/local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.config/scripts/:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.config/rofi/scripts:$PATH"
export PATH="$HOME/miniconda:$PATH"
export JAVA_HOME="/usr/lib/jvm/default"
export PATH="$JAVA_HOME/bin:$PATH"
export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:$XDG_DATA_DIRS"
export PUPPETEER_EXECUTABLE_PATH="/home/karna/.cache/puppeteer/chrome-headless-shell/linux-133.0.6943.53/chrome-headless-shell-linux64/chrome-headless-shell"
export SUDO_EDITOR=/usr/bin/nvim
export TMUX_CONF="$HOME/.config/tmux/tmux.conf" # tmux
# export FZF_DEFAULT_OPTS="--layout=reverse --exact --border=bold --border=rounded --margin=3% --color=dark"
# Set up FZF key bindings and fuzzy completion
# Keymaps for this is available at https://github.com/junegunn/fzf-git.sh
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git "
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

export FZF_DEFAULT_OPTS="--height 50% --layout=default --border --color=hl:#2dd4bf"

# Setup fzf previews
export FZF_CTRL_T_OPTS="--preview 'bat --color=always -n --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --icons=always --tree --color=always {} | head -200'"

# fzf preview for tmux
export FZF_TMUX_OPTS=" -p90%,70% "  
export STARSHIP_LOG="error"
export MPLBACKEND=TkAgg
export EDITOR='/usr/bin/nvim'
export PAGER='bat'
export NVM_COLORS='cmgRY'
# Lazy-load NVM only when needed
export NVM_DIR="$HOME/.nvm"

# echo some artwork 
# if [ -f "$HOME/.config/scripts/unix" ]; then
  # ~/.config/scripts/unix
# fi

(cat ~/.cache/wal/sequences &)
