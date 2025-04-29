#!/bin/bash
set -e

# Start rsyslog for logging
echo "Starting rsyslog service..."
service rsyslog start || echo "Warning: rsyslog service failed to start"

# Create log file if it doesn't exist
touch /var/log/mail.log

# Configure postfix
echo "Checking Postfix configuration..."
postfix check

echo "Setting Postfix permissions..."
postfix set-permissions

# Ensure Postfix is set to listen on all interfaces
postconf -e "inet_interfaces = all"
postconf -e "inet_protocols = all"

echo "Starting Postfix..."
postfix start

echo "Postfix status:"
postfix status

echo "Network connections:"
# Check if netstat exists, otherwise use ss
if command -v netstat &> /dev/null; then
    netstat -tulnp | grep :25 || echo "Warning: Port 25 not showing in netstat"
else
    ss -tulnp | grep :25 || echo "Warning: Port 25 not showing in ss"
fi

echo "Postfix has been started. Showing mail logs..."

# Keep the container running and show logs
tail -f /var/log/mail.log