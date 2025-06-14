fastfetch -c ~/.config/fastfetch/config.jsonc -l arch --logo-color-1 blue --logo-color-2 red

# ---------------------------------------
# Zinit Bootstrap
# ---------------------------------------
if [[ ! -f ~/.zinit/bin/zinit.zsh ]]; then
  mkdir -p ~/.zinit && git clone https://github.com/zdharma-continuum/zinit.git ~/.zinit/bin
fi
source ~/.zinit/bin/zinit.zsh

# ---------------------------------------
# Starship Prompt
# ---------------------------------------
eval "$(starship init zsh)"

# ---------------------------------------
# Zsh Options
# ---------------------------------------
setopt prompt_subst           # allow variables in prompt
setopt autocd                 # cd by just typing directory
setopt extended_glob          # extended globbing
setopt hist_ignore_dups       # ignore duplicate history entries
setopt share_history          # share command history across sessions
unsetopt correct
unsetopt correct_all
# ---------------------------------------
# History Config
# ---------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# ---------------------------------------
# Completion Behavior
# ---------------------------------------
autoload -Uz compinit && compinit

zstyle ':completion:*' menu select                   # enable menu selection on <Tab>
zstyle ':completion:*' group-name ''                 # disable groupings (e.g. -- alias --)
zstyle ':completion:*' format ''                     # disable section titles
zstyle ':completion:*' list-colors 'fi=34'
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
# ---------------------------------------
# Plugins via Zinit
# ---------------------------------------

# Autosuggestions like Fish
zinit light zsh-users/zsh-autosuggestions

# Syntax highlighting (MUST BE LAST)
zinit light zsh-users/zsh-syntax-highlighting

# Syntax Highlighting
ZSH_HIGHLIGHT_STYLES[command]='fg=blue'
ZSH_HIGHLIGHT_STYLES[alias]='fg=blue'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=cyan'                 # Also applies to commands
ZSH_HIGHLIGHT_STYLES[builtin]='fg=blue'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=blue'           # Like `sudo`, `command`, etc.
ZSH_HIGHLIGHT_STYLES[option]='fg=cyan'             # Options like -fsSL
ZSH_HIGHLIGHT_STYLES[argument]='fg=white'            # Command args like filenames
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[path]='fg=cyan'                 # Files and directories
ZSH_HIGHLIGHT_STYLES[globbing]='fg=magenta'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=green'    # The `|` pipe
ZSH_HIGHLIGHT_STYLES[assign]='fg=white'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=green'
ZSH_HIGHLIGHT_STYLES[comment]='fg=242'               # Comments gray
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
# ---------------------------------------
# Aliases & UI
# ---------------------------------------
alias ls='exa --icons --color=always'
alias ll='exa -lah --icons --color=always'
alias cat='bat --style=plain --paging=never'

# ---------------------------------------
# Editor & Path
# ---------------------------------------
export EDITOR="nvim"
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

