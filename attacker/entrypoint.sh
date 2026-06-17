#!/bin/sh

echo "Waiting for certificates..."
while [ ! -f /shared_certs/testnet.crt ] || [ ! -f /shared_certs/reseed.crt ]; do
  sleep 1
done

# Trust certificates
mkdir -p /var/lib/i2pd/certificates/reseed
cp /shared_certs/testnet.crt /var/lib/i2pd/certificates/reseed/testnet.crt
export SSL_CERT_FILE=/shared_certs/reseed.crt

echo "Generating i2pd.conf..."

ROUTER_IP=$(hostname -i | awk '{print $1}')
export ROUTER_IP

envsubst < /i2pd.conf.template > /var/lib/i2pd/i2pd.conf

echo "Starting..."
exec /usr/local/bin/i2pd --conf=/var/lib/i2pd/i2pd.conf --datadir=/var/lib/i2pd
