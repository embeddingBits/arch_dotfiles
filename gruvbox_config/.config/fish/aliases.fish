function fetch --wraps='fastfetch -c ~/.config/fastfetch/small.jsonc --logo-color-1 blue --logo-color-2 red' --description 'alias fetch fastfetch -c ~/.config/fastfetch/small.jsonc --logo-color-1 blue --logo-color-2 red'
    fastfetch -c ~/.config/fastfetch/small.jsonc --logo-color-1 blue --logo-color-2 red $argv
end

function ls --wraps=exa --wraps='exa --icons' --description 'alias ls exa --icons'
    exa --icons $argv
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

# Pacman aliases
alias pac="sudo pacman"
alias pacref="sudo pacman -Syy"
alias pacup="sudo pacman -Syyu"

# Tmux aliases
alias tnew="tmux new -s"
alias tls="tmux ls"
alias ta="tmux attach -t"
alias td="tmux detach"
