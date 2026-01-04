function fetch --wraps='fastfetch -c ~/.config/fastfetch/small.jsonc --logo-color-1 blue --logo-color-2 red' --description 'alias fetch fastfetch -c ~/.config/fastfetch/small.jsonc --logo-color-1 blue --logo-color-2 red'
    fastfetch -c ~/.config/fastfetch/small.jsonc --logo-color-1 blue --logo-color-2 red $argv
end

function ls --wraps=exa --wraps='exa --icons' --description 'alias ls exa --icons'
    exa --icons $argv
end

function nv --wraps=nvim --description 'alias nv nvim'
    nvim $argv
end

alias tree="ls --tree"
alias pac="sudo pacman"
alias pacref="sudo pacman -Syy"
alias pacup="sudo pacman -Syyu"
alias aur="yay -S"
