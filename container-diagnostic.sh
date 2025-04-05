#!/bin/bash
# In-container diagnostic script for Postfix

echo "===== POSTFIX CONTAINER DIAGNOSTIC TOOL ====="
echo "Running diagnostics inside the container..."

# Check OS and system info
echo -e "\n===== SYSTEM INFORMATION ====="
cat /etc/os-release
uname -a

# Check if Postfix is installed
echo -e "\n===== POSTFIX VERSION ====="
postconf mail_version 2>/dev/null || echo "ERROR: Postfix not found"

# Check Postfix configuration
echo -e "\n===== POSTFIX CONFIGURATION CHECK ====="
postfix check 2>&1

# Check main.cf settings
echo -e "\n===== MAIN.CF SETTINGS ====="
postconf -n | grep -E 'mydestination|mynetworks|inet_interfaces|myhostname|relayhost|smtpd_recipient_restrictions'

# Check master.cf settings
echo -e "\n===== MASTER.CF SERVICES ====="
postconf -M | grep '2525'

# Check certificate files
echo -e "\n===== TLS CERTIFICATE CHECK ====="
ls -la /etc/postfix/cert.pem /etc/postfix/key.pem

# Check sasl_passwd file
echo -e "\n===== SASL PASSWORD FILE CHECK ====="
if [[ -f /etc/postfix/sasl_passwd ]]; then
  echo "sasl_passwd file exists"
  postmap -q "[smtp.gmail.com]:587" hash:/etc/postfix/sasl_passwd || echo "Error querying sasl_passwd"
else
  echo "ERROR: sasl_passwd file not found"
fi

# Check network connectivity
echo -e "\n===== NETWORK CONNECTIVITY ====="
echo "Checking DNS resolution:"
host blacklist_service 2>/dev/null || echo "Cannot resolve blacklist_service"
echo "Checking connectivity to blacklist_service:"
nc -zv blacklist_service 5000 2>&1 || echo "Cannot connect to blacklist_service:5000"
echo "Checking connectivity to Gmail SMTP:"
nc -zv smtp.gmail.com 587 2>&1 || echo "Cannot connect to Gmail SMTP"

# Check critical directories and permissions
echo -e "\n===== DIRECTORY PERMISSIONS ====="
ls -la /var/spool/postfix/pid /var/log/postfix /etc/postfix

# Check running processes
echo -e "\n===== RUNNING PROCESSES ====="
ps aux | grep -E 'postfix|master|qmgr|pickup|smtpd'

# Try to manually start Postfix
echo -e "\n===== ATTEMPTING MANUAL POSTFIX START ====="
postfix stop
sleep 1
postfix start
sleep 2
postfix status

echo -e "\n===== DIAGNOSTIC COMPLETE ====="
echo "If you need more information, check the logs in /var/log/postfix/"