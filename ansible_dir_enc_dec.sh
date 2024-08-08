#!/bin/bash

# Directory containing the playbook files
PLAYBOOK_DIR="/home/test_dir"

# Prompt for the action
echo "Enter 1 to decrypt files, 0 to encrypt files:"
read -r action

# Validate input
if [[ "$action" != "1" && "$action" != "0" ]]; then
    echo "Invalid input. Please enter 1 to decrypt or 0 to encrypt."
    exit 1
fi

# Prompt for the Vault password once
read -sp "Enter the Ansible Vault password: " vault_password
echo

# Create a temporary file to store the password securely
temp_vault_pass=$(mktemp)
echo "$vault_password" > "$temp_vault_pass"

# Change to the playbook directory
cd "$PLAYBOOK_DIR" || exit

# Perform the chosen action on each YAML file
if [[ "$action" == "1" ]]; then
    for file in *.yml; do
        ansible-vault decrypt "$file" --vault-password-file "$temp_vault_pass"
    done
    echo "All YAML files have been decrypted."
else
    for file in *.yml; do
        ansible-vault encrypt "$file" --vault-password-file "$temp_vault_pass"
    done
    echo "All YAML files have been encrypted."
fi

# Remove the temporary password file
rm -f "$temp_vault_pass"

