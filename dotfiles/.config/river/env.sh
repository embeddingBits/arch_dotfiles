#!/usr/bin/env bash

ulimit -n 65536
ulimit -s unlimited

export XDG_CURRENT_DESKTOP=river
export XDG_SESSION_DESKTOP=River
export XDG_SESSION_TYPE=wayland
export MOZ_ENABLE_WAYLAND=1

export GTK_THEME=Gruvbox-BL-LB-Dark

export QT_QPA_PLATFORM="wayland;xcb"
export QT_QPA_PLATFORMTHEME=qt6ct
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

export GDK_BACKEND="wayland,x11,*"
export WLR_NO_HARDWARE_CURSORS=1

export PATH="$HOME/.bun/bin:$HOME/.local/go/bin:/opt/cuda/bin:$PATH"

dbus-update-activation-environment --systemd --all

systemctl --user start xdg-desktop-portal
systemctl --user start xdg-desktop-portal-wlr
