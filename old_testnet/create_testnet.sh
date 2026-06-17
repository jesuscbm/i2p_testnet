#!/usr/bin/env bash

# Configuration
I2PD_BIN="${I2PD_BIN:-$(command -v i2pd)}"
BASE_DIR="${BASE_DIR:-./nodes/node}"
export NET_ID=164 # Exported for envsubst
GENERATE_TIME=30

# Start ports. Nodes will use the ports from start+1 to start+num_nodes
START_PORT=9010
START_HTTP=7080
START_HTTP_PROXY=4450
START_SOCKS_PROXY=4480

if [ -z "$1" ]; then
    echo "Usage: $0 <number_of_nodes>"
    exit 1
fi

if [ -z "$I2PD_BIN" ] || [ ! -x "$I2PD_BIN" ]; then
    echo "[!] Error: i2pd binary not found or not executable. Set I2PD_BIN."
    exit 1
fi

if [ ! -f "node_i2pd.conf" ]; then
    echo "[!] Error: node_i2pd.conf template not found in current directory."
    exit 1
fi

NUM_NODES=$1

echo "[*] Cleaning up existing i2pd instances globally..."
killall -INT i2pd-daemon i2pd 2>/dev/null
sleep 2
killall -9 i2pd-daemon i2pd 2>/dev/null

echo "[*] Removing previous identities..."
rm -rf "${BASE_DIR}_"*

echo "[*] Creating configurations for $NUM_NODES nodes..."
for i in $(seq 1 "$NUM_NODES"); do
    export NODE_DIR="${BASE_DIR}_${i}"
    mkdir -p "$NODE_DIR/netDb"

    export PORT=$((START_PORT + i))
    export HTTP_PORT=$((START_HTTP + i))
    export H_PROXY=$((START_HTTP_PROXY + i))
    export S_PROXY=$((START_SOCKS_PROXY + i))

    # Parse template and output to node directory
    envsubst < "node_i2pd.conf" > "$NODE_DIR/i2pd.conf"
done

echo "[*] Launching nodes to generate base cryptographic identities..."
PIDS=()
for i in $(seq 1 "$NUM_NODES"); do
    NODE_DIR="${BASE_DIR}_${i}"
    "$I2PD_BIN" --datadir="$NODE_DIR" --conf="$NODE_DIR/i2pd.conf" &
    PIDS+=($!) # Capture PIDs to kill later
done

echo "[*] Waiting $GENERATE_TIME seconds for routers to generate keys..."
sleep "$GENERATE_TIME"

echo "[*] Stopping specific testnet nodes to perform cross-pollination..."
kill -INT "${PIDS[@]}" 2>/dev/null
sleep 2
kill -9 "${PIDS[@]}" 2>/dev/null
sleep 2

echo "[*] Cross-pollinating netDb files..."
for src in $(seq 1 "$NUM_NODES"); do
    SRC_DIR="${BASE_DIR}_${src}"
    SRC_RI="$SRC_DIR/router.info"

    if [ ! -f "$SRC_RI" ]; then
        echo "[!] Warning: router.info not found for Node $src"
        continue
    fi

    for dest in $(seq 1 "$NUM_NODES"); do
        if [ "$src" -ne "$dest" ]; then
            DEST_NETDB="${BASE_DIR}_${dest}/netDb"
            cp "$SRC_RI" "$DEST_NETDB/routerInfo-${src}.dat"
        fi
    done
done

echo "[+] Setup Complete! To start your network, execute:"
for i in $(seq 1 "$NUM_NODES"); do
    echo "  $I2PD_BIN --datadir=${BASE_DIR}_${i} --conf=${BASE_DIR}_${i}/i2pd.conf &"
done
