# Fzf with Git in the shell
# You can find this whole script from Junegunn Github repo below
# https://github.com/junegunn/fzf-git.sh

# Script is used in .zshrc 

# shellcheck disable=SC2039
[[ $0 == - ]] && return

__fzf_git_color() {
  if [[ -n $NO_COLOR ]]; then
    echo never
  elif [[ $# -gt 0 ]] && [[ -n $FZF_GIT_PREVIEW_COLOR ]]; then
    echo "$FZF_GIT_PREVIEW_COLOR"
  else
    echo "${FZF_GIT_COLOR:-always}"
  fi
}

__fzf_git_cat() {
  if [[ -n $FZF_GIT_CAT ]]; then
    echo "$FZF_GIT_CAT"
    return
  fi

  _fzf_git_bat_options="--style='${BAT_STYLE:-full}' --color=$(__fzf_git_color .) --pager=never"
  if command -v batcat > /dev/null; then
    echo "batcat $_fzf_git_bat_options"
  elif command -v bat > /dev/null; then
    echo "bat $_fzf_git_bat_options"
  else
    echo cat
  fi
}

__fzf_git_pager() {
  local pager
  pager="${FZF_GIT_PAGER:-${GIT_PAGER:-$(git config --get core.pager 2> /dev/null)}}"
  echo "${pager:-cat}"
}

if [[ $1 == --list ]]; then
  shift
  if [[ $# -eq 1 ]]; then
    branches() {
      git branch "$@" --sort=-committerdate --sort=-HEAD --format=$'%(HEAD) %(color:yellow)%(refname:short) %(color:green)(%(committerdate:relative))\t%(color:blue)%(subject)%(color:reset)' --color=$(__fzf_git_color) | column -ts$'\t'
    }
    refs() {
      git for-each-ref "$@" --sort=-creatordate --sort=-HEAD --color=$(__fzf_git_color) --format=$'%(if:equals=refs/remotes)%(refname:rstrip=-2)%(then)%(color:magenta)remote-branch%(else)%(if:equals=refs/heads)%(refname:rstrip=-2)%(then)%(color:brightgreen)branch%(else)%(if:equals=refs/tags)%(refname:rstrip=-2)%(then)%(color:brightcyan)tag%(else)%(if:equals=refs/stash)%(refname:rstrip=-2)%(then)%(color:brightred)stash%(else)%(color:white)%(refname:rstrip=-2)%(end)%(end)%(end)%(end)\t%(color:yellow)%(refname:short) %(color:green)(%(creatordate:relative))\t%(color:blue)%(subject)%(color:reset)' | column -ts$'\t'
    }
    hashes() {
      git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=$(__fzf_git_color) "$@" $LIST_OPTS
    }
    case "$1" in
      branches)
        echo 'CTRL-O (open in browser) ╱ ALT-A (show all branches)'
        echo 'ALT-H (list commit hashes)'
        branches
        ;;
      all-branches)
        echo 'CTRL-O (open in browser) ╱ ALT-ENTER (accept without remote)'
        echo 'ALT-H (list commit hashes)'
        branches -a
        ;;
      hashes)
        echo 'CTRL-O (open in browser) ╱ CTRL-D (diff)'
        echo 'CTRL-S (toggle sort) ╱ ALT-F (list files) ╱ ALT-A (show all hashes)'
        hashes
        ;;
      all-hashes)
        echo 'CTRL-O (open in browser) ╱ CTRL-D (diff)'
        echo 'CTRL-S (toggle sort) ╱ ALT-F (list files)'
        hashes --all
        ;;
      refs)
        echo 'CTRL-O (open in browser) ╱ ALT-E (examine in editor) ╱ ALT-A (show all refs)'
        refs --exclude='refs/remotes'
        ;;
      all-refs)
        echo 'CTRL-O (open in browser) ╱ ALT-E (examine in editor)'
        refs
        ;;
      *) exit 1 ;;
    esac
  elif [[ $# -gt 1 ]]; then
    set -e
    branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
    if [[ $branch == HEAD ]]; then
      branch=$(git describe --exact-match --tags 2> /dev/null || git rev-parse --short HEAD)
    fi
    case "$1" in
      commit)
        hash=$(grep -o "[a-f0-9]\{7,\}" | head -n 1 <<< "$2")
        path=/commit/$hash
        ;;
      branch|remote-branch)
        branch=$(sed 's/^[* ]*//' <<< "$2" | cut -d' ' -f1)
        remote=$(git config branch."${branch}".remote || echo 'origin')
        branch=${branch#$remote/}
        path=/tree/$branch
        ;;
      remote)
        remote=$2
        path=/tree/$branch
        ;;
      file) path=/blob/$branch/$(git rev-parse --show-prefix)$2 ;;
      tag)  path=/releases/tag/$2 ;;
      *)    exit 1 ;;
    esac
    remote=${remote:-$(git config branch."${branch}".remote || echo 'origin')}
    remote_url=$(git remote get-url "$remote" 2> /dev/null || echo "$remote")
    if [[ $remote_url =~ ^git@ ]]; then
      url=${remote_url%.git}; url=${url#git@}; url=https://${url/://}
    elif [[ $remote_url =~ ^http ]]; then
      url=${remote_url%.git}
    fi
    case "$OSTYPE" in
      darwin*) open "$url$path" ;;
      msys)    start "$url$path" ;;
      linux*)
        if uname -a | grep -i -q Microsoft && command -v powershell.exe; then
          powershell.exe -NoProfile start "$url$path"
        else
          xdg-open "$url$path"
        fi ;;
      *) xdg-open "$url$path" ;;
    esac
    exit 0
  fi
