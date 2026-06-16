#!/bin/sh

echo "Generating i2pd.conf..."

ROUTER_IP="$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)"
export ROUTER_IP

envsubst < /i2pd.conf.template > /var/lib/i2pd/i2pd.conf

try_push() {
	while [ ! -f /var/lib/i2pd/router.info ]; do
		sleep 1
	done
	# cp /var/lib/i2pd/router.info "/var/netdb/routerInfo-researcher.dat"
	cp /var/lib/i2pd/router.info "/var/netdb/routerInfo-dTyfoJzmJCRNQCcSDYzcowIOjU46qZl3XAfSsXeEYFg=.dat"
}

try_push &

exec i2pd --conf=/var/lib/i2pd/i2pd.conf --datadir=/var/lib/i2pd
