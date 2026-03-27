# Aliases
# alias emacs="emacsclient -c -a 'emacs'"
alias zathura="$HOME/.local/bin/zathura"
alias cd="z"
alias cdi="zi"
alias la='exa -al --colour=always --icons --group-directories-first'
alias ll='exa -a --colour=always --icons --group-directories-first'
alias ls='exa -l --colour=always --icons --group-directories-first'
alias lt='exa -aT --colour=always --icons --group-directories-first'
alias l='ls'
alias l.="ls -A | egrep '^\.'"
alias listdir="ls -d */ > list"
alias depends='function_depends'

#fix obvious typo's
alias cd..='cd ..'
alias pdw='pwd'
alias udpate='sudo pacman -Syyu'
alias upate='sudo pacman -Syyu'
alias updte='sudo pacman -Syyu'
alias updqte='sudo pacman -Syyu'
alias upqll='paru -Syu --noconfirm'
alias upal='paru -Syu --noconfirm'

# !! and !$ history bindings (Zsh has this natively!)
# But you can add aliases for comfort:
alias please="fc -s"        # rerun last command (like !!)
alias lastarg='echo $_'     # print last argument of last command (like !$)

## Colorize the grep command output for ease of use (good for log files)##
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

#readable output
alias df='df -h'

#setlocale
alias setlocale="sudo localectl set-locale LANG=en_US.UTF-8"

#pacman unlock
alias unlock="sudo rm /var/lib/pacman/db.lck"
alias rmpacmanlock="sudo rm /var/lib/pacman/db.lck"
#pacman unlock
alias unlock="sudo rm /var/lib/pacman/db.lck"
alias rmpacmanlock="sudo rm /var/lib/pacman/db.lck"

# Aliases for software managment
# pacman or pm
alias pacman='sudo pacman --color auto'
alias update='sudo pacman -Syyu'
alias upd='sudo pacman -Syyu'

# paru as aur helper - updates everything
alias pksyua="paru -Syu --noconfirm"
alias upall="paru -Syu --noconfirm"
alias upa="paru -Syu --noconfirm"

#ps
alias psa="ps auxf"
alias psgrep="ps aux | grep -v grep | grep -i -e VSZ -e"

#grub update
alias update-grub="sudo grub-mkconfig -o /boot/grub/grub.cfg"
alias grub-update="sudo grub-mkconfig -o /boot/grub/grub.cfg"

#add new fonts
alias update-fc='sudo fc-cache -fv'

#switch between bash and zsh
alias tobash="sudo chsh $USER -s /bin/bash && echo 'Now log out.'"
alias tozsh="sudo chsh $USER -s /bin/zsh && echo 'Now log out.'"
alias tofish="sudo chsh $USER -s /bin/fish && echo 'Now log out.'"

#audio check pulseaudio or pipewire
alias audio="pactl info | grep 'Server Name'"

#skip integrity check
alias paruskip='paru -S --mflags --skipinteg'
alias trizenskip='trizen -S --skipinteg'

#check cpu
alias cpu="cpuid -i | grep uarch | head -n 1"

#get fastest mirrors in your neighborhood
alias mirror="sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist"
alias mirrord="sudo reflector --latest 30 --number 10 --sort delay --save /etc/pacman.d/mirrorlist"
alias mirrors="sudo reflector --latest 30 --number 10 --sort score --save /etc/pacman.d/mirrorlist"
alias mirrora="sudo reflector --latest 30 --number 10 --sort age --save /etc/pacman.d/mirrorlist"
#our experimental - best option for the moment
alias mirrorx="sudo reflector --age 6 --latest 20  --fastest 20 --threads 5 --sort rate --protocol https --save /etc/pacman.d/mirrorlist"
alias mirrorxx="sudo reflector --age 6 --latest 20  --fastest 20 --threads 20 --sort rate --protocol https --save /etc/pacman.d/mirrorlist"
alias ramm='rate-mirrors --allow-root --disable-comments arch | sudo tee /etc/pacman.d/mirrorlist'
alias ramms='rate-mirrors --allow-root --disable-comments --protocol https arch  | sudo tee /etc/pacman.d/mirrorlist'

#enabling vmware services
alias start-vmware="sudo systemctl enable --now vmtoolsd.service"
alias vmware-start="sudo systemctl enable --now vmtoolsd.service"
alias sv="sudo systemctl enable --now vmtoolsd.service"

#youtube download
alias yta-aac="yt-dlp --extract-audio --audio-format aac --embed-thumbnail"
alias yta-best="yt-dlp --extract-audio --audio-format best --embed-thumbnail"
alias yta-flac="yt-dlp --extract-audio --audio-format flac --embed-thumbnail"
alias yta-mp3="yt-dlp --extract-audio --audio-format mp3 --embed-thumbnail"
alias ytv-best="yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio' --embed-thumbnail --merge-output-format mp4 "
alias ytfzf="invidious_instance='https://vid.puffyan.us' ytfzf --rii"
alias ytfzfsub="ytfzf -fcS"

#Recent Installed Packages
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"
alias riplong="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -3000 | nl"

#Cleanup orphaned packages
alias cleanup='sudo pacman -Rns $(pacman -Qtdq)'

# This will generate a list of explicitly installed packages
alias list="sudo pacman -Qqe"
#This will generate a list of explicitly installed packages without dependencies
alias listt="sudo pacman -Qqet"
# list of AUR packages
alias listaur="sudo pacman -Qqem"
# add > list at the end to write to a file

# install packages from list
# pacman -S --needed - < my-list-of-packages.txt

#search content with ripgrep
alias rg="rg --sort path"

#shutdown or reboot
alias ssn="sudo shutdown now"
alias sr="reboot"

# DWM 
alias makedwm="cd ~/.config/dwm/dwm && rm config.h && sudo make clean install"
alias makeslstatus="cd ~/.config/dwm/slstatus/ && rm -rf config.h && make && sudo make install"
alias makeblocks="cd ~/.config/dwm/dwmblocks/ && rm -rf blocks.h && make && sudo make install"
alias makest="cd ~/.config/dwm/st && cp config.def.h config.h && make && sudo make install"
alias dotfiles="cd $HOME/dotfiles/"
alias n="nvim"

#git 
alias gs="git status"
alias ga="git add"
alias gcm="git commit -m"
alias gc="git clone"
alias gp="git push"
alias gpb="git push -u origin"
alias reposize="git count-objects -vH"

# get error messages from journalctl
alias jctl="journalctl -p 3 -xb"

alias mkcd='f() { mkdir -p "$1" && cd "$1"; }; f'
alias dev='cd /mnt/d'
alias windev='cd /mnt/c/Users/vchagant/Downloads'

alias mangaread="curl -sSL mangal.metafates.one/run | sh"
alias anime1="ani-cli"
alias anime2="anipy-cli"
alias download="aria2c"
alias fontc="fc-cache -fv"
alias autocommit="sh ~/dotfiles/gitAutoCommitter.sh"
alias rm="trash-put"
alias tls="trash-list"
alias trs="restore-trash"
alias te="trash-empty"
alias lzd="lazydocker"
alias exmod="chmod +x"
alias lg="lazygit"
alias cls="clear"
alias cat='bat --style header --style snip --style changes --style header'
alias fman="compgen -c | fzf | xargs man"
alias open='wslview'    # opens files/URLs in Windows default app
alias pbcopy='clip.exe'
alias pbpaste='powershell.exe -command "Get-Clipboard"'
