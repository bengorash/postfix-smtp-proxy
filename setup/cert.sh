# Generate the private key
openssl genrsa -out /app/togotrek/postfix/key.pem 2048

# Generate a certificate signing request (CSR)
openssl req -new -key /app/togotrek/postfix/key.pem -out /app/togotrek/postfix/cert.csr -subj "/C=US/ST=Arizona/L=Phoenix/O=TogoTrek/OU=Email/CN=smtp.togotrek.com"

# Generate the certificate (self-signed)
openssl x509 -req -days 3650 -in /app/togotrek/postfix/cert.csr -signkey /app/togotrek/postfix/key.pem -out /app/togotrek/postfix/cert.pem

# Set proper permissions
chmod 600 /app/togotrek/postfix/key.pem
chmod 644 /app/togotrek/postfix/cert.pem