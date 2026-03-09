#!/bin/bash

# Step 1: Ask the user for their email address
read -p "Enter your email address for GitHub: " email

# Step 2: Check if SSH key already exists
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  echo "No SSH key found. Generating new SSH key..."
  # Generate SSH key
  ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""
  echo "SSH key generated successfully!"
else
  echo "SSH key already exists. Skipping key generation."
fi

# Step 3: Display the SSH public key for the user
echo "Your SSH public key is:"
cat "$HOME/.ssh/id_ed25519.pub"
echo "Please copy the above SSH key and add it to your GitHub account."

