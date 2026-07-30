set fish_greeting
starship init fish | source
set -x BAT_THEME gruvbox-dark
set -x EDITOR nvim
set -x TERMINAL footclient

source ~/.config/fish/aliases.fish
zoxide init fish | source

# Start SSH agent if not already running
if not set -q SSH_AUTH_SOCK
    eval (ssh-agent -c)
    set -Ux SSH_AUTH_SOCK $SSH_AUTH_SOCK
    set -Ux SSH_AGENT_PID $SSH_AGENT_PID
end

# Zig Version Manager
export ZVM_INSTALL="$HOME/.zvm/self"
export PATH="$PATH:$HOME/.zvm/bin:$ZVM_INSTALL"

set -Ux PATH /opt/cuda/bin $PATH
set -Ux LD_LIBRARY_PATH /opt/cuda/lib64 $LD_LIBRARY_PATH
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
set -Ux GOPATH $HOME/.local/go
set -Ux GOBIN  $HOME/.local/go/bin
fish_add_path  $GOBIN

# opencode
fish_add_path /home/ebits/.opencode/bin
