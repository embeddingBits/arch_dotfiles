function _inLimbo_completions
    set -l cur (commandline -ct)
    set -l opts \
        "--help" "Show help information" \
        "--version" "Display the version of inLimbo" \
        "--clear-cache" "Clear cached data" \
        "--show-config-file" "Show the configuration file path" \
        "--show-log-dir" "Show the log directory path" \
        "--show-dbus-name" "Show the DBus service name" \
        "--update-cache-run"   "Update the cache file and run the application" \
        "--print-song-tree"   "Print the Song Map parsed from directory" \
        "--print-artists-all"        "Print all parsed artists from Song Map" \
        "--print-songs-by-artist"    "Print all the songs of a given artist" \
        "--print-songs-by-genre-all" "Print all parsed genre and their song mappings" \
        "--print-song-info"          "Print every parsed field of a song name / filepath" \
        "--socket-info"              "Gives information on the socket binding of inLimbo" \
        "--socket-unlink-force"      "Forcibly remove the socket binding if present and undesired"
    for i in (seq 1 2 (count $opts))
        set -l opt (string trim -- $opts[$i])
        set -l desc $opts[(math $i + 1)]
        if test -z "$cur"
            echo -e "$opt\t$desc\n"
        else if string match -q -- "$cur*" $opt
            echo -e "$opt\t$desc\n"
        end
    end
end
complete -f -c inLimbo -a "(_inLimbo_completions)"
