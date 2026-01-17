#!/usr/bin/env bash

# Check if IP address is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <ip-address>"
    echo "Example: $0 192.168.1.100"
    exit 1
fi

TARGET_IP=$1
DISK_CONFIG="hosts/pushkin-nixos/disk-config.nix"

# Extract configured device from disk-config.nix
# This simple grep assumes the format: device = "/dev/sda";
CONFIGURED_DEVICE=$(grep 'device = "' "$DISK_CONFIG" | cut -d '"' -f 2)

if [ -z "$CONFIGURED_DEVICE" ]; then
    echo "Error: Could not determine configured device from $DISK_CONFIG"
    exit 1
fi

echo "Configured device in $DISK_CONFIG: $CONFIGURED_DEVICE"
echo "---------------------------------------------------"
echo "Connecting to $TARGET_IP to list available disks..."
echo

# Run lsblk on remote host
ssh "root@$TARGET_IP" "lsblk -d -o NAME,SIZE,MODEL,TYPE | grep disk"

echo "---------------------------------------------------"
echo "Please verify that '$CONFIGURED_DEVICE' exists in the list above."
echo "If the names don't match (e.g. sda vs nvme0n1), update $DISK_CONFIG before installing."
