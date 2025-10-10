if status is-interactive
    # Commands to run in interactive sessions can go here
end
set fish_greeting
starship init fish | source
set -x BAT_THEME Nord
set -x EDITOR nvim
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


set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
