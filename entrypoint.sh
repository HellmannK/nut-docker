#!/bin/bash

# Function to start NUT server
start_nut_server() {
    echo "Starting NUT server..."
    /usr/sbin/upsd
}

# Function to start NUT monitor
start_nut_monitor() {
    echo "Starting NUT monitor..."
    /usr/sbin/upsmon
}

# Function to start NGINX
start_nginx() {
    echo "Starting NGINX..."
    nginx -g 'daemon off;'
}

# Function to start Postfix
start_postfix() {
    echo "Starting Postfix..."
    /etc/init.d/postfix start
}

# Function to start fcgiwrap
start_fcgiwrap() {
    echo "Starting fcgiwrap..."
    /etc/init.d/fcgiwrap start
}

# Function to monitor UPS and trigger WOL script
monitor_ups() {
    echo "Monitoring UPS status..."
    while true; do
        # Check the status of the UPS
        STATUS=$(upsc ups@localhost ups.status || echo "UNKNOWN")
        
        # If mains is back, execute WOL script
        if [ "$STATUS" == "OL" ]; then
            echo "Mains is back, executing WOL script..."
            /opt/scripts/wol.sh
        fi
        
        # Sleep for a while before checking again
        sleep 60
    done
}

# Ensure WOL configuration files are in place
CONFIGS_DIR="/opt/scripts/configs"
SCRIPTS_DIR="/opt/scripts"

echo "Checking for WOL configuration files..."

if [ ! -f "$CONFIGS_DIR/wol_clients.conf" ]; then
    echo "wol_clients.conf not found in $CONFIGS_DIR! Exiting..."
    ls -l $CONFIGS_DIR
    exit 1
fi

if [ ! -f "$SCRIPTS_DIR/wol.sh" ]; then
    echo "wol.sh not found in $SCRIPTS_DIR! Exiting..."
    ls -l $SCRIPTS_DIR
    exit 1
fi

# Generate a file with the output of nut-scanner -U
nut-scanner -U > /etc/nut/nut-scanner-output.txt

# Start all services
start_nut_server
start_nut_monitor
start_postfix
start_fcgiwrap

# Start UPS monitoring in the background
monitor_ups &

# Start NGINX (this will keep the script running)
start_nginx
