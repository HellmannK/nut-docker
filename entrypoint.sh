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

# Function to restart Postfix with updated configs
restart_postfix() {
    echo "Restarting Postfix..."
    /etc/init.d/postfix restart
}

# Function to start fcgiwrap
start_fcgiwrap() {
    echo "Starting fcgiwrap..."
    /etc/init.d/fcgiwrap start
}

# Function to start nut-driver
start_upsdrvctl() {
    echo "Starting upsdrvctl"
    upsdrvctl start
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

# Check if /etc/nut files exist, and copy them from /tmp/nut if they don't
nut_files=( hosts.conf nut.conf ups.conf upsd.conf upsd.users upsmon.conf upssched.conf upsset.conf upsstats-single.html upsstats.html )

for i in "${nut_files[@]}"
do
  if [ ! -f /etc/nut/$i ]; then
    cp /tmp/nut/$i /etc/nut/$i \
    && echo "No existing $i found"
  else
    echo "Existing $i found, and will be used"
  fi
done

# Check if /etc/postfix files exist, and copy them from /tmp/postfix if they don't
postfix_files=( main.cf sasl_passwd sender_canonical generic )

for i in "${postfix_files[@]}"
do
  if [ ! -f /etc/postfix/$i ]; then
    cp /tmp/postfix/$i /etc/postfix/$i \
    && echo "No existing $i found"
  else
    echo "Existing $i found, and will be used"
  fi
done

# Generate postfix maps and restart postfix
postmap /etc/postfix/sender_canonical
postmap /etc/postfix/sasl_passwd
postmap /etc/postfix/generic
restart_postfix

# Generate a file with the output of nut-scanner -U
nut-scanner -U > /etc/nut/nut-scanner-output.txt

# Start services
start_nut_server
start_nut_monitor
start_fcgiwrap
start_upsdrvctl

# Start NGINX (this will keep the script running)
start_nginx
