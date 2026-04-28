sudo pacman -S --needed \
  # CLI tools
  unzip zip unrar \
   bat less fd eza ripgrep fzf jq \
  fastfetch btop cava stow \
  zoxide starship neovim zed emacs \
  \
  # System / services
  bluez bluez-utils blueman \
  pipewire pipewire-pulse \
  wireplumber \
  syncthing \
  \
  # Wayland / UI
  fuzzel \
  awww waybar \
  ly fnott river \
  grim slurp \
  xdg-desktop-portal xdg-desktop-portal-wlr \
  qt5ct qt6ct nwg-look \
  \
  # Terminal / dev
  fish foot yazi waylock \
  \
  # Media / documents
  mpv mpv-mpris \
  imagemagick \
  poppler zathura zathura-pdf-mupdf \ 
  \
  # Fonts / apps
  ttf-iosevka-nerd firefox brave-browser-bin element-desktop 

# Changing Shell
chsh -s /usr/bin/fish
