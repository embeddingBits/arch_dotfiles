#!/usr/bin/env bash

# Constants
divider="---------"
goback="Back"

# ----------- FUZZEL MENU WRAPPER -----------
fuzzel_menu() {
    local prompt="$1"
    local options="$2"
    printf "%b" "$options" | fuzzel --match-mode fzf --dmenu -p "$prompt"
}

# ----------- POWER STATE -----------
power_on() {
    bluetoothctl show | grep -q "Powered: yes"
}

toggle_power() {
    if power_on; then
        bluetoothctl power off
    else
        if rfkill list bluetooth | grep -q 'blocked: yes'; then
            rfkill unblock bluetooth && sleep 2
        fi
        bluetoothctl power on
    fi
    show_menu
}

# ----------- SCAN STATE -----------
scan_on() {
    bluetoothctl show | grep -q "Discovering: yes"
}

toggle_scan() {
    if scan_on; then
        bluetoothctl scan off
    else
        bluetoothctl --timeout 5 scan on &
    fi
    show_menu
}

# ----------- PAIRABLE -----------
pairable_on() {
    bluetoothctl show | grep -q "Pairable: yes"
}

toggle_pairable() {
    if pairable_on; then
        bluetoothctl pairable off
    else
        bluetoothctl pairable on
    fi
    show_menu
}

# ----------- DISCOVERABLE -----------
discoverable_on() {
    bluetoothctl show | grep -q "Discoverable: yes"
}

toggle_discoverable() {
    if discoverable_on; then
        bluetoothctl discoverable off
    else
        bluetoothctl discoverable on
    fi
    show_menu
}

# ----------- DEVICE STATES -----------
device_connected() {
    bluetoothctl info "$1" | grep -q "Connected: yes"
}

device_paired() {
    bluetoothctl info "$1" | grep -q "Paired: yes"
}

device_trusted() {
    bluetoothctl info "$1" | grep -q "Trusted: yes"
}

# ----------- DEVICE ACTIONS -----------
toggle_connection() {
    if device_connected "$1"; then
        bluetoothctl disconnect "$1"
    else
        bluetoothctl connect "$1"
    fi
    device_menu "$device"
}

toggle_paired() {
    if device_paired "$1"; then
        bluetoothctl remove "$1"
    else
        bluetoothctl pair "$1"
    fi
    device_menu "$device"
}

toggle_trust() {
    if device_trusted "$1"; then
        bluetoothctl untrust "$1"
    else
        bluetoothctl trust "$1"
    fi
    device_menu "$device"
}

# ----------- DEVICE MENU -----------
device_menu() {
    device="$1"

    device_name=$(echo "$device" | cut -d ' ' -f 3-)
    mac=$(echo "$device" | cut -d ' ' -f 2)

    if device_connected "$mac"; then
        connected="Connected: yes"
    else
        connected="Connected: no"
    fi

    if device_paired "$mac"; then
        paired="Paired: yes"
    else
        paired="Paired: no"
    fi

    if device_trusted "$mac"; then
        trusted="Trusted: yes"
    else
        trusted="Trusted: no"
    fi

    options="$connected\n$paired\n$trusted\n$divider\n$goback\nExit"

    chosen="$(fuzzel_menu "$device_name" "$options")"

    case "$chosen" in
        "" | "$divider")
            ;;
        "$connected")
            toggle_connection "$mac"
            ;;
        "$paired")
            toggle_paired "$mac"
            ;;
        "$trusted")
            toggle_trust "$mac"
            ;;
        "$goback")
            show_menu
            ;;
    esac
}

# ----------- MAIN MENU -----------
show_menu() {
    if power_on; then
        power="Power: on"

        devices=$(bluetoothctl devices | grep Device | cut -d ' ' -f 3-)

        scan=$(scan_on && echo "Scan: on" || echo "Scan: off")
        pairable=$(pairable_on && echo "Pairable: on" || echo "Pairable: off")
        discoverable=$(discoverable_on && echo "Discoverable: on" || echo "Discoverable: off")

        options="$devices\n$divider\n$power\n$scan\n$pairable\n$discoverable\nExit"
    else
        power="Power: off"
        options="$power\nExit"
    fi

    chosen="$(fuzzel_menu "Bluetooth" "$options")"

    case "$chosen" in
        "" | "$divider")
            ;;
        "$power")
            toggle_power
            ;;
        "$scan")
            toggle_scan
            ;;
        "$pairable")
            toggle_pairable
            ;;
        "$discoverable")
            toggle_discoverable
            ;;
        *)
            device=$(bluetoothctl devices | grep "$chosen")
            [ -n "$device" ] && device_menu "$device"
            ;;
    esac
}

# ----------- STATUS (for waybar/polybar) -----------
print_status() {
    if power_on; then
        printf ''
        bluetoothctl devices Connected | cut -d ' ' -f 3-
        printf "\n"
    else
        echo ""
    fi
}

# ----------- ENTRY POINT -----------
case "$1" in
    --status)
        print_status
        ;;
    *)
        show_menu
        ;;
esac
