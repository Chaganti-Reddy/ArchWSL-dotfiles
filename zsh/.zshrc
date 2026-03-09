autoload -Uz compinit
if [[ ! -f ~/.zcompdump.zsh || ~/.zcompdump.zsh -ot ~/.zshrc ]]; then
  compinit -d ~/.zcompdump.zsh
else
  compinit -C -d ~/.zcompdump.zsh
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="archcraft-dwm"
# ENABLE_CORRECTION="true"
plugins=(git nvm)
source $ZSH/oh-my-zsh.sh
# On-demand rehash
zshcache_time="$(date +%s%N)"
autoload -Uz add-zsh-hook
rehash_precmd() {
  if [[ -a /var/cache/zsh/pacman ]]; then
    local paccache_time="$(date -r /var/cache/zsh/pacman +%s%N)"
    if (( zshcache_time < paccache_time )); then
      rehash
      zshcache_time="$paccache_time"
    fi
  fi
}
add-zsh-hook -Uz precmd rehash_precmd
source $HOME/.config/scripts/fzf-git.sh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/fzf/completion.zsh
source /usr/share/fzf/key-bindings.zsh
eval "$(fzf --zsh)" # fzf
eval "$(zoxide init zsh)"
# fastfetch 
# colorscript random
source $HOME/.config/zsh/exports.zsh
source $HOME/.config/zsh/aliases.zsh
source $HOME/.config/zsh/functions.zsh

# Atuin configs
export ATUIN_NOBIND="true"
eval "$(atuin init zsh)"
bindkey '^r' atuin-up-search-viins

fpath+=~/.zfunc; autoload -Uz compinit; compinit
eval "$(thefuck --alias)"
# eval "$(leetcode completions)"
[[ $commands[kubectl] ]] && source <(kubectl completion zsh)

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# >>> conda initialize >>>
# !! Contents within this block are managed by "conda init" !!
__conda_setup="$(/home/karna/miniconda/bin/conda shell.${SHELL##*/} hook 2> /dev/null)"
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
# <<< conda initialize <<<
