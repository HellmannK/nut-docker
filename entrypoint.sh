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

# Check if USB_DEVICE environment variable is set
if [ -z "$USB_DEVICE" ]; then
  echo "Error: USB_DEVICE environment variable is not set."
  exit 1
fi

# Wait for the USB device to be available
while [ ! -e $USB_DEVICE ]; do
  echo "Waiting for USB device $USB_DEVICE to be available..."
  sleep 1
done

# Set permissions for the USB device
chown root:nut $USB_DEVICE
chmod 660 $USB_DEVICE

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

# Temporarily copy /etc/nut contents before mounting
TEMP_DIR="/tmp/nut"
mkdir -p "$TEMP_DIR"
cp -r /etc/nut/* "$TEMP_DIR"

# Copy /etc/nut to the target directory if it is empty
TARGET_DIR="/home/admin/podman_volumes/nut-cgi-server/nut"
if [ -d "$TARGET_DIR" ] && [ -z "$(ls -A "$TARGET_DIR")" ]; then
  echo "Target directory is empty. Copying contents of /etc/nut to $TARGET_DIR"
  cp -r "$TEMP_DIR"/* "$TARGET_DIR"
fi

# Generate a file with the output of nut-scanner -U
nut-scanner -U > /etc/nut/nut-scanner-output.txt

# Start all services
start_nut_server
start_nut_monitor
start_postfix
start_fcgiwrap
upsdrvctl start

# Start NGINX (this will keep the script running)
start_nginx
