#!/bin/bash

# Default configuration file
DEFAULT_CONFIG_FILE="/opt/scripts/configs/wol_clients.conf"

# Usage function to display help
usage() {
    echo "Usage: $0 [config_file]"
    exit 1
}

# Check if a configuration file is provided as an argument
if [ -n "$1" ]; then
    CONFIG_FILE=$1
else
    CONFIG_FILE=$DEFAULT_CONFIG_FILE
fi

# Check if the configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found at $CONFIG_FILE."
    usage
fi

# Function to send magic packet
send_magic_packet() {
    local mac_address=$1
    local ip_address=$2
    local name=$3

    sudo etherwake $mac_address

    if [ $? -eq 0 ]; then
        echo "Magic packet sent to $name ($mac_address, $ip_address)"
    else
        echo "Failed to send magic packet to $name ($mac_address, $ip_address)"
    fi
}

# Read the configuration file
while IFS=' ' read -r mac_address ip_address name; do
    # Skip empty lines and comments
    [[ "$mac_address" =~ ^#.*$ ]] && continue
    [[ -z "$mac_address" ]] && continue

    # Validate MAC address format (basic check)
    if [[ ! "$mac_address" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
        echo "Error: Invalid MAC address format in configuration file: $mac_address"
        continue
    fi

    send_magic_packet $mac_address $ip_address $name
done < "$CONFIG_FILE"

