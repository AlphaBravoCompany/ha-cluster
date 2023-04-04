#!/bin/bash

## Check to see if this is an Ubuntu environment
if ! grep -q "ID=ubuntu" /etc/os-release; then
  echo "Not running on Ubuntu. Exiting."
  exit 1
fi

## Check if the script is running as root or with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with sudo privilages."
  exit 1
fi

## Multipass Cleanup
multipass stop --all
multipass delete --all
multipass purge