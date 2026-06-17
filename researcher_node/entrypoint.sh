#!/bin/sh

echo "Generating i2pd.conf..."

ROUTER_IP="$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)"
export ROUTER_IP

envsubst < /i2pd.conf.template > /var/lib/i2pd/i2pd.conf

try_push() {
	while [ ! -f /var/lib/i2pd/router.info ]; do
		sleep 1
	done
	
	LEN=$(od -An -N2 -j385 -t x1 /var/lib/i2pd/router.info | tr -d ' ')
	SIZE=$((387 + LEN))
	IDENT=$(dd if=/var/lib/i2pd/router.info bs=1 count=$SIZE 2>/dev/null | \
			openssl dgst -sha256 -binary | \
			base64 | tr '+/' '-~' )

	cp /var/lib/i2pd/router.info "/var/netdb/routerInfo-$IDENT.dat"

	touch /var/lib/i2pd/pushed.flag
}

try_push &

exec i2pd --conf=/var/lib/i2pd/i2pd.conf --datadir=/var/lib/i2pd
