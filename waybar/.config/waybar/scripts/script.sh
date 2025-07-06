#!/bin/bash

speedtest-cli --simple | awk '/Download/ { d=$2 } /Upload/ { u=$2 } END { printf "↓ %.1f Mbps ↑ %.1f Mbps\n", d, u }'
