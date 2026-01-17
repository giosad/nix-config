#!/usr/bin/env bash

# Check if IP address is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <ip-address>"
    echo "Example: $0 192.168.1.100"
    exit 1
fi

TARGET_IP=$1

echo "WARNING: This will erase all data on the target machine ($TARGET_IP)!"
echo "Target disk configured in hosts/pushkin-nixos/disk-config.nix must match the hardware."
read -p "Are you sure you want to proceed? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Run nixos-anywhere
# --flake .#pushkin-nixos: points to the configuration defined in flake.nix
# root@$TARGET_IP: the SSH destination
nix run github:nix-community/nixos-anywhere -- --flake .#pushkin-nixos "root@$TARGET_IP"
