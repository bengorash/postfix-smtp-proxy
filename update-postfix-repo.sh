#!/bin/bash
# Script to update postfix-smtp-proxy from GitHub with proper permissions

# Define the target directory
TARGET_DIR=~/togotrek/postfix-smtp-proxy

# Create the parent directory if it doesn't exist
mkdir -p ~/togotrek

# Remove the target directory if it exists
if [ -d "$TARGET_DIR" ]; then
  echo "Removing existing directory..."
  sudo rm -rf "$TARGET_DIR"
fi

# Clone the repository
echo "Cloning repository from GitHub..."
git clone https://github.com/bengorash/postfix-smtp-proxy.git "$TARGET_DIR"

# Set permissions
echo "Setting directory permissions..."
sudo chown -R $USER:$USER "$TARGET_DIR"
sudo chmod -R 755 "$TARGET_DIR"

# Create necessary directories for Docker build if they don't exist
echo "Creating additional directories needed for Docker..."
mkdir -p "$TARGET_DIR/var/spool/postfix/public"
mkdir -p "$TARGET_DIR/var/spool/postfix/private" 
mkdir -p "$TARGET_DIR/var/mail"

# Create start-services.sh script if it doesn't exist
if [ ! -f "$TARGET_DIR/start-services.sh" ]; then
  echo "Creating start-services.sh script..."
  cat > "$TARGET_DIR/start-services.sh" << 'EOL'
#!/bin/bash
service rsyslog start
service postfix start || postfix start
# Create log file if it doesn't exist
touch /var/log/mail.log
# Keep container running
tail -f /var/log/mail.log
EOL
  chmod +x "$TARGET_DIR/start-services.sh"
fi

echo "Setup complete! Your repository is now at $TARGET_DIR with proper permissions."