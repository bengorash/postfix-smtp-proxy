#!/bin/bash
set -e

# Create sasl_passwd file for Gmail authentication
if [ ! -f /etc/postfix/sasl_passwd ]; then
  echo "[${SMTP_HOST:-smtp.gmail.com}]:${SMTP_PORT:-587} ${SMTP_USER}:${SMTP_PASS}" > /etc/postfix/sasl_passwd
  postmap /etc/postfix/sasl_passwd
  chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
  chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
fi

# Update dynamic configuration
postconf -e "myhostname = ${HOSTNAME:-smtp.togotrek.com}"
postconf -e "relayhost = [${SMTP_HOST:-smtp.gmail.com}]:${SMTP_PORT:-587}"

# Environment variables for blacklist service
export API_URL=${API_URL:-"http://blacklist_service:5000"}
export API_KEY=${API_KEY:-"550e8400-e29b-41d4-a716-446655440000"}
export LOG_DIR=${LOG_DIR:-"/var/log/postfix"}

# Make sure log directories exist with proper permissions
mkdir -p ${LOG_DIR}
chmod 755 ${LOG_DIR}

# Ensure the postfix directory has the right permissions
mkdir -p /var/spool/postfix/pid
chown -R postfix:root /var/spool/postfix/
chmod 755 /var/spool/postfix/

# Copy host DNS info to chroot jail
cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf

# Double-check script permissions
if [ ! -x /usr/local/bin/blacklist_policy.py ] || [ ! -x /usr/local/bin/health_monitor.py ]; then
  chmod 755 /usr/local/bin/blacklist_policy.py /usr/local/bin/health_monitor.py
fi

# Verify certificate permissions
if [ -f /etc/postfix/cert.pem ] && [ -f /etc/postfix/key.pem ]; then
  chmod 644 /etc/postfix/cert.pem
  chmod 600 /etc/postfix/key.pem
  chown root:root /etc/postfix/cert.pem /etc/postfix/key.pem
fi

# Create supervisor log directory
mkdir -p /var/log/supervisor
chmod 755 /var/log/supervisor

# Initialize postfix
/usr/sbin/postfix -c /etc/postfix check || {
  echo "Postfix configuration check failed"
  exit 1
}

echo "Starting services with supervisor..."
# Start supervisor (which manages all services)
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf