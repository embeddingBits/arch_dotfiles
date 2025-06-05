if status is-interactive
    # Commands to run in interactive sessions can go here
end
set fish_greeting
starship init fish | source
fastfetch -c ~/.config/fastfetch/config.jsonc -l arch --logo-color-1 blue --logo-color-2 red
set -x BAT_THEME Nord
fish_add_path /home/amiitesh/.spicetify

function all
      sh swww-sh
end

function mon
      sh ~/automation_scripts/external-wlr/output.sh
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