fi

if [[ $- =~ i ]] || [[ $1 = --run ]]; then

_fzf_git_fzf() {
  fzf --height 50% --tmux 90%,70% \
    --layout reverse --multi --min-height 20+ --border \
    --no-separator --header-border horizontal \
    --border-label-pos 2 \
    --color 'label:blue' \
    --preview-window 'right,50%' --preview-border line \
    --bind 'ctrl-/:change-preview-window(down,50%|hidden|)' "$@"
}

_fzf_git_check() {
  git rev-parse > /dev/null 2>&1 && return
  [[ -n $TMUX ]] && tmux display-message "Not in a git repository"
  return 1
}

__fzf_git=${BASH_SOURCE[0]:-${(%):-%x}}
__fzf_git=$(readlink -f "$__fzf_git" 2> /dev/null || /usr/bin/ruby --disable-gems -e 'puts File.expand_path(ARGV.first)' "$__fzf_git" 2> /dev/null)

_fzf_git_files() {
  _fzf_git_check || return
  local root query extract_file_name
  root=$(git rev-parse --show-toplevel)
  [[ -n "$(git rev-parse --show-prefix)" ]] && query='!../ '
  read -r -d "" extract_file_name <<'EOF'
"$(cut -c4- <<< {} | sed 's/.* -> //;s/^"//;s/"$//;s/\\"/"/g')"
EOF
  ( git -c core.quotePath=false -c color.status=$(__fzf_git_color) status --short --no-branch --untracked-files=all
    git -c core.quotePath=false ls-files "$root" | grep -vxFf <(
      git -c core.quotePath=false status --short --untracked-files=no | cut -c4- | sed -e 's/.* -> //' -e '/^"[^"\\]*"$/ { s/^"//;s/"$//; }'
      echo :
    ) | sed 's/^/   /'
  ) | _fzf_git_fzf -m --ansi --nth 2..,.. --border-label '📁 Files ' \
      --header 'CTRL-O (open in browser) ╱ ALT-E (open in editor)' \
      --bind "ctrl-o:execute-silent:bash \"$__fzf_git\" --list file $extract_file_name" \
      --bind "alt-e:execute:${EDITOR:-vim} $extract_file_name" \
      --query "$query" \
      --preview "git -c core.quotePath=false diff --no-ext-diff --color=$(__fzf_git_color .) -- $extract_file_name | $(__fzf_git_pager); $(__fzf_git_cat) $extract_file_name" "$@" |
    cut -c4- | sed 's/.* -> //'
}

