#!/bin/bash
# Script to diagnose Postfix SMTP proxy issues
set -e

echo "===== POSTFIX SMTP PROXY DIAGNOSTIC TOOL ====="
echo "Running comprehensive diagnostics..."

# Check container status
echo -e "\n===== CONTAINER STATUS ====="
docker-compose ps

# Check services are running
echo -e "\n===== SERVICE STATUS ====="
docker-compose exec smtp_proxy supervisorctl status

# Check network connectivity
echo -e "\n===== NETWORK DIAGNOSTICS ====="
echo "Docker networks:"
docker network ls

echo -e "\nNetwork details:"
docker network inspect postfix_net

echo -e "\nBlacklist service IP address:"
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' blacklist_service

# DNS resolution test
echo -e "\n===== DNS RESOLUTION TEST ====="
docker-compose exec smtp_proxy bash -c "dig blacklist_service"
docker-compose exec smtp_proxy bash -c "getent hosts blacklist_service"

# Test blacklist service directly
echo -e "\n===== BLACKLIST SERVICE TEST ====="
docker-compose exec smtp_proxy bash -c "curl -v http://blacklist_service:5000/health"

# Check Postfix configuration
echo -e "\n===== POSTFIX CONFIGURATION CHECK ====="
docker-compose exec smtp_proxy bash -c "postconf -n | grep restriction"
docker-compose exec smtp_proxy bash -c "postconf -n | grep policy"
docker-compose exec smtp_proxy bash -c "ls -la /etc/postfix/cert.pem /etc/postfix/key.pem"

# Check TLS certificate validity
echo -e "\n===== TLS CERTIFICATE CHECK ====="
docker-compose exec smtp_proxy bash -c "openssl x509 -in /etc/postfix/cert.pem -text -noout | grep -E 'Subject:|Issuer:|Not Before:|Not After :'"

# Check service logs
echo -e "\n===== CONTAINER LOGS ====="
echo "Last 20 lines of blacklist_service logs:"
docker-compose logs --tail=20 blacklist_service

echo -e "\nLast 20 lines of smtp_proxy logs:"
docker-compose logs --tail=20 smtp_proxy

# Check Postfix mail logs
echo -e "\n===== POSTFIX MAIL LOGS ====="
docker-compose exec smtp_proxy bash -c "grep -i 'error\\|warning\\|fatal' /var/log/postfix/postfix.log | tail -20"

echo -e "\n===== CHROOT ENVIRONMENT CHECK ====="
docker-compose exec smtp_proxy bash -c "ls -la /var/spool/postfix/etc/"

echo -e "\n===== SMTP TEST ====="
echo "Testing SMTP connection to the proxy:"
docker-compose exec smtp_proxy bash -c "nc -zv localhost 2525"

echo -e "\n===== DIAGNOSTIC COMPLETE ====="
echo "If you're still having issues, please check the full logs with:"
echo "docker-compose logs -f"