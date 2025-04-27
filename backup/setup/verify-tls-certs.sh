#!/bin/bash
# Script to verify TLS certificates for SMTP proxy
set -e

# Set variables
CERT_DIR="/app/togotrek"
CERT_FILE="$CERT_DIR/cert.pem"
KEY_FILE="$CERT_DIR/key.pem"

# Check if files exist
if [ ! -f "$CERT_FILE" ]; then
    echo "ERROR: Certificate file not found: $CERT_FILE"
    exit 1
fi

if [ ! -f "$KEY_FILE" ]; then
    echo "ERROR: Private key file not found: $KEY_FILE"
    exit 1
fi

# Check file permissions
CERT_PERMS=$(stat -c %a "$CERT_FILE")
KEY_PERMS=$(stat -c %a "$KEY_FILE")

echo "Certificate permissions: $CERT_PERMS (should be 644)"
echo "Private key permissions: $KEY_PERMS (should be 600)"

if [ "$KEY_PERMS" != "600" ]; then
    echo "WARNING: Private key should have 600 permissions. Fixing..."
    chmod 600 "$KEY_FILE"
fi

if [ "$CERT_PERMS" != "644" ]; then
    echo "WARNING: Certificate should have 644 permissions. Fixing..."
    chmod 644 "$CERT_FILE"
fi

# Verify certificate
echo -e "\nCertificate details:"
openssl x509 -in "$CERT_FILE" -text -noout | grep -E 'Subject:|Issuer:|Not Before:|Not After :'

# Verify that private key matches certificate
echo -e "\nVerifying that private key matches certificate..."
CERT_MODULUS=$(openssl x509 -in "$CERT_FILE" -modulus -noout | openssl md5)
KEY_MODULUS=$(openssl rsa -in "$KEY_FILE" -modulus -noout | openssl md5)

if [ "$CERT_MODULUS" == "$KEY_MODULUS" ]; then
    echo "SUCCESS: Private key matches certificate"
else
    echo "ERROR: Private key does not match certificate"
    exit 1
fi

echo -e "\nTesting certificate with OpenSSL s_client..."
# Create a test server
openssl s_server -cert "$CERT_FILE" -key "$KEY_FILE" -accept 12345 -www &
SERVER_PID=$!
sleep 1

# Test connection to the server
echo -e "\nTesting TLS connection..."
openssl s_client -connect localhost:12345 -servername smtp.togotrek.com </dev/null 2>/dev/null | grep "Verify return code"

# Kill the test server
kill $SERVER_PID

echo -e "\nCertificate verification complete!"