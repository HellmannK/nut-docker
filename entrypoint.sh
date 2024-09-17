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
    nginx
}

# Function to start Postfix
start_postfix() {
    echo "Starting Postfix..."
    /etc/init.d/postfix start
}

# Function to monitor UPS and trigger WOL script
monitor_ups() {
    echo "Monitoring UPS status..."
    while true; do
        # Check the status of the UPS
        STATUS=$(upsc ups@localhost ups.status)
        
        # If mains is back, execute WOL script
        if [ "$STATUS" == "OL" ]; then
            echo "Mains is back, executing WOL script..."
            /opt/scripts/wol.sh
        fi
        
        # Sleep for a while before checking again
        sleep 60
    done
}

# Start all services
start_nut_server
start_nut_monitor
start_nginx
start_postfix

# Start UPS monitoring in the background
monitor_ups &

# Keep the container running
tail -f /dev/null
