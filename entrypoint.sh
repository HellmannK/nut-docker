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
    /usr/sbin/fcgiwrap -s unix:/var/run/fcgiwrap.socket &
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

# Ensure configuration files are in place
CONFIGS_DIR="/opt/scripts/configs"

required_configs=("nginx.conf" "ups.conf" "upsd.conf" "upsd.users" "upsmon.conf" "wol_clients.conf")

for config in "${required_configs[@]}"; do
    if [ ! -f "$CONFIGS_DIR/$config" ]; then
        echo "$config not found!"
        exit 1
    fi
done

# Copy configuration files from the volume to their respective locations
cp "$CONFIGS_DIR/nginx.conf" /etc/nginx/nginx.conf
cp "$CONFIGS_DIR/hosts.conf" /etc/nut/hosts.conf
cp "$CONFIGS_DIR/nut.conf" /etc/nut/nut.conf
cp "$CONFIGS_DIR/ups.conf" /etc/nut/ups.conf
cp "$CONFIGS_DIR/upsd.conf" /etc/nut/upsd.conf
cp "$CONFIGS_DIR/upsd.users" /etc/nut/upsd.users
cp "$CONFIGS_DIR/upsmon.conf" /etc/nut/upsmon.conf
cp "$CONFIGS_DIR/main.cf" /etc/postfix/main.cf
cp "$CONFIGS_DIR/wol_clients.conf" /opt/scripts/wol_clients.conf

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
