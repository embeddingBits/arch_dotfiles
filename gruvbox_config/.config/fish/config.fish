if status is-interactive
    # Commands to run in interactive sessions can go here
end
set fish_greeting
starship init fish | source
set -x BAT_THEME gruvbox-dark
set -x EDITOR nvim
set -x TERMINAL ghostty
fish_add_path /home/amiitesh/.spicetify

function fastfetch_big
      fastfetch -c ~/.config/fastfetch/large.jsonc --logo-color-1 blue --logo-color-2 red
end

function fetch
      fastfetch -c ~/.config/fastfetch/small.jsonc --logo-color-1 blue --logo-color-2 red
end

function mus
      systemctl --user enable --now mpd.service && rmpc && systemctl --user stop mpd.service && systemctl --user disable mpd.service
end

function mirrorOut
      wlr-randr --output HDMI-A-1 --mode 1920x1080 --pos 0,0
end

function dual
      wlr-randr --output HDMI-A-1 --pos 0,0 --output eDP-1 --pos 1920,0
end

function f
      feh --scale-down --auto-zoom --geometry 1100x800 --no-menus --image-bg black $argv
end

function nv
      nvim $argv
end

function ls
    set -l exa_args

    for arg in $argv
        switch $arg
            case '-l'
                set exa_args $exa_args '--long'
            case '-a'
                set exa_args $exa_args '--all'
            case '-la' '-al'
                set exa_args $exa_args '--long' '--all'
            case '-h'
                set exa_args $exa_args '--header'
            case '-t'
                set exa_args $exa_args '--sort=modified'
            case '-r'
                set exa_args $exa_args '--reverse'
            case '*'
                set exa_args $exa_args $arg
        end
    end

    exa --icons $exa_args
end

if not set -q SSH_AUTH_SOCK
    ssh-agent -c >/tmp/ssh-agent.fish
    source /tmp/ssh-agent.fish >/dev/null
end

set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
source /home/ebits/.config/fish/completions/inLimbo.fish
