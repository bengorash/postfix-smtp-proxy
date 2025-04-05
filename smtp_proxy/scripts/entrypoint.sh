#!/bin/bash
set -e  # Exit on any error

echo "Starting SMTP proxy container setup..."

# Create sasl_passwd file for Gmail authentication
if [ ! -f /etc/postfix/sasl_passwd ]; then
  echo "Creating SASL password file..."
  echo "[${SMTP_HOST:-smtp.gmail.com}]:${SMTP_PORT:-587} ${SMTP_USER}:${SMTP_PASS}" > /etc/postfix/sasl_passwd
  postmap /etc/postfix/sasl_passwd
  chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
  chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
  echo "SASL password file created and mapped successfully."
fi

# Update dynamic configuration
echo "Updating Postfix configuration..."
postconf -e "myhostname = ${HOSTNAME:-smtp.togotrek.com}"
postconf -e "relayhost = [${SMTP_HOST:-smtp.gmail.com}]:${SMTP_PORT:-587}"

# Environment variables for blacklist service
export API_URL=${API_URL:-"http://blacklist_service:5000"}
export API_KEY=${API_KEY:-"550e8400-e29b-41d4-a716-446655440000"}
export LOG_DIR=${LOG_DIR:-"/var/log/postfix"}

# Make sure log directories exist with proper permissions
echo "Setting up log directories..."
mkdir -p ${LOG_DIR}
chmod 755 ${LOG_DIR}

# Ensure the postfix directory has the right permissions
echo "Setting up Postfix directories and permissions..."
mkdir -p /var/spool/postfix/pid
chown -R postfix:root /var/spool/postfix/
chmod 755 /var/spool/postfix/

# Copy host DNS info to chroot jail (CRITICAL for service resolution)
echo "Setting up DNS resolution in chroot environment..."
mkdir -p /var/spool/postfix/etc
cp /etc/resolv.conf /var/spool/postfix/etc/
cp /etc/hosts /var/spool/postfix/etc/
cp /etc/services /var/spool/postfix/etc/

# Double-check script permissions
echo "Checking script permissions..."
if [ -f /usr/local/bin/blacklist_policy.py ]; then
  chmod 755 /usr/local/bin/blacklist_policy.py
fi

if [ -f /usr/local/bin/health_monitor.py ]; then
  chmod 755 /usr/local/bin/health_monitor.py
fi

# Verify certificate permissions
echo "Checking certificate permissions..."
if [ -f /etc/postfix/cert.pem ] && [ -f /etc/postfix/key.pem ]; then
  chmod 644 /etc/postfix/cert.pem
  chmod 600 /etc/postfix/key.pem
  chown root:root /etc/postfix/cert.pem /etc/postfix/key.pem
  echo "Certificate permissions set correctly."
else
  echo "ERROR: TLS certificates not found!"
  exit 1
fi

# Create supervisor log directory
echo "Setting up supervisor log directory..."
mkdir -p /var/log/supervisor
chmod 755 /var/log/supervisor

# Wait for blacklist service to be ready
echo "Waiting for blacklist service..."
for i in $(seq 1 30); do
  if curl -s http://blacklist_service:5000/health > /dev/null; then
    echo "Blacklist service is ready!"
    break
  fi
  echo "Waiting for blacklist service... attempt $i/30"
  sleep 1
  if [ $i -eq 30 ]; then
    echo "WARNING: Blacklist service did not respond to health check"
    echo "Will continue startup and retry connections later..."
  fi
done

# Test network connectivity
echo "Testing network connectivity to blacklist service..."
ping -c 1 blacklist_service || echo "WARNING: Cannot ping blacklist_service (this may be normal if ICMP is blocked)"
nc -zv blacklist_service 5000 || echo "WARNING: Cannot connect to blacklist_service:5000 with netcat"

# Initialize postfix with verbose error reporting
echo "Checking Postfix configuration..."
/usr/sbin/postfix -c /etc/postfix check || {
  echo "ERROR: Postfix configuration check failed with errors:"
  postconf -n
  echo "Checking specific configuration items..."
  [ -f /etc/postfix/sasl_passwd.db ] || echo "ERROR: sasl_passwd.db not found"
  grep -q "smtpd_recipient_restrictions" /etc/postfix/main.cf || echo "ERROR: Missing recipient restrictions"
  exit 1
}

echo "Starting services with supervisor..."
# Start supervisor (which manages all services)
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf