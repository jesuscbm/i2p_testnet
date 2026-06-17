#!/bin/sh

echo "Waiting for testnet certificates..."
while [ ! -f /shared_certs/testnet.crt ] || [ ! -f /shared_certs/reseed.crt ]; do
  sleep 1
done

# Force verbose Java logging to stdout
cat <<EOF > /i2p/.i2p/logger.config
logger.defaultLevel=DEBUG
logger.displayOnScreen=true
logger.consoleBufferSize=100000
EOF
chown i2p:i2p /i2p/.i2p/logger.config

cp /shared_certs/reseed.crt /usr/local/share/ca-certificates/reseed.crt
cp /shared_certs/testnet.crt /usr/local/share/ca-certificates/testnet.crt
update-ca-certificates > /dev/null 2>&1

ROUTER_IP=$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
export ROUTER_IP
echo "Java Node IP mapped to: $ROUTER_IP"

mkdir -p /i2p/.i2p
envsubst < /router.config.template > /i2p/.i2p/router.config

mkdir -p /i2p/.i2p/certificates/reseed
cp /shared_certs/testnet.crt /i2p/.i2p/certificates/reseed/testnet.crt
chown -R i2p:i2p /i2p/.i2p/certificates

echo "Starting..."

exec /startapp.sh
