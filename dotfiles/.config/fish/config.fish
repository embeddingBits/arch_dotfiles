set fish_greeting
starship init fish | source
set -x BAT_THEME gruvbox-dark
set -x EDITOR nvim
set -x TERMINAL footclient

source ~/.config/fish/aliases.fish
export PATH="/home/ebits/.local/bin:$PATH"
zoxide init fish | source

if test -f "$HOME/.ssh/agent-env"
    set -gx SSH_AUTH_SOCK (sed -n 's/^SSH_AUTH_SOCK=\([^;]*\);.*/\1/p' "$HOME/.ssh/agent-env")
    set -gx SSH_AGENT_PID (sed -n 's/^SSH_AGENT_PID=\([^;]*\);.*/\1/p' "$HOME/.ssh/agent-env")
end
if not test -S "$SSH_AUTH_SOCK"
    ssh-agent > "$HOME/.ssh/agent-env" 2>/dev/null
    and begin
        set -gx SSH_AUTH_SOCK (sed -n 's/^SSH_AUTH_SOCK=\([^;]*\);.*/\1/p' "$HOME/.ssh/agent-env")
        set -gx SSH_AGENT_PID (sed -n 's/^SSH_AGENT_PID=\([^;]*\);.*/\1/p' "$HOME/.ssh/agent-env")
    end
end

set --export BUN_INSTALL "$HOME/.bun"
set -Ux GOPATH $HOME/.local/go
set -Ux GOBIN  $HOME/.local/go/bin
fish_add_path  $GOBIN