_fzf_git_branches() {
  _fzf_git_check || return
  local shell; [[ -n ${BASH_VERSION:-} ]] && shell=bash || shell=zsh
  bash "$__fzf_git" --list branches |
  __fzf_git_fzf=$(declare -f _fzf_git_fzf) _fzf_git_fzf --ansi --border-label '🌲 Branches ' --header-lines 2 \
    --preview-window down,border-top,40% --color hl:underline,hl+:underline --no-hscroll \
    --bind "ctrl-o:execute-silent:bash \"$__fzf_git\" --list branch {}" \
    --bind "alt-a:change-border-label(🌳 All branches)+reload:bash \"$__fzf_git\" --list all-branches" \
    --bind "alt-h:become:LIST_OPTS=\$(cut -c3- <<< {} | cut -d' ' -f1) $shell \"$__fzf_git\" --run hashes" \
    --preview "git log --oneline --graph --date=short --color=$(__fzf_git_color .) --pretty='format:%C(auto)%cd %h%d %s' \$(cut -c3- <<< {} | cut -d' ' -f1) --" "$@" |
  sed 's/^\* //' | awk '{print $1}'
}

_fzf_git_tags() {
  _fzf_git_check || return
  git tag --sort -version:refname | _fzf_git_fzf --preview-window right,70% --border-label '📛 Tags ' \
    --header 'CTRL-O (open in browser)' \
    --bind "ctrl-o:execute-silent:bash \"$__fzf_git\" --list tag {}" \
    --preview "git show --color=$(__fzf_git_color .) {} | $(__fzf_git_pager)" "$@"
}

_fzf_git_hashes() {
  _fzf_git_check || return
  bash "$__fzf_git" --list hashes | _fzf_git_fzf --ansi --no-sort --bind 'ctrl-s:toggle-sort' --border-label '🍡 Hashes ' --header-lines 2 \
    --bind "ctrl-o:execute-silent:bash \"$__fzf_git\" --list commit {}" \
    --bind "alt-a:change-border-label(🍇 All hashes)+reload:bash \"$__fzf_git\" --list all-hashes" \
    --preview "grep -o '[a-f0-9]\{7,\}' <<< {} | head -n 1 | xargs git show --color=$(__fzf_git_color .) | $(__fzf_git_pager)" "$@" |
  awk 'match($0, /[a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]*/) { print substr($0, RSTART, RLENGTH) }'
}

_fzf_git_remotes() {
  _fzf_git_check || return
  git remote -v | awk '{print $1 "\t" $2}' | uniq | _fzf_git_fzf --tac --border-label '📡 Remotes ' \
    --header 'CTRL-O (open in browser)' \
    --bind "ctrl-o:execute-silent:bash \"$__fzf_git\" --list remote {1}" \
    --preview "git log --oneline --graph --date=short --color=$(__fzf_git_color .) --pretty='format:%C(auto)%cd %h%d %s' '{1}/$(git rev-parse --abbrev-ref HEAD)' --" "$@" |
  cut -d$'\t' -f1
}

_fzf_git_stashes() {
  _fzf_git_check || return
  git stash list | _fzf_git_fzf --border-label '🥡 Stashes ' --header 'CTRL-X (drop stash)' \
    --bind 'ctrl-x:reload(git stash drop -q {1}; git stash list)' \
    -d: --preview "git show --first-parent --color=$(__fzf_git_color .) {1} | $(__fzf_git_pager)" "$@" | cut -d: -f1
}

_fzf_git_lreflogs() {
  _fzf_git_check || return
  git reflog --color=$(__fzf_git_color) --format="%C(blue)%gD %C(yellow)%h%C(auto)%d %gs" | _fzf_git_fzf --ansi --border-label '📒 Reflogs ' \
    --preview "git show --color=$(__fzf_git_color .) {1} | $(__fzf_git_pager)" "$@" | awk '{print $1}'
}

