function fetch --wraps='fastfetch -c ~/.config/fastfetch/small.jsonc --logo-color-1 blue --logo-color-2 red' --description 'alias fetch fastfetch -c ~/.config/fastfetch/small.jsonc --logo-color-1 blue --logo-color-2 red'
    fastfetch -c ~/.config/fastfetch/small.jsonc --logo-color-1 blue --logo-color-2 red $argv
end

function ls --wraps=exa --wraps='exa --icons' --description 'alias ls exa --icons'
    eza $argv --icons
end

function nv --wraps=nvim --description 'alias nv nvim'
    nvim $argv
end

# Git commands
alias gt="git status"
alias gp="git push"
alias ga="git add"
alias gl="git log"
alias gc="git commit -m"
alias gu="git pull"

# Common Commands
alias j="z"
alias tree="ls --tree"
alias zb="zig build"
alias upfor="uptime -p"

# Pacman aliases (Arch)
alias xi="sudo pacman -S"
alias xr="sudo pacman -Rns"
alias xu="sudo pacman -Syu"
# AUR helper (uncomment if using yay/paru)
# alias xi="yay -S"
# alias xr="yay -Rns"
# alias xu="yay -Syu"

# System
alias shutdown="loginctl poweroff"
alias reboot="sudo reboot"

# Tmux aliases
alias tnew="tmux new -s"
alias tls="tmux ls"
alias ta="tmux attach -t"
alias td="tmux detach"
