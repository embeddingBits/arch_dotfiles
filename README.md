# Software

- **Distro**: [Arch Linux](https://archlinux.org/)
- **Window manager**: [Niri](https://niri-wm.github.io/niri/index.html)
- **Top bar**: [Quickshell](https://quickshell.org)
- **Terminal**: [foot](https://codeberg.org/dnkl/foot)
- **Text editor**: [Emacs](https://www.gnu.org/software/emacs/) and [Neovim](https://neovim.io/)
- **Application Launcher**: [Fuzzel](https://codeberg.org/dnkl/fuzzel)
- **Visual candy**: [pipes.sh](https://github.com/pipeseroni/pipes.sh)
- **Shell**: [fish](https://github.com/fish-shell/fish-shell)
- **Spotify**: [Spicetify](https://github.com/spicetify)
- **Discord**: [Discord](https://betterdiscord.app)

Currently, most of my quickshell config is under heavy WIP :)

# Gruvbox Rice

![Terminal](./images/river_terminal.png)
![Main](./images/river_main.png)
![Neovim](./images/river_nvim.png)
![Discord](./images/river_discord.png)

# Reproducible Installation

Dotfiles are managed with [GNU Stow](https://www.gnu.org/software/stow/).

Packages are categorized in `packages.lst` for modular, selective installation.
The `install.sh` script orchestrates a full reproducible bootstrap.

## Quick start 

```bash
./install.sh
```

Manual Stow

```bash
stow dotfiles
stow emacs
stow nvim-config
stow quickshel
```
