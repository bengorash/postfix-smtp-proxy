#!/bin/bash
# Script to properly setup and start Postfix

# First check if we need to run postfix upgrade-configuration
if ! grep -q "postlog" /etc/postfix/master.cf; then
  echo "Running postfix upgrade-configuration to update Postfix configuration..."
  postfix upgrade-configuration
fi

# Check Postfix configuration
postfix check

# Set permissions
postfix set-permissions

# Start Postfix
postfix start

# Output status
postfix status

# Exit with success
exit 0