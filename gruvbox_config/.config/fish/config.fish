set fish_greeting
starship init fish | source
set -x BAT_THEME gruvbox-dark
set -x EDITOR nvim
set -x TERMINAL ghostty

source ~/.config/fish/aliases.fish
zoxide init fish | source

# ssh agent
set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket

set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
source /home/ebits/.config/fish/completions/inLimbo.fish
set -Ux GOPATH $HOME/.local/go
set -Ux GOBIN  $HOME/.local/go/bin
fish_add_path  $GOBIN

