#!/usr/bin/env bash

export XDG_CURRENT_DESKTOP=river
export XDG_SESSION_DESKTOP=River
export XDG_SESSION_TYPE=wayland
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM="wayland;xcb"
export QT_QPA_PLATFORMTHEME=qt6ct
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export QT_SCALE_FACTOR=1
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export GDK_SCALE=1
export GDK_BACKEND="wayland,x11,*"
export WLR_NO_HARDWARE_CURSORS=1
export GTK_CSD=0

dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP

systemctl --user start xdg-desktop-portal-wlr
systemctl --user start xdg-desktop-portal
