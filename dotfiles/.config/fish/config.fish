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

function __ensure_ssh_key
    set -q SSH_AUTH_SOCK; and test -S "$SSH_AUTH_SOCK"; or return 1
    ssh-add -l >/dev/null 2>&1; or ssh-add "$HOME/.ssh/git" 2>/dev/null
end

function git --wraps=git
    __ensure_ssh_key
    command git $argv
end

function ssh --wraps=ssh
    __ensure_ssh_key
    command ssh $argv
end

# Zig Version Manager
export ZVM_INSTALL="$HOME/.zvm/self"
export PATH="$PATH:$HOME/.zvm/bin:$ZVM_INSTALL"

set --export BUN_INSTALL "$HOME/.bun"
set -Ux GOPATH $HOME/.local/go
set -Ux GOBIN  $HOME/.local/go/bin
fish_add_path  $GOBIN

# opencode
fish_add_path /home/ebits/.opencode/bin
fish_add_path /home/ebits/.kilo/bin
export PATH="/home/ebits/.local/bin:$PATH"

# Nebula shell
set -gx NEBULA_VENV "/home/ebits/.local/state/quickshell/.venv"
set -gx QML_IMPORT_PATH "$HOME/.local/lib/qt6/qml" $QML_IMPORT_PATH
