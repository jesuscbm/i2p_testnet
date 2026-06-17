#!/bin/sh

# Force verbose Java logging to stdout
cat <<EOF > /i2p/.i2p/logger.config
logger.defaultLevel=DEBUG
logger.displayOnScreen=true
logger.consoleBufferSize=100000
EOF
chown i2p:i2p /i2p/.i2p/logger.config

ROUTER_IP=$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
export ROUTER_IP
echo "Java Node IP mapped to: $ROUTER_IP"

mkdir -p /i2p/.i2p
envsubst < /router.config.template > /i2p/.i2p/router.config

# Enable web console
cat <<EOF > /i2p/.i2p/clients.config
clientApp.0.main=net.i2p.router.web.RouterConsoleRunner
clientApp.0.name=I2P Router Console
clientApp.0.args=7657 0.0.0.0 ./webapps/
clientApp.0.delay=2
clientApp.0.startOnLoad=true
EOF

chown i2p:i2p /i2p/.i2p/clients.config

echo "Starting..."

try_push() {
    while [ ! -f /i2p/.i2p/router.info ]; do
        sleep 2
    done
    
    sleep 1
    
    # 2. Extraer el hash base64 de I2P nativamente en Busybox/Alpine
    HEX_LEN=$(od -An -N2 -j385 -t x1 /i2p/.i2p/router.info | tr -d ' \n')
    SIZE=$((387 + 0x$HEX_LEN))
    IDENT=$(dd if=/i2p/.i2p/router.info bs=1 count=$SIZE 2>/dev/null | \
            openssl dgst -sha256 -binary | \
            base64 | tr '+/' '-~')

    cp /i2p/.i2p/router.info "/var/netdb/routerInfo-$IDENT.dat"
    
    touch /i2p/.i2p/pushed.flag
}

try_push &

exec /startapp.sh
