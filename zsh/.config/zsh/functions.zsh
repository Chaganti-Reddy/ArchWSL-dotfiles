# Functions
function function_depends() {
    search=$(echo "$1")
    sudo pacman -Sii $search | grep "Required" | sed -e "s/Required By     : //g" | sed -e "s/  /\n/g"
}

function ex() {
  if [ -f $1 ]; then
    case $1 in
      *.tar.bz2) tar xjf $1 ;;
      *.tar.gz) tar xzf $1 ;;
      *.bz2) bunzip2 $1 ;;
      *.rar) unrar x $1 ;;
      *.gz) gunzip $1 ;;
      *.tar) tar xf $1 ;;
      *.tbz2) tar xjf $1 ;;
      *.tgz) tar xzf $1 ;;
      *.zip) unzip $1 ;;
      *.Z) uncompress $1 ;;
      *.7z) 7z x $1 ;;
      *.deb) ar x $1 ;;
      *.tar.xz) tar xf $1 ;;
      *.tar.zst) tar xf $1 ;;
      *) echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

function comp() {
  if [ -z "$1" ]; then
    echo "Usage: comp <file_or_directory>"
    return 1
  fi
  input="$1"
  echo "Select a compression format:"
  typeset -a options
  options=("tar.gz" "zip" "rar" "7z" "tar.xz" "tar.zst" "gz" "tar.bz2" "tar" "tbz2" "tgz" "bz2")
  for i in {1..${#options[@]}}
  do
    echo "$i) ${options[$i]}"
  done
  echo -n "Enter the number of your choice: "
  read choice
  if [[ "$choice" -lt 1 || "$choice" -gt ${#options[@]} ]]; then
    echo "Invalid choice. Exiting."

    zle -N lolcat_clear
bindkey '^L' lolcat_clear  # Ctrl+L
    return 1
  fi
  format="${options[$choice]}"
  output="${input}.${format}"
  case $format in
    tar.bz2) tar cjf "$output" "$input" ;;
    tar.gz) tar czf "$output" "$input" ;;
    bz2) bzip2 -k "$input" ;;
    rar) rar a "$output" "$input" ;;
    gz) gzip -k "$input" ;;
    tar) tar cf "$output" "$input" ;;
    tbz2) tar cjf "$output" "$input" ;;
    tgz) tar czf "$output" "$input" ;;
    zip) zip -r "$output" "$input" ;;
    7z) 7z a "$output" "$input" ;;
    tar.xz) tar cJf "$output" "$input" ;;
    tar.zst) tar --zstd -cf "$output" "$input" ;;
    *) echo "Unsupported format: $format" ; return 1;;
  esac
  echo "Compression successful: $output"
}

compdef '_files' comp

function ctime() {
  file="$1"
  if [[ $file == *.c ]]; then
    out_file="${file%.c}"
    g++ -std=c++17 "$file" -o "$out_file"
    /usr/bin/time -p ./"$out_file"
  else
    g++ -std=c++17 "$file.c" -o "$file"
    /usr/bin/time -p ./"$file"
  fi
}

function cpptime() {
  file="$1"
  if [[ $file == *.cpp ]]; then
    out_file="${file%.cpp}"
    g++ -std=c++17 "$file" -o "$out_file"
    /usr/bin/time -p ./"$out_file"
  else
    g++ -std=c++17 "$file.cpp" -o "$file"
    /usr/bin/time -p ./"$file"
  fi
}

function mosscc() {
    perl -i moss.pl -l cc $1 $2
}

function mosspy() {
    perl -i moss.pl -l python $1 $2
}

