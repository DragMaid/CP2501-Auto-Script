#!/bin/bash

# Set default key path
KEY_PATH="$HOME/.ssh/id_aweb"

# Create .ssh directory if it doesn't exist
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Check if key already exists
if [ -f "$KEY_PATH" ]; then
    echo "An SSH key already exists at $KEY_PATH"
    exit 1
fi

# Generate SSH key pair without passphrase
ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N "" -m PEM

# Set correct permissions
chmod 600 "$KEY_PATH"
chmod 644 "$KEY_PATH.pub"
mv "$KEY_PATH" "$KEY_PATH.pem"

echo "SSH key pair generated:"
echo "Private key: $KEY_PATH.pem"
echo "Public key:  $KEY_PATH.pub"
