#!/bin/bash

# Ensure log files have proper permissions
mkdir -p /var/log
touch /var/log/mail.log
chmod 644 /var/log/mail.log

# Start rsyslog
service rsyslog start || rsyslogd

# Initialize Postfix directories
mkdir -p /var/spool/postfix/public/pickup
mkdir -p /var/spool/postfix/public/cleanup
mkdir -p /var/spool/postfix/public/qmgr
chown -R postfix:postfix /var/spool/postfix

# Configure Postfix to relay through Gmail
postconf -e 'relayhost = [smtp.gmail.com]:587'
postconf -e 'smtp_use_tls = yes'
postconf -e 'smtp_sasl_auth_enable = yes'
postconf -e 'smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd'
postconf -e 'smtp_sasl_security_options = noanonymous'
postconf -e 'smtp_tls_security_level = encrypt'

# Process password file
postmap /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db

# Enable submission port
postconf -M submission/inet="submission inet n - n - - smtpd"
postconf -P "submission/inet/syslog_name=postfix/submission"
postconf -P "submission/inet/smtpd_tls_security_level=encrypt"
postconf -P "submission/inet/smtpd_sasl_auth_enable=yes"

# Start Postfix
service postfix stop || true
sleep 1
postfix start

# Keep container running and show logs
tail -f /var/log/mail.log