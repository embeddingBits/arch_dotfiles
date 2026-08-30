# Print an optspec for argparse to handle cmd's options that are independent of any subcommand.
function __fish_grok_global_optspecs
	string join \n v/version cwd= leader-socket= debug debug-file= always-approve trust allow= deny= p/single= prompt-json= prompt-file= verbatim output-format= include-partial-messages json-schema= m/model= reasoning-effort= rules= compaction-mode= compaction-detail= system-prompt-override= r/resume= load= c/continue s/session-id= fork-session w/worktree= worktree-ref= restore-code no-plan no-subagents no-ask-user experimental-memory no-memory memory-flush agent= agents= tools= disallowed-tools= max-turns= permission-mode= disable-web-search no-wait-for-background background-wait-timeout= sandbox= storage-mode= client-identifier= hunk-tracker-mode= terminal fs-read fs-write no-auto-update todo-gate installer= no-alt-screen minimal fullscreen log-sampling force-login oauth leader no-leader h/help
end

function __fish_grok_needs_command
	# Figure out if the current invocation already has a command.
	set -l cmd (commandline -opc)
	set -e cmd[1]
	argparse -s (__fish_grok_global_optspecs) -- $cmd 2>/dev/null
	or return
	if set -q argv[1]
		# Also print the command, so this can be used to figure out what it is.
		echo $argv[1]
		return 1
	end
	return 0
end

function __fish_grok_using_subcommand
	set -l cmd (__fish_grok_needs_command)
	test -z "$cmd"
	and return 1
	contains -- $cmd[1] $argv
end

complete -c grok -n "__fish_grok_needs_command" -l cwd -d 'Working directory' -r -F
complete -c grok -n "__fish_grok_needs_command" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_needs_command" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_needs_command" -l allow -d 'Permission allow rule (compat alias: --allowedTools)' -r
complete -c grok -n "__fish_grok_needs_command" -l deny -d 'Permission deny rule (compat alias: --disallowedTools)' -r
complete -c grok -n "__fish_grok_needs_command" -s p -l single -d 'Single-turn prompt. Prints the response to stdout and exits' -r
complete -c grok -n "__fish_grok_needs_command" -l prompt-json -d 'Single-turn prompt as JSON content blocks' -r
complete -c grok -n "__fish_grok_needs_command" -l prompt-file -d 'Single-turn prompt from a file' -r -F
complete -c grok -n "__fish_grok_needs_command" -l output-format -d 'Output format for headless mode' -r -f -a "plain\t''
json\t''
streaming-json\t'NDJSON: one ACP session update per line, the agent\'s native format'
streaming-messages-json\t'NDJSON in the Anthropic Messages API wire format'"
complete -c grok -n "__fish_grok_needs_command" -l json-schema -d 'JSON Schema for structured output. When set, the model is constrained to produce JSON matching this schema. Implies --output-format json. Example: --json-schema \'{"type":"object","properties":{"name":{"type":"string"}}}\'' -r
complete -c grok -n "__fish_grok_needs_command" -s m -l model -d 'Model ID to use' -r
complete -c grok -n "__fish_grok_needs_command" -l reasoning-effort -l effort -d 'Reasoning effort for reasoning models' -r
complete -c grok -n "__fish_grok_needs_command" -l rules -d 'Extra rules to append to the system prompt' -r
complete -c grok -n "__fish_grok_needs_command" -l compaction-mode -d 'Compaction mode [summary|transcript|segments]. `summary` adds no pointer; `transcript` points at the raw transcript; `segments` (default) persists per-segment markdown to grep. Sets `GROK_COMPACTION_MODE`' -r
complete -c grok -n "__fish_grok_needs_command" -l compaction-detail -d 'Segments verbatim detail [none|minimal|balanced|verbose] (default `verbose`). Only affects `--compaction-mode segments`. Sets `GROK_COMPACTION_DETAIL`' -r
complete -c grok -n "__fish_grok_needs_command" -l system-prompt-override -d 'Override the agent\'s system prompt (compat alias: --system-prompt)' -r
complete -c grok -n "__fish_grok_needs_command" -s r -l resume -d 'Resume a session by ID or title, or the most recent if omitted. Non-ID values match session titles for the current directory, ignoring letter case; UUID-shaped values always mean IDs. Among duplicate titles a sole renamed match wins; otherwise the resume fails as ambiguous' -r
complete -c grok -n "__fish_grok_needs_command" -l load -d 'Resume a previous session by session ID (alias for --resume)' -r
complete -c grok -n "__fish_grok_needs_command" -s s -l session-id -d 'Use a specific session UUID for a **new** conversation (must be a valid UUID and must not already exist under the target session directory). With `--resume`/`--continue`, only valid together with `--fork-session` (names the forked session). Does not resume existing sessions, use `--resume` / `--continue` instead' -r
complete -c grok -n "__fish_grok_needs_command" -s w -l worktree -d 'Start the session in a new git worktree, optionally named. With `--resume` of a remote session, pass `--restore-code` to apply the snapshot codebase (conversation is restored either way). Headless (`-p`) does not create a worktree from this flag' -r
complete -c grok -n "__fish_grok_needs_command" -l worktree-ref -l ref -d 'Branch, tag, or commit to base the worktree on (with `--worktree`). Defaults to the current HEAD of the source checkout when omitted' -r
complete -c grok -n "__fish_grok_needs_command" -l agent -d 'Agent name or definition file path' -r
complete -c grok -n "__fish_grok_needs_command" -l agents -d 'Inline subagent definitions as JSON' -r
complete -c grok -n "__fish_grok_needs_command" -l tools -d 'Built-in tools to allow (comma-separated)' -r
complete -c grok -n "__fish_grok_needs_command" -l disallowed-tools -d 'Built-in tools to remove (comma-separated)' -r
complete -c grok -n "__fish_grok_needs_command" -l max-turns -d 'Maximum number of agent turns' -r
complete -c grok -n "__fish_grok_needs_command" -l permission-mode -d 'Permission mode' -r -f -a "default\t''
acceptEdits\t''
auto\t''
dontAsk\t''
bypassPermissions\t''
plan\t''"
complete -c grok -n "__fish_grok_needs_command" -l background-wait-timeout -d 'Max seconds to wait for background work after the first turn ends (headless only). Applies to bash/monitor `task_completed`, background subagents (`SubagentFinished`), and any still-running non-persistent work. Persistent `monitor(persistent:true)` never completes and always waits the full timeout. Use `--no-wait-for-background` or a lower timeout for throughput. Conflicts with `--no-wait-for-background`' -r
complete -c grok -n "__fish_grok_needs_command" -l sandbox -d 'Sandbox profile for filesystem and network access' -r
complete -c grok -n "__fish_grok_needs_command" -l storage-mode -d 'Session storage mode: local or writeback' -r
complete -c grok -n "__fish_grok_needs_command" -l client-identifier -d 'Override the client identifier sent to the agent' -r
complete -c grok -n "__fish_grok_needs_command" -l hunk-tracker-mode -d 'Hunk tracker mode: agent_only, all_dirty, or off ("disabled" is an alias for off, which turns the hunk tracker off entirely)' -r
complete -c grok -n "__fish_grok_needs_command" -l installer -d 'Set the installer field in config.toml' -r
complete -c grok -n "__fish_grok_needs_command" -s v -l version -d 'Print version'
complete -c grok -n "__fish_grok_needs_command" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_needs_command" -l always-approve -d 'Auto-approve all tool executions'
complete -c grok -n "__fish_grok_needs_command" -l trust -d 'Trust this folder and persist the decision to the trust store'
complete -c grok -n "__fish_grok_needs_command" -l verbatim -d 'Send the prompt exactly as given'
complete -c grok -n "__fish_grok_needs_command" -l include-partial-messages -d 'Emit incremental `stream_event` lines (text/thinking deltas) alongside whole messages. Only affects `--output-format streaming-messages-json`'
complete -c grok -n "__fish_grok_needs_command" -s c -l continue -d 'Continue the most recent session for the current working directory'
complete -c grok -n "__fish_grok_needs_command" -l fork-session -d 'When resuming (`--resume` / `--continue`), create a new session ID instead of reusing the original (optionally set via `--session-id`)'
complete -c grok -n "__fish_grok_needs_command" -l restore-code -d 'Restore the original session\'s repository snapshot when resuming. Remote sessions require `--worktree` (never checks out into the current directory). Without this flag, resume restores conversation only'
complete -c grok -n "__fish_grok_needs_command" -l no-plan -d 'Disable plan mode'
complete -c grok -n "__fish_grok_needs_command" -l no-subagents -d 'Disable subagent spawning'
complete -c grok -n "__fish_grok_needs_command" -l no-ask-user -d 'Disable structured question prompts from the agent'
complete -c grok -n "__fish_grok_needs_command" -l experimental-memory -d 'Legacy compatibility flag for enabling cross-session memory'
complete -c grok -n "__fish_grok_needs_command" -l no-memory -d 'Legacy compatibility flag for disabling cross-session memory'
complete -c grok -n "__fish_grok_needs_command" -l memory-flush -d 'Run a memory flush after the headless turn (or instead of a prompt when resuming). Calls `x.ai/memory/flush` and waits for the flush LLM. Headless only: `/flush` as `-p` text is not a reliable flush trigger'
complete -c grok -n "__fish_grok_needs_command" -l disable-web-search -d 'Disable web search and web fetch tools'
complete -c grok -n "__fish_grok_needs_command" -l no-wait-for-background -d 'Exit as soon as the first agent turn ends, without waiting for pending background bash/monitor tasks or background subagents (headless only). Default for all `grok -p` runs is to wait (up to `--background-wait-timeout`) so eval harnesses see full task completion. Use this for fast scripts that only need the first turn\'s text. Does not wait for server-side auto-wake output or persistent monitors (those hit the timeout)'
complete -c grok -n "__fish_grok_needs_command" -l terminal -d 'Enable terminal support for the agent'
complete -c grok -n "__fish_grok_needs_command" -l fs-read -d 'Enable client-side file reads'
complete -c grok -n "__fish_grok_needs_command" -l fs-write -d 'Enable client-side file writes'
complete -c grok -n "__fish_grok_needs_command" -l no-auto-update -d 'Disable automatic updates for this session'
complete -c grok -n "__fish_grok_needs_command" -l todo-gate -d 'Enable the runtime turn-end TodoGate for this session'
complete -c grok -n "__fish_grok_needs_command" -l no-alt-screen -d 'Run inline instead of using the terminal alternate screen'
complete -c grok -n "__fish_grok_needs_command" -l minimal -d 'Experimental: scrollback-native rendering. Finalized blocks are printed into the terminal\'s native scrollback (use the terminal\'s own scroll / selection). A small pinned region holds the prompt and running turn. Session-scoped only, does not write config. To default plain `grok` to minimal, set `[ui] screen_mode = "minimal"` in ~/.grok/config.toml'
complete -c grok -n "__fish_grok_needs_command" -l fullscreen -d 'Open in the standard fullscreen TUI for this session, overriding a config `[ui] screen_mode = "minimal"` preference. Session-scoped only, does not write config. Fullscreen-vs-inline still follows the alt-screen policy (--no-alt-screen, [terminal] alt_screen, terminal auto-detection)'
complete -c grok -n "__fish_grok_needs_command" -l log-sampling -d 'Write sampling events to ~/.grok/logs/sampling.jsonl'
complete -c grok -n "__fish_grok_needs_command" -l force-login -d 'Show the login screen even when credentials are already available'
complete -c grok -n "__fish_grok_needs_command" -l oauth -d 'Use OAuth when the welcome screen starts authentication'
complete -c grok -n "__fish_grok_needs_command" -l leader -d 'Connect to a shared leader process'
complete -c grok -n "__fish_grok_needs_command" -l no-leader -d 'Run standalone even when leader mode is configured'
complete -c grok -n "__fish_grok_needs_command" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c grok -n "__fish_grok_needs_command" -a "agent" -d 'Run Grok without the interactive UI'
complete -c grok -n "__fish_grok_needs_command" -a "inspect" -d 'Show the configuration Grok discovers for this directory'
complete -c grok -n "__fish_grok_needs_command" -a "doctor" -d 'Check terminal, clipboard, color, and input support without starting Grok'
complete -c grok -n "__fish_grok_needs_command" -a "leader" -d 'Manage running leader processes'
complete -c grok -n "__fish_grok_needs_command" -a "logout" -d 'Sign out and clear cached credentials'
complete -c grok -n "__fish_grok_needs_command" -a "login" -d 'Sign in to Grok'
complete -c grok -n "__fish_grok_needs_command" -a "mcp" -d 'Manage MCP server configurations'
complete -c grok -n "__fish_grok_needs_command" -a "plugin" -d 'Manage plugins and marketplace sources'
complete -c grok -n "__fish_grok_needs_command" -a "memory" -d 'Manage cross-session memory'
complete -c grok -n "__fish_grok_needs_command" -a "models" -d 'List available models and exit'
complete -c grok -n "__fish_grok_needs_command" -a "sessions" -d 'List, search, or restore sessions'
complete -c grok -n "__fish_grok_needs_command" -a "setup" -d 'Fetch and install managed configuration'
complete -c grok -n "__fish_grok_needs_command" -a "share" -d 'Share a session and print the share URL'
complete -c grok -n "__fish_grok_needs_command" -a "wrap" -d 'Run any command with local clipboard support (forwards OSC 52 to the system clipboard)'
complete -c grok -n "__fish_grok_needs_command" -a "export" -d 'Export a session transcript as Markdown'
complete -c grok -n "__fish_grok_needs_command" -a "trace" -d 'Export or upload session trace data'
complete -c grok -n "__fish_grok_needs_command" -a "update" -d 'Check for updates or install a specific version'
complete -c grok -n "__fish_grok_needs_command" -a "version" -d 'Print version information'
complete -c grok -n "__fish_grok_needs_command" -a "v" -d 'Print version information'
complete -c grok -n "__fish_grok_needs_command" -a "completions" -d 'Generate shell completion scripts (bash, zsh, fish, powershell, ...)'
complete -c grok -n "__fish_grok_needs_command" -a "worktree" -d 'Manage git worktrees'
complete -c grok -n "__fish_grok_needs_command" -a "clone" -d 'Lazy-clone a git repository via grove (NFS on macOS, FUSE on Linux)'
complete -c grok -n "__fish_grok_needs_command" -a "du" -d 'Show what the grok home (~/.grok) uses on disk'
complete -c grok -n "__fish_grok_needs_command" -a "disk-usage" -d 'Show what the grok home (~/.grok) uses on disk'
complete -c grok -n "__fish_grok_needs_command" -a "workspace" -d 'Expose this workspace to the Computer Hub (via the leader)'
complete -c grok -n "__fish_grok_needs_command" -a "dashboard" -d 'Open the Agent Dashboard view at startup'
complete -c grok -n "__fish_grok_needs_command" -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -s m -l model -d 'Model ID to use' -r
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l reasoning-effort -l effort -d 'Reasoning effort for reasoning models' -r
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l agent-profile -d 'Path to an agent profile file' -r -F
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l plugin-dir -d 'Load a plugin from this directory for this process only (repeatable). Highest-priority plugin scope; always trusted: hooks and MCP servers activate without a prompt. Used by the Agent SDKs to inject per-connection plugins' -r -f -a "(__fish_complete_directories)"
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l grok-ws-origin -r
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l grok-ws-url -r
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l cli-chat-proxy-base-url -d 'Override the CLI chat proxy base URL' -r
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l xai-api-base-url -d 'Override the public xAI API base URL' -r
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l reauth -l --reauthenticate -d 'Run authentication before starting the agent'
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l always-approve -d 'Auto-approve all tool executions'
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l leader -d 'Connect to a shared leader process instead of starting a new agent. Allows multiple clients to share one backend. Defaults to [cli] use_leader in config.toml'
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l no-leader -d 'Start a new agent even when config enables leader mode'
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -f -a "stdio" -d 'Run the agent over stdio'
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -f -a "headless" -d 'Run the agent headlessly over the Grok WebSocket relay'
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -f -a "serve" -d 'Run the agent as a WebSocket server'
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -f -a "leader" -d 'Run as the shared leader process for other clients'
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from stdio" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from stdio" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from stdio" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from stdio" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from headless" -l grok-ws-origin -r
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from headless" -l grok-ws-url -r
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from headless" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from headless" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from headless" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from headless" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from serve" -l bind -d 'Address for the server to listen on' -r
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from serve" -l secret -d 'Secret token for client authentication (auto-generated if not provided)' -r
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from serve" -l remote -d 'Remote agent URL for proxy mode' -r
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from serve" -l grok-ws-origin -r
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from serve" -l grok-ws-url -r
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from serve" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from serve" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from serve" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from serve" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from leader" -l grok-ws-origin -r
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from leader" -l grok-ws-url -r
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from leader" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from leader" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from leader" -l no-exit-on-disconnect -d 'Keep the leader running after the last client disconnects'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from leader" -l relay-on-demand -d 'Defer the grok.com relay WebSocket until the first headless IPC client registers. Without this flag the leader connects the relay eagerly at startup. Bare leaders (headless remote env / systemd) need the eager connect: they receive remote prompts *through* the relay. Passed by leaders auto-spawned from interactive clients (TUI/IDE), which only need the relay if a headless client appears'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from leader" -l no-auto-update -d 'Disable periodic auto-update checks for the leader'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from leader" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from leader" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from help" -f -a "stdio" -d 'Run the agent over stdio'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from help" -f -a "headless" -d 'Run the agent headlessly over the Grok WebSocket relay'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from help" -f -a "serve" -d 'Run the agent as a WebSocket server'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from help" -f -a "leader" -d 'Run as the shared leader process for other clients'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand inspect" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand inspect" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand inspect" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand inspect" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand inspect" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand doctor; and not __fish_seen_subcommand_from fix help" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand doctor; and not __fish_seen_subcommand_from fix help" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand doctor; and not __fish_seen_subcommand_from fix help" -l json -d 'Print the diagnostic report as JSON'
complete -c grok -n "__fish_grok_using_subcommand doctor; and not __fish_seen_subcommand_from fix help" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand doctor; and not __fish_seen_subcommand_from fix help" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand doctor; and not __fish_seen_subcommand_from fix help" -f -a "fix" -d 'Apply an automatic fix'
complete -c grok -n "__fish_grok_using_subcommand doctor; and not __fish_seen_subcommand_from fix help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand doctor; and __fish_seen_subcommand_from fix" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand doctor; and __fish_seen_subcommand_from fix" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand doctor; and __fish_seen_subcommand_from fix" -l yes -d 'Apply the displayed changes without confirmation'
complete -c grok -n "__fish_grok_using_subcommand doctor; and __fish_seen_subcommand_from fix" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand doctor; and __fish_seen_subcommand_from fix" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand doctor; and __fish_seen_subcommand_from help" -f -a "fix" -d 'Apply an automatic fix'
complete -c grok -n "__fish_grok_using_subcommand doctor; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand leader; and not __fish_seen_subcommand_from list info kill help" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand leader; and not __fish_seen_subcommand_from list info kill help" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand leader; and not __fish_seen_subcommand_from list info kill help" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand leader; and not __fish_seen_subcommand_from list info kill help" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand leader; and not __fish_seen_subcommand_from list info kill help" -f -a "list" -d 'List running leader processes'
complete -c grok -n "__fish_grok_using_subcommand leader; and not __fish_seen_subcommand_from list info kill help" -f -a "info" -d 'Show details for a leader process'
complete -c grok -n "__fish_grok_using_subcommand leader; and not __fish_seen_subcommand_from list info kill help" -f -a "kill" -d 'Stop all running leader processes'
complete -c grok -n "__fish_grok_using_subcommand leader; and not __fish_seen_subcommand_from list info kill help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from list" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from list" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from list" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from list" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from info" -l pid -d 'Leader process ID from `grok leader list`' -r
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from info" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from info" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from info" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from info" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from info" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from kill" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from kill" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from kill" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from kill" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from help" -f -a "list" -d 'List running leader processes'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from help" -f -a "info" -d 'Show details for a leader process'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from help" -f -a "kill" -d 'Stop all running leader processes'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand logout" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand logout" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand logout" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand logout" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand login" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand login" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand login" -l legacy -d 'Ignored (kept for backwards compatibility). OAuth2 is now the only auth method'
complete -c grok -n "__fish_grok_using_subcommand login" -l oauth -d 'Use Grok OAuth via auth.x.ai'
complete -c grok -n "__fish_grok_using_subcommand login" -l device-auth -l device-code -d 'Use device-code authentication for headless/remote environments'
complete -c grok -n "__fish_grok_using_subcommand login" -l devbox -d 'Authenticate for remote development environments (hidden)'
complete -c grok -n "__fish_grok_using_subcommand login" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand login" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand mcp; and not __fish_seen_subcommand_from list add remove enable disable doctor help" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand mcp; and not __fish_seen_subcommand_from list add remove enable disable doctor help" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand mcp; and not __fish_seen_subcommand_from list add remove enable disable doctor help" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand mcp; and not __fish_seen_subcommand_from list add remove enable disable doctor help" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand mcp; and not __fish_seen_subcommand_from list add remove enable disable doctor help" -f -a "list" -d 'List configured MCP servers'
complete -c grok -n "__fish_grok_using_subcommand mcp; and not __fish_seen_subcommand_from list add remove enable disable doctor help" -f -a "add" -d 'Add or update an MCP server'
complete -c grok -n "__fish_grok_using_subcommand mcp; and not __fish_seen_subcommand_from list add remove enable disable doctor help" -f -a "remove" -d 'Remove an MCP server'
complete -c grok -n "__fish_grok_using_subcommand mcp; and not __fish_seen_subcommand_from list add remove enable disable doctor help" -f -a "enable" -d 'Enable an MCP server'
complete -c grok -n "__fish_grok_using_subcommand mcp; and not __fish_seen_subcommand_from list add remove enable disable doctor help" -f -a "disable" -d 'Disable an MCP server'
complete -c grok -n "__fish_grok_using_subcommand mcp; and not __fish_seen_subcommand_from list add remove enable disable doctor help" -f -a "doctor" -d 'Diagnose MCP server configuration and connectivity'
complete -c grok -n "__fish_grok_using_subcommand mcp; and not __fish_seen_subcommand_from list add remove enable disable doctor help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from list" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from list" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from list" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from list" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from add" -s t -l transport -d 'Transport type. Defaults to stdio, or to http when the positional argument is an http(s):// URL' -r -f -a "stdio\t'Launch a local process and communicate over stdin/stdout'
http\t'Connect to a remote server over streamable HTTP'
sse\t'Connect to a remote server over Server-Sent Events'"
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from add" -s s -l scope -d 'Config to write to: user (~/.grok/config.toml) or project (./.grok/config.toml)' -r -f -a "user\t'`~/.grok/config.toml`, available in all your projects'
project\t'`./.grok/config.toml`, shared with everyone working in this directory'"
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from add" -s e -l env -d 'Environment variable for the server process (repeatable)' -r
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from add" -s H -l header -d 'HTTP header for remote servers (repeatable)' -r
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from add" -l command -d 'Legacy alias for the positional command argument' -r
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from add" -l args -d 'Legacy companion to --command' -r
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from add" -l url -d 'Legacy alias for adding a remote server by URL' -r
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from add" -l type -d 'Legacy transport type for --url servers' -r
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from add" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from add" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from add" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from add" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from remove" -s s -l scope -d 'Config to remove from. When omitted, all scopes are searched' -r -f -a "user\t'`~/.grok/config.toml`, available in all your projects'
project\t'`./.grok/config.toml`, shared with everyone working in this directory'"
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from remove" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from remove" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from remove" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from remove" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from enable" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from enable" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from enable" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from enable" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from disable" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from disable" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from disable" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from disable" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from doctor" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from doctor" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from doctor" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from doctor" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from doctor" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from help" -f -a "list" -d 'List configured MCP servers'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from help" -f -a "add" -d 'Add or update an MCP server'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from help" -f -a "remove" -d 'Remove an MCP server'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from help" -f -a "enable" -d 'Enable an MCP server'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from help" -f -a "disable" -d 'Disable an MCP server'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from help" -f -a "doctor" -d 'Diagnose MCP server configuration and connectivity'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "list" -d 'List installed plugins'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "install" -d 'Install a plugin from a git URL or local path'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "uninstall" -d 'Uninstall an installed plugin by name'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "rm" -d 'Uninstall an installed plugin by name'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "remove" -d 'Uninstall an installed plugin by name'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "update" -d 'Update installed plugin(s)'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "enable" -d 'Enable a disabled plugin'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "disable" -d 'Disable a plugin without uninstalling it'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "details" -d 'Show a plugin\'s component inventory'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "validate" -d 'Validate a plugin manifest'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "tag" -d 'Create a release git tag from the plugin\'s manifest version'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "marketplace" -d 'Manage marketplace sources'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from list" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from list" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from list" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from list" -l available -d 'Include available plugins from marketplace sources. Requires --json'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from list" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from install" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from install" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from install" -l trust -d 'Trust the plugin immediately (skip confirmation prompt)'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from install" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from install" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from uninstall" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from uninstall" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from uninstall" -l confirm -d 'Skip confirmation for multi-plugin repos'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from uninstall" -l keep-data -d 'Preserve the plugin\'s persistent data directory'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from uninstall" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from uninstall" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from rm" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from rm" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from rm" -l confirm -d 'Skip confirmation for multi-plugin repos'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from rm" -l keep-data -d 'Preserve the plugin\'s persistent data directory'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from rm" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from rm" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from remove" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from remove" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from remove" -l confirm -d 'Skip confirmation for multi-plugin repos'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from remove" -l keep-data -d 'Preserve the plugin\'s persistent data directory'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from remove" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from remove" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from update" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from update" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from update" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from update" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from enable" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from enable" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from enable" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from enable" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from disable" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from disable" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from disable" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from disable" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from details" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from details" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from details" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from details" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from validate" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from validate" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from validate" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from validate" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from tag" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from tag" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from tag" -l push -d 'Push the tag to the remote after creating it'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from tag" -s f -l force -d 'Create the tag even if the working tree is dirty or tag exists'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from tag" -l dry-run -d 'Print what would be tagged without creating the tag'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from tag" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from tag" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from marketplace" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from marketplace" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from marketplace" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from marketplace" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from marketplace" -f -a "list" -d 'List configured marketplace sources and their plugins'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from marketplace" -f -a "add" -d 'Add a marketplace source (git URL, GitHub shorthand, or local path)'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from marketplace" -f -a "remove" -d 'Remove a marketplace source and uninstall its plugins'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from marketplace" -f -a "update" -d 'Refresh marketplace source(s) and sync git caches'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from marketplace" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "list" -d 'List installed plugins'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "install" -d 'Install a plugin from a git URL or local path'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "uninstall" -d 'Uninstall an installed plugin by name'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "update" -d 'Update installed plugin(s)'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "enable" -d 'Enable a disabled plugin'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "disable" -d 'Disable a plugin without uninstalling it'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "details" -d 'Show a plugin\'s component inventory'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "validate" -d 'Validate a plugin manifest'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "tag" -d 'Create a release git tag from the plugin\'s manifest version'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "marketplace" -d 'Manage marketplace sources'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand memory; and not __fish_seen_subcommand_from clear help" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand memory; and not __fish_seen_subcommand_from clear help" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand memory; and not __fish_seen_subcommand_from clear help" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand memory; and not __fish_seen_subcommand_from clear help" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand memory; and not __fish_seen_subcommand_from clear help" -f -a "clear" -d 'Clear memory files (workspace by default)'
complete -c grok -n "__fish_grok_using_subcommand memory; and not __fish_seen_subcommand_from clear help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand memory; and __fish_seen_subcommand_from clear" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand memory; and __fish_seen_subcommand_from clear" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand memory; and __fish_seen_subcommand_from clear" -l workspace -d 'Clear workspace-scoped memory (MEMORY.md, sessions/, index.sqlite)'
complete -c grok -n "__fish_grok_using_subcommand memory; and __fish_seen_subcommand_from clear" -l global -d 'Clear global MEMORY.md'
complete -c grok -n "__fish_grok_using_subcommand memory; and __fish_seen_subcommand_from clear" -l all -d 'Clear both workspace and global memory'
complete -c grok -n "__fish_grok_using_subcommand memory; and __fish_seen_subcommand_from clear" -s y -l yes -d 'Skip confirmation prompt'
complete -c grok -n "__fish_grok_using_subcommand memory; and __fish_seen_subcommand_from clear" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand memory; and __fish_seen_subcommand_from clear" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand memory; and __fish_seen_subcommand_from help" -f -a "clear" -d 'Clear memory files (workspace by default)'
complete -c grok -n "__fish_grok_using_subcommand memory; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand models" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand models" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand models" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand models" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand sessions; and not __fish_seen_subcommand_from list search delete help" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand sessions; and not __fish_seen_subcommand_from list search delete help" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand sessions; and not __fish_seen_subcommand_from list search delete help" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand sessions; and not __fish_seen_subcommand_from list search delete help" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand sessions; and not __fish_seen_subcommand_from list search delete help" -f -a "list" -d 'List recent sessions (same as search with no query)'
complete -c grok -n "__fish_grok_using_subcommand sessions; and not __fish_seen_subcommand_from list search delete help" -f -a "search" -d 'Search sessions by keyword'
complete -c grok -n "__fish_grok_using_subcommand sessions; and not __fish_seen_subcommand_from list search delete help" -f -a "delete" -d 'Permanently delete a session from history'
complete -c grok -n "__fish_grok_using_subcommand sessions; and not __fish_seen_subcommand_from list search delete help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from list" -s n -l limit -d 'Maximum number of sessions to show' -r
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from list" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from list" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from list" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from search" -s n -l limit -d 'Maximum number of sessions to show' -r
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from search" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from search" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from search" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from search" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from delete" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from delete" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from delete" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from help" -f -a "list" -d 'List recent sessions (same as search with no query)'
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from help" -f -a "search" -d 'Search sessions by keyword'
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Permanently delete a session from history'
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand setup" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand setup" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand setup" -l json -d 'Print the fetched configuration as JSON instead of installing it; writes nothing to ~/.grok'
complete -c grok -n "__fish_grok_using_subcommand setup" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand setup" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand share" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand share" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand share" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand share" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand wrap" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand wrap" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand wrap" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand wrap" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c grok -n "__fish_grok_using_subcommand export" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand export" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand export" -s c -l clipboard -d 'Copy to clipboard instead of writing to stdout'
complete -c grok -n "__fish_grok_using_subcommand export" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand export" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand trace" -s o -l output -d 'Output path (default: $GROK_HOME/trace-exports/<session-id>.tar.gz)' -r -F
complete -c grok -n "__fish_grok_using_subcommand trace" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand trace" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand trace" -l local -d 'Save locally only, skip remote upload'
complete -c grok -n "__fish_grok_using_subcommand trace" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand trace" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand trace" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand update" -l version -d 'Install a specific version (e.g. 0.1.150 or 0.1.151-alpha.2)' -r
complete -c grok -n "__fish_grok_using_subcommand update" -l trigger -d 'Internal: what spawned this `grok update` (`user_command`, `auto_background`, `leader_converge`). Hidden' -r
complete -c grok -n "__fish_grok_using_subcommand update" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand update" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand update" -l check -d 'Check for updates without installing'
complete -c grok -n "__fish_grok_using_subcommand update" -l json -d 'Emit machine-readable JSON output (for --check)'
complete -c grok -n "__fish_grok_using_subcommand update" -l force-reinstall -d 'Force re-download and install even if already up to date'
complete -c grok -n "__fish_grok_using_subcommand update" -l alpha -d 'Switch to the alpha release channel (faster updates, may have bugs)'
complete -c grok -n "__fish_grok_using_subcommand update" -l stable -d 'Switch to the stable release channel (default, weekly releases)'
complete -c grok -n "__fish_grok_using_subcommand update" -l enterprise -d 'Switch to the enterprise release channel'
complete -c grok -n "__fish_grok_using_subcommand update" -l auto -d 'Internal compat alias for `--trigger=auto_background` (older parents still spawn children with it)'
complete -c grok -n "__fish_grok_using_subcommand update" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand update" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand version" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand version" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand version" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand version" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand version" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand v" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand v" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand v" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand v" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand v" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand completions" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand completions" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand completions" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand completions" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand worktree; and not __fish_seen_subcommand_from list ls show rm gc detach salvage clean-artifacts db help" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand worktree; and not __fish_seen_subcommand_from list ls show rm gc detach salvage clean-artifacts db help" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand worktree; and not __fish_seen_subcommand_from list ls show rm gc detach salvage clean-artifacts db help" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand worktree; and not __fish_seen_subcommand_from list ls show rm gc detach salvage clean-artifacts db help" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand worktree; and not __fish_seen_subcommand_from list ls show rm gc detach salvage clean-artifacts db help" -f -a "list" -d 'List tracked worktrees'
complete -c grok -n "__fish_grok_using_subcommand worktree; and not __fish_seen_subcommand_from list ls show rm gc detach salvage clean-artifacts db help" -f -a "ls" -d 'List tracked worktrees'
complete -c grok -n "__fish_grok_using_subcommand worktree; and not __fish_seen_subcommand_from list ls show rm gc detach salvage clean-artifacts db help" -f -a "show" -d 'Show details for a specific worktree'
complete -c grok -n "__fish_grok_using_subcommand worktree; and not __fish_seen_subcommand_from list ls show rm gc detach salvage clean-artifacts db help" -f -a "rm" -d 'Remove worktrees'
complete -c grok -n "__fish_grok_using_subcommand worktree; and not __fish_seen_subcommand_from list ls show rm gc detach salvage clean-artifacts db help" -f -a "gc" -d 'Remove expired worktrees, keeping any whose work would not survive'
complete -c grok -n "__fish_grok_using_subcommand worktree; and not __fish_seen_subcommand_from list ls show rm gc detach salvage clean-artifacts db help" -f -a "detach" -d 'Convert an NFS-projected worktree into a plain git worktree'
complete -c grok -n "__fish_grok_using_subcommand worktree; and not __fish_seen_subcommand_from list ls show rm gc detach salvage clean-artifacts db help" -f -a "salvage" -d 'Recover hydrated and dirty files when the source repo is gone'
complete -c grok -n "__fish_grok_using_subcommand worktree; and not __fish_seen_subcommand_from list ls show rm gc detach salvage clean-artifacts db help" -f -a "clean-artifacts" -d 'Purge escape-dir artifact contents (`git clean` does not)'
complete -c grok -n "__fish_grok_using_subcommand worktree; and not __fish_seen_subcommand_from list ls show rm gc detach salvage clean-artifacts db help" -f -a "db" -d 'Database maintenance'
complete -c grok -n "__fish_grok_using_subcommand worktree; and not __fish_seen_subcommand_from list ls show rm gc detach salvage clean-artifacts db help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from list" -l repo -r
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from list" -l type -r
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from list" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from list" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from list" -l json
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from list" -l all
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from list" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from ls" -l repo -r
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from ls" -l type -r
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from ls" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from ls" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from ls" -l json
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from ls" -l all
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from ls" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from ls" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from show" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from show" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from show" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from show" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from rm" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from rm" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from rm" -s f -l force
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from rm" -l dry-run
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from rm" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from rm" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from gc" -l max-age -d 'Expire worktrees idle longer than this, e.g. `7d`. Without it, nothing expires' -r
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from gc" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from gc" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from gc" -l dry-run -d 'Report what would be removed without removing it'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from gc" -s f -l force -d 'Skip the live-process and protected-path guards. This does not override the safety check; use `grok worktree rm` for that'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from gc" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from gc" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from detach" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from detach" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from detach" -l allow-copy -d 'Permit a copy when dest and backing are on different devices'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from detach" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from detach" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from salvage" -l out -d 'Directory to write the salvaged plain repo into' -r
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from salvage" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from salvage" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from salvage" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from salvage" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from clean-artifacts" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from clean-artifacts" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from clean-artifacts" -l dry-run -d 'List jail children and exit without deleting'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from clean-artifacts" -l yes -d 'Required to actually delete (irreversible)'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from clean-artifacts" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from clean-artifacts" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from db" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from db" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from db" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from db" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from db" -f -a "rebuild" -d 'Rebuild DB from filesystem scan'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from db" -f -a "stats" -d 'Show DB statistics'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from db" -f -a "path" -d 'Print DB file path'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from db" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from help" -f -a "list" -d 'List tracked worktrees'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from help" -f -a "show" -d 'Show details for a specific worktree'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from help" -f -a "rm" -d 'Remove worktrees'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from help" -f -a "gc" -d 'Remove expired worktrees, keeping any whose work would not survive'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from help" -f -a "detach" -d 'Convert an NFS-projected worktree into a plain git worktree'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from help" -f -a "salvage" -d 'Recover hydrated and dirty files when the source repo is gone'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from help" -f -a "clean-artifacts" -d 'Purge escape-dir artifact contents (`git clean` does not)'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from help" -f -a "db" -d 'Database maintenance'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand clone" -s b -l branch -d 'Branch or ref to check out' -r
complete -c grok -n "__fish_grok_using_subcommand clone" -l cone -d 'Sparse-checkout cone path (repeatable)' -r -F
complete -c grok -n "__fish_grok_using_subcommand clone" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand clone" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand clone" -l full-history -d 'Fetch complete history during clone instead of the fast depth-1 bootstrap. After a depth-1 clone, `git fetch --deepen=N origin` / `--unshallow origin` affect only the selected branch. Another branch needs an explicit depth-limited refspec'
complete -c grok -n "__fish_grok_using_subcommand clone" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand clone" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand du" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand du" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand du" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand du" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand du" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand disk-usage" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand disk-usage" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand disk-usage" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand disk-usage" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand disk-usage" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand workspace; and not __fish_seen_subcommand_from start pause resume stop restart status list help" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand workspace; and not __fish_seen_subcommand_from start pause resume stop restart status list help" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand workspace; and not __fish_seen_subcommand_from start pause resume stop restart status list help" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand workspace; and not __fish_seen_subcommand_from start pause resume stop restart status list help" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c grok -n "__fish_grok_using_subcommand workspace; and not __fish_seen_subcommand_from start pause resume stop restart status list help" -f -a "start" -d 'Start (or update) the workspace-to-hub exposure'
complete -c grok -n "__fish_grok_using_subcommand workspace; and not __fish_seen_subcommand_from start pause resume stop restart status list help" -f -a "pause" -d 'Drain and disconnect from the hub, keeping the exposure warm'
complete -c grok -n "__fish_grok_using_subcommand workspace; and not __fish_seen_subcommand_from start pause resume stop restart status list help" -f -a "resume" -d 'Reconnect a paused exposure to the hub'
complete -c grok -n "__fish_grok_using_subcommand workspace; and not __fish_seen_subcommand_from start pause resume stop restart status list help" -f -a "stop" -d 'Stop exposing the workspace (the leader keeps running)'
complete -c grok -n "__fish_grok_using_subcommand workspace; and not __fish_seen_subcommand_from start pause resume stop restart status list help" -f -a "restart" -d 'Restart the exposure (stop, then start with the given options)'
complete -c grok -n "__fish_grok_using_subcommand workspace; and not __fish_seen_subcommand_from start pause resume stop restart status list help" -f -a "status" -d 'Show the current workspace-exposure status'
complete -c grok -n "__fish_grok_using_subcommand workspace; and not __fish_seen_subcommand_from start pause resume stop restart status list help" -f -a "list" -d 'Show the current workspace-exposure status'
complete -c grok -n "__fish_grok_using_subcommand workspace; and not __fish_seen_subcommand_from start pause resume stop restart status list help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from start" -l hub-url -d 'Computer Hub WebSocket URL (default: `[hub].url`, then the prod hub)' -r
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from start" -l cwd -d 'Workspace root directory to expose. Defaults to the current directory' -r -f -a "(__fish_complete_directories)"
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from start" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from start" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from start" -l leader -d 'Force leader mode for this command, overriding config'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from start" -l no-leader -d 'Refuse to start even when config enables leader mode'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from start" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from start" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from start" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from pause" -l pid -d 'Leader process ID from `grok leader list`' -r
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from pause" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from pause" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from pause" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from pause" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from pause" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from resume" -l pid -d 'Leader process ID from `grok leader list`' -r
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from resume" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from resume" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from resume" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from resume" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from resume" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from stop" -l pid -d 'Leader process ID from `grok leader list`' -r
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from stop" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from stop" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from stop" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from stop" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from stop" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from restart" -l hub-url -d 'Computer Hub WebSocket URL (default: `[hub].url`, then the prod hub)' -r
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from restart" -l cwd -d 'Workspace root directory to expose. Defaults to the current directory' -r -f -a "(__fish_complete_directories)"
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from restart" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from restart" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from restart" -l leader -d 'Force leader mode for this command, overriding config'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from restart" -l no-leader -d 'Refuse to start even when config enables leader mode'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from restart" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from restart" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from restart" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from status" -l pid -d 'Leader process ID from `grok leader list`' -r
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from status" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from status" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from status" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from status" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from status" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from list" -l pid -d 'Leader process ID from `grok leader list`' -r
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from list" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from list" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from list" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from list" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from help" -f -a "start" -d 'Start (or update) the workspace-to-hub exposure'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from help" -f -a "pause" -d 'Drain and disconnect from the hub, keeping the exposure warm'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from help" -f -a "resume" -d 'Reconnect a paused exposure to the hub'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from help" -f -a "stop" -d 'Stop exposing the workspace (the leader keeps running)'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from help" -f -a "restart" -d 'Restart the exposure (stop, then start with the given options)'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from help" -f -a "status" -d 'Show the current workspace-exposure status'
complete -c grok -n "__fish_grok_using_subcommand workspace; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand dashboard" -l leader-socket -d 'Use a custom leader socket path instead of the default `~/.grok/leader.sock`' -r -F
complete -c grok -n "__fish_grok_using_subcommand dashboard" -l debug-file -d 'Write debug logs to FILE' -r -F
complete -c grok -n "__fish_grok_using_subcommand dashboard" -l debug -d 'Enable debug logging'
complete -c grok -n "__fish_grok_using_subcommand dashboard" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "agent" -d 'Run Grok without the interactive UI'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "inspect" -d 'Show the configuration Grok discovers for this directory'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "doctor" -d 'Check terminal, clipboard, color, and input support without starting Grok'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "leader" -d 'Manage running leader processes'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "logout" -d 'Sign out and clear cached credentials'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "login" -d 'Sign in to Grok'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "mcp" -d 'Manage MCP server configurations'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "plugin" -d 'Manage plugins and marketplace sources'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "memory" -d 'Manage cross-session memory'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "models" -d 'List available models and exit'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "sessions" -d 'List, search, or restore sessions'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "setup" -d 'Fetch and install managed configuration'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "share" -d 'Share a session and print the share URL'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "wrap" -d 'Run any command with local clipboard support (forwards OSC 52 to the system clipboard)'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "export" -d 'Export a session transcript as Markdown'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "trace" -d 'Export or upload session trace data'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "update" -d 'Check for updates or install a specific version'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "version" -d 'Print version information'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "completions" -d 'Generate shell completion scripts (bash, zsh, fish, powershell, ...)'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "worktree" -d 'Manage git worktrees'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "clone" -d 'Lazy-clone a git repository via grove (NFS on macOS, FUSE on Linux)'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "du" -d 'Show what the grok home (~/.grok) uses on disk'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "workspace" -d 'Expose this workspace to the Computer Hub (via the leader)'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "dashboard" -d 'Open the Agent Dashboard view at startup'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent inspect doctor leader logout login mcp plugin memory models sessions setup share wrap export trace update version completions worktree clone du workspace dashboard help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from agent" -f -a "stdio" -d 'Run the agent over stdio'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from agent" -f -a "headless" -d 'Run the agent headlessly over the Grok WebSocket relay'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from agent" -f -a "serve" -d 'Run the agent as a WebSocket server'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from agent" -f -a "leader" -d 'Run as the shared leader process for other clients'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from doctor" -f -a "fix" -d 'Apply an automatic fix'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from leader" -f -a "list" -d 'List running leader processes'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from leader" -f -a "info" -d 'Show details for a leader process'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from leader" -f -a "kill" -d 'Stop all running leader processes'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from mcp" -f -a "list" -d 'List configured MCP servers'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from mcp" -f -a "add" -d 'Add or update an MCP server'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from mcp" -f -a "remove" -d 'Remove an MCP server'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from mcp" -f -a "enable" -d 'Enable an MCP server'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from mcp" -f -a "disable" -d 'Disable an MCP server'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from mcp" -f -a "doctor" -d 'Diagnose MCP server configuration and connectivity'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from plugin" -f -a "list" -d 'List installed plugins'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from plugin" -f -a "install" -d 'Install a plugin from a git URL or local path'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from plugin" -f -a "uninstall" -d 'Uninstall an installed plugin by name'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from plugin" -f -a "update" -d 'Update installed plugin(s)'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from plugin" -f -a "enable" -d 'Enable a disabled plugin'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from plugin" -f -a "disable" -d 'Disable a plugin without uninstalling it'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from plugin" -f -a "details" -d 'Show a plugin\'s component inventory'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from plugin" -f -a "validate" -d 'Validate a plugin manifest'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from plugin" -f -a "tag" -d 'Create a release git tag from the plugin\'s manifest version'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from plugin" -f -a "marketplace" -d 'Manage marketplace sources'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from memory" -f -a "clear" -d 'Clear memory files (workspace by default)'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from sessions" -f -a "list" -d 'List recent sessions (same as search with no query)'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from sessions" -f -a "search" -d 'Search sessions by keyword'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from sessions" -f -a "delete" -d 'Permanently delete a session from history'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from worktree" -f -a "list" -d 'List tracked worktrees'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from worktree" -f -a "show" -d 'Show details for a specific worktree'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from worktree" -f -a "rm" -d 'Remove worktrees'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from worktree" -f -a "gc" -d 'Remove expired worktrees, keeping any whose work would not survive'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from worktree" -f -a "detach" -d 'Convert an NFS-projected worktree into a plain git worktree'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from worktree" -f -a "salvage" -d 'Recover hydrated and dirty files when the source repo is gone'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from worktree" -f -a "clean-artifacts" -d 'Purge escape-dir artifact contents (`git clean` does not)'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from worktree" -f -a "db" -d 'Database maintenance'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from workspace" -f -a "start" -d 'Start (or update) the workspace-to-hub exposure'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from workspace" -f -a "pause" -d 'Drain and disconnect from the hub, keeping the exposure warm'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from workspace" -f -a "resume" -d 'Reconnect a paused exposure to the hub'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from workspace" -f -a "stop" -d 'Stop exposing the workspace (the leader keeps running)'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from workspace" -f -a "restart" -d 'Restart the exposure (stop, then start with the given options)'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from workspace" -f -a "status" -d 'Show the current workspace-exposure status'
