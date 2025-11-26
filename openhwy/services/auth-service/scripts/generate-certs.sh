# scripts/generate-certs.sh
#!/bin/bash

# Generate self-signed certificates for local development

set -e

CERT_DIR="../certs"
DOMAIN="localhost"

echo "🔐 Generating self-signed certificates for local development..."

# Create certs directory
mkdir -p $CERT_DIR

# Generate private key
openssl genrsa -out $CERT_DIR/server-key.pem 4096

# Generate certificate signing request
openssl req -new -key $CERT_DIR/server-key.pem -out $CERT_DIR/server-csr.pem -subj "/C=US/ST=CA/L=San Francisco/O=Auth Service/CN=$DOMAIN"

# Generate self-signed certificate
openssl x509 -req -in $CERT_DIR/server-csr.pem -signkey $CERT_DIR/server-key.pem -out $CERT_DIR/server-cert.pem -days 365

# Clean up CSR
rm $CERT_DIR/server-csr.pem

echo "✅ Certificates generated in $CERT_DIR/"
echo "   - server-cert.pem"
echo "   - server-key.pem"
echo ""
echo "⚠️  These are self-signed certificates for development only!"