_fzf_git_each_ref() {
  _fzf_git_check || return
  bash "$__fzf_git" --list refs | _fzf_git_fzf --ansi --border-label '☘️  Each ref ' --header-lines 1 \
    --bind "ctrl-o:execute-silent:bash \"$__fzf_git\" --list {1} {2}" \
    --bind "alt-a:change-border-label(🍀 Every ref)+reload:bash \"$__fzf_git\" --list all-refs" \
    --preview "git log --oneline --graph --date=short --color=$(__fzf_git_color .) --pretty='format:%C(auto)%cd %h%d %s' {2} --" "$@" | awk '{print $2}'
}

_fzf_git_worktrees() {
  _fzf_git_check || return
  git worktree list | _fzf_git_fzf --border-label '🌴 Worktrees ' --header 'CTRL-X (remove worktree)' \
    --bind 'ctrl-x:reload(git worktree remove {1} > /dev/null; git worktree list)' \
    --preview "git -c color.status=$(__fzf_git_color .) -C {1} status --short --branch; echo; git log --oneline --graph --date=short --color=$(__fzf_git_color .) --pretty='format:%C(auto)%cd %h%d %s' {2} --" "$@" | awk '{print $1}'
}

_fzf_git_list_bindings() {
  cat <<'EOF'

CTRL-G ? or Shift-H to show this list
CTRL-G F for Files
CTRL-G B for Branches
CTRL-G T for Tags
CTRL-G R for Remotes
CTRL-G H for commit Hashes
CTRL-G S for Stashes
CTRL-G L for reflogs
CTRL-G W for Worktrees
CTRL-G E for Each ref (git for-each-ref)
EOF
}

fi

if [[ $1 = --run ]]; then
  shift; type=$1; shift; eval "_fzf_git_$type" "$@"
elif [[ $- =~ i ]]; then
  if [[ -n "${BASH_VERSION:-}" ]]; then
    __fzf_git_init() {
      local o c; for o in "$@"; do
        c=${o:0:1}; [[ $o == "list_bindings" ]] && c="H"
        if [[ $o == "list_bindings" ]]; then
          bind -x "\"\C-g$c\": _fzf_git_list_bindings"
          bind -x "\"\C-g?\": _fzf_git_list_bindings"
        else
          bind -m emacs-standard '"\C-g'$c'": " \C-u \C-a\C-k`_fzf_git_'$o'`\e\C-e\C-y\C-a\C-y\ey\C-h\C-e\er \C-h"'
        fi
      done
    }
  elif [[ -n "${ZSH_VERSION:-}" ]]; then
    __fzf_git_join() { local item; while read -r item; do echo -n -E "${(q)${(Q)item}} "; done }
    __fzf_git_init() {
      setopt localoptions no_glob
      local m o c name
      for o in "$@"; do
        c=${o[1]}; [[ $o == "list_bindings" ]] && c="H"
        name="fzf-git-$o-widget"
        if [[ $o == "list_bindings" ]]; then
          eval "$name() { zle -M '$(_fzf_git_list_bindings)'; }"
        else
          eval "$name() { local result=\$(_fzf_git_$o | __fzf_git_join); LBUFFER+=\$result; zle reset-prompt }"
        fi
        zle -N "$name"
        for m in emacs vicmd viins; do
          bindkey -M $m "^g$c" "$name"
          [[ $o == "list_bindings" ]] && bindkey -M $m "^g?" "$name"
        done
      done
      # Prevent Ctrl-G from interrupting/Enter behavior
      bindkey '^g' self-insert 2>/dev/null || true
    }
  fi
  __fzf_git_init files branches tags remotes hashes stashes lreflogs each_ref worktrees list_bindings
  [[ -n "${ZSH_VERSION:-}" ]] && export KEYTIMEOUT=100
fi
