#!/bin/bash
# Don't exit on errors
set +e

echo "Starting SMTP proxy container setup..."

# Basic setup
mkdir -p /var/log/postfix
mkdir -p /var/log/supervisor

# Create sasl_passwd file for Gmail authentication
echo "Creating SASL password file..."
echo "[${SMTP_HOST:-smtp.gmail.com}]:${SMTP_PORT:-587} ${SMTP_USER}:${SMTP_PASS}" > /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db

# Prepare Postfix directories
mkdir -p /var/spool/postfix/pid
chown -R postfix:root /var/spool/postfix/
chmod 755 /var/spool/postfix/

# Copy host DNS info to chroot jail
mkdir -p /var/spool/postfix/etc
cp /etc/resolv.conf /var/spool/postfix/etc/
cp /etc/hosts /var/spool/postfix/etc/
cp /etc/services /var/spool/postfix/etc/

# Wait for blacklist service
echo "Waiting for blacklist service..."
for i in {1..10}; do
  if curl -s http://blacklist_service:5000/health > /dev/null; then
    echo "Blacklist service is ready!"
    break
  fi
  echo "Attempt $i: Waiting for blacklist service..."
  sleep 2
done

# Set file permissions
chmod 755 /usr/local/bin/*.py 2>/dev/null || true
chmod 644 /etc/postfix/cert.pem 2>/dev/null || true
chmod 600 /etc/postfix/key.pem 2>/dev/null || true

# Start supervisord
echo "Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf