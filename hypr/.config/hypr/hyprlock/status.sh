#!/usr/bin/env bash

############ Variables ############
enable_battery=false

####### Check availability ########
for battery in /sys/class/power_supply/*BAT*; do
  if [[ -f "$battery/uevent" ]]; then
    enable_battery=true
    break
  fi
done

############# Output #############
if [[ $enable_battery == true ]]; then
  echo -n "  $(cat /sys/class/power_supply/*/capacity | head -1)"%
fi

echo ''