function spark() {
  local args=() numbers=() min= max= version="1.0.0"
  for arg in "$@"; do
    case "$arg" in
      --version|-v)
        echo "spark version $version"
        return
        ;;
      --help|-h)
        echo "usage: spark [--min=<n> --max=<n>] <numbers...>  Draw sparklines"
        echo "examples:"
        echo "       spark 1 2 3 4"
        echo "       seq 100 | sort -R | spark"
        echo "       awk '{print length}' file | spark"
        return
        ;;
      --min=*)
        min="${arg#--min=}"
        ;;
      --max=*)
        max="${arg#--max=}"
        ;;
      *)
        numbers+=("$arg")
        ;;
    esac
  done
  if [[ -t 0 && ${#numbers[@]} -eq 0 ]]; then
    echo "No input provided. Try 'spark 1 2 3 4' or pipe data in." >&2
    return 1
  fi
  awk -v MIN="$min" -v MAX="$max" '
    BEGIN {
      n = split("▁ ▂ ▃ ▄ ▅ ▆ ▇ █", blocks, " ")
      count = 0
    }
    function update_bounds(v) {
      if (MIN == "") MIN = v
      if (MAX == "") MAX = v
      if (v < MIN) MIN = v
      if (v > MAX) MAX = v
    }
    {
      for (i = 1; i <= NF; i++) {
        if ($i ~ /^-?[0-9.]+$/) {
          data[count++] = $i
          update_bounds($i)
        }
      }
    }
    END {
      scale = (MAX == MIN) ? 1 : (MAX - MIN) / (n - 1)
      for (i = 0; i < count; i++) {
        idx = (scale == 0) ? 1 : int((data[i] - MIN) / scale) + 1
        if (idx < 1) idx = 1
        if (idx > n) idx = n
        printf "%s", blocks[idx]
      }
      print ""
    }
  ' < <([[ ${#numbers[@]} -gt 0 ]] && printf "%s\n" "${numbers[@]}" || cat)
}

function letters() {
  cat "$@" | awk -vFS='' '{for(i=1;i<=NF;i++){ if($i~/[a-zA-Z]/) { w[tolower($i)]++} } }END{for(i in w) print i,w[i]}' | sort | cut -c 3- | spark | lolcat
  echo "abcdefghijklmnopqrstuvwxyz" | lolcat
}

function commits() {
  git log --author="$1" --format=format:%ad --date=short | uniq -c | awk '{print $1}' | spark | lolcat
}

function please() {
  fc -s
}

function lastarg() {
  echo $_
}

function backup() {
  cp "$1" "$1.bak"
}

function copy() {
  if [[ $# -eq 2 && -d "$1" ]]; then
    from="${1%/}"
    to="$2"
    cp -r "$from" "$to"
  else
    cp "$@"
  fi
}

function coln() {
  while read -r line; do
    echo "$line" | awk "{ print \$$1 }"
  done
}

function rown() {
  sed -n "${1}p"
}

function skip() {
  tail -n +"$(( $1 + 1 ))"
}

function take() {
  head -n "$1"
}

function cheat() {
    curl cht.sh/$1
}

function fd() {
    local dir
    dir=$(
        (zoxide query -l; find / -maxdepth 8 -type d -not -path "/proc/*" -not -path "/sys/*" -not -path "/run/*" 2>/dev/null) |
        fzf --preview 'ls -al {}' --tac
    ) && cd "$dir" && zle clear-screen
}

function search_previous() {
    zle -I              
    $HOME/.config/scripts/fzf_listoldfiles.sh
    zle reset-prompt    
}

function search_all() {
    zle -I
    $HOME/.config/scripts/zoxide_openfiles_nvim.sh
    zle reset-prompt
}

# Register them as Widgets
zle -N search_previous
zle -N search_all

# zle -N fd
bindkey '^O' search_previous 
bindkey '^[o' search_all

function rmfzf() {
    local target
    target=$(
        (find . -maxdepth 1 -type f 2>/dev/null;
        find . -maxdepth 1 -type d 2>/dev/null) |
        fzf --preview 'ls -al {}' --tac
    ) && trash "$target" && zle clear-screen
}

# zle -N rmfzf
# bindkey '^X^A' rmfzf

function nv() {
  if [[ -z "$1" ]]; then
    echo "Usage: e path/to/file"
    return 1
  fi
  local file
  file="${1/#\~/$HOME}"
  [[ "$file" != /* ]] && file="$PWD/$file"
  local dir="${file%/*}"
  if [[ "$dir" != "$file" && ! -d "$dir" ]]; then
    mkdir -p "$dir" || { echo "Failed to create directory: $dir"; return 2; }
  fi
  nvim "$file"
}

function cparse() {
  ~/.config/scripts/CPParse
}

function cpedit() {
  if [[ -z "$1" ]]; then
    echo "Usage: cpedit <problem letter>"
    return 1
  fi
  ~/.config/scripts/CPParse edit "$1"
}

function cprun() {
  if [[ -z "$1" ]]; then
    echo "Usage: cprun <problem letter>"
    return 1
  fi
  ~/.config/scripts/CPParse run "$1"
}

function cpRun() {
  ~/.config/scripts/CPParse Run
}

function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

function lolcat_clear() {
  printf "\x1b[2J\x1b[1;1H"
  echo
  seq 1 $(tput cols) | sort -R | spark | lolcat
  echo
  zle reset-prompt
}

zle -N lolcat_clear
# bindkey '^L' lolcat_clear  # Ctrl+L

function nvm() {
  unset -f nvm
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm "$@"
}

