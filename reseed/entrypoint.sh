#!/bin/sh

RESEED_BIN="/var/lib/i2p/go/src/i2pgit.org/idk/reseed-tools/reseed-tools"
NETDB_DIR="/var/lib/i2p/i2p-config/netDb"
cd /var/lib/i2p/i2p-config/reseed || exit 1
cp -r /var/lib/i2p/go/src/i2pgit.org/idk/reseed-tools/content ./content

NUM_RI=${NUM_RI:-3}

$RESEED_BIN reseed --signer=testnet --netdb=$NETDB_DIR --port=8443 --ip=0.0.0.0 --yes=true --numRi=$NUM_RI --tlsHost=reseed &
RESEED_PID=$!

echo "Waiting for certificates to be generated..."
while [ ! -f testnet.crt ] || [ ! -f reseed.crt ]; do
  sleep 1
done

cp *.crt /shared_certs/
echo "Certificates exported."

kill $RESEED_PID
wait $RESEED_PID 2>/dev/null

echo "Waiting for $NUM_RI router.info files from nodes..."
while true; do
    count=$(find $NETDB_DIR -name "routerInfo-*.dat" 2>/dev/null | wc -l)
    if [ "$count" -ge "$NUM_RI" ]; then
        echo "Found $count identities. Rebuilding SU3..."
        break
    fi
    sleep 2
done

exec $RESEED_BIN reseed --signer=testnet --netdb=$NETDB_DIR --port=8443 --ip=0.0.0.0 --yes=true --numRi=$NUM_RI --tlsHost=reseed
