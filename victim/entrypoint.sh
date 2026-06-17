#!/bin/sh

echo "Waiting for certificates..."
while [ ! -f /shared_certs/testnet.crt ] || [ ! -f /shared_certs/reseed.crt ]; do
  sleep 1
done

mkdir -p /var/www
echo "<h1>Victim node</h1>" > /var/www/index.html
chmod -R a+rw /var/www

# Trust certificates
mkdir -p /var/lib/i2pd/certificates/reseed
cp /shared_certs/testnet.crt /var/lib/i2pd/certificates/reseed/testnet.crt
export SSL_CERT_FILE=/shared_certs/reseed.crt

# Start lighttpd
httpd -p 127.0.0.1:8080 -h /var/www

echo "Generating i2pd.conf..."

ROUTER_IP="$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)"
export ROUTER_IP

envsubst < /i2pd.conf.template > /var/lib/i2pd/i2pd.conf

echo "Starting..."
exec i2pd --conf=/var/lib/i2pd/i2pd.conf --datadir=/var/lib/i2pd
