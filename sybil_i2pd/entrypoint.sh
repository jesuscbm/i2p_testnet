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

ROUTER_IP="$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)"
export ROUTER_IP

envsubst < /i2pd.conf.template > /var/lib/i2pd/i2pd.conf

echo "Waiting for startup..."
sleep 5

try_push() {
	while [ ! -f /var/lib/i2pd/router.info ]; do
		sleep 1
	done
	UUID=$(cat /proc/sys/kernel/random/uuid)
	cp /var/lib/i2pd/router.info "/var/netdb/routerInfo-$UUID.dat"
}

try_push &

exec i2pd --conf=/var/lib/i2pd/i2pd.conf --datadir=/var/lib/i2pd
