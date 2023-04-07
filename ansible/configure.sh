#!/bin/bash

function display_help() {
  echo "Usage: ${0} --key /path/to/ssh_key"
  echo "Options:"
  echo "  -k, --key        Path to a valid SSH key"
  echo "  --help           Show this help message"
}

# Check if Ansible is installed
if ! command -v ansible >/dev/null 2>&1; then
  echo "Ansible is not installed. Please install Ansible and try again."
  exit 1
fi

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -k|--key)
      key_path="$2"
      shift 2
      ;;
    --help)
      display_help
      exit 0
      ;;
    *)
      display_help
      exit 1
      ;;
  esac
done

# Check if the key path is provided
if [[ -z "$key_path" ]]; then
  display_help
  exit 1
fi

# Check if the key path is valid
if [[ ! -f "$key_path" ]]; then
  echo "Invalid key path. Please provide a valid path to an SSH key with --key or -k."
  exit 1
fi

# Check if the file is a valid SSH key
if ! ssh-keygen -l -f "$key_path" >/dev/null 2>&1; then
  echo "The provided file does not appear to be a valid SSH key. Please ensure it's a valid SSH key."
  exit 1
fi

# Check if the inventory.txt file exists and is not empty
if [[ ! -s "inventory.txt" ]]; then
  echo "The file, inventory.txt, is missing or empty. Please make sure it exists and contains IP addresses."
  exit 1
fi

# Check if the inventory file contains IP addresses
if ! grep -q -E "([0-9]{1,3}\.){3}[0-9]{1,3}" inventory.txt; then
  echo "The inventory file does not contain any IP addresses. Please ensure it has valid IP addresses."
  exit 1
fi

# Run the Ansible playbook
ansible-playbook -T 1800 -i inventory.txt configure_baremetal.yml -u ubuntu --private-key "${key_path}"
