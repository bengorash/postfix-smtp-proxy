#!/bin/bash
# Script to generate new TLS certificates for SMTP proxy
set -e

# Set variables
DOMAIN="smtp.togotrek.com"
CERT_DIR="/app/togotrek/postfix"
CERT_FILE="$CERT_DIR/cert.pem"
KEY_FILE="$CERT_DIR/key.pem"
DAYS_VALID=3650  # 10 years

# Create directory if it doesn't exist
mkdir -p $CERT_DIR

# Generate OpenSSL configuration file
cat > openssl.cnf << EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = v3_ca

[dn]
C = US
ST = Arizona
L = Phoenix
O = TogoTrek
OU = Email
CN = $DOMAIN
emailAddress = admin@togotrek.com

[v3_ca]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
basicConstraints = CA:true
keyUsage = digitalSignature, keyEncipherment, keyCertSign
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = *.togotrek.com
DNS.3 = localhost
IP.1 = 127.0.0.1
EOF

echo "Generating private key..."
openssl genrsa -out $KEY_FILE 2048

echo "Generating certificate..."
openssl req -new -x509 -key $KEY_FILE -out $CERT_FILE -days $DAYS_VALID -config openssl.cnf

# Set proper permissions
chmod 600 $KEY_FILE
chmod 644 $CERT_FILE

echo "Certificates created successfully:"
echo "Private key: $KEY_FILE"
echo "Certificate: $CERT_FILE"
echo "Certificate details:"
openssl x509 -in $CERT_FILE -text -noout | grep -E 'Subject:|Issuer:|Not Before:|Not After :'