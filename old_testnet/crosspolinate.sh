#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Usage: $0 <target_directory>"
    exit 1
fi

# Remove trailing slash for clean paths
TARGET_DIR="${1%/}"
BASE_DIR="${BASE_DIR:-$HOME/Desktop/i2p/i2pd_testnet/nodes/node}"

TARGET_RI="$TARGET_DIR/router.info"
TARGET_NETDB="$TARGET_DIR/netDb"
TARGET_NAME="$(basename "$TARGET_DIR")"

if [ ! -f "$TARGET_RI" ]; then
    echo "[!] Error: $TARGET_RI not found. You must run the target router at least once so it generates its keys."
    exit 1
fi

mkdir -p "$TARGET_NETDB"

shopt -s nullglob
NODE_DIRS=( "${BASE_DIR}"_* )
shopt -u nullglob

if [ ${#NODE_DIRS[@]} -eq 0 ]; then
    echo "[!] Error: No testnet nodes found matching ${BASE_DIR}_*"
    exit 1
fi

echo "[*] Cross-pollinating '$TARGET_NAME' with ${#NODE_DIRS[@]} testnet nodes..."

for NODE_DIR in "${NODE_DIRS[@]}"; do
    NODE_NUM="${NODE_DIR##*_}"
    NODE_RI="$NODE_DIR/router.info"
    NODE_NETDB="$NODE_DIR/netDb"

    if [ -f "$NODE_RI" ]; then
        # 1. Inject target router into testnet node's netDb
        cp "$TARGET_RI" "$NODE_NETDB/routerInfo-${TARGET_NAME}.dat"
        
        # 2. Inject testnet node into target router's netDb
        cp "$NODE_RI" "$TARGET_NETDB/routerInfo-node${NODE_NUM}.dat"
    else
        echo "[!] Warning: router.info missing in $NODE_DIR"
    fi
done

echo "[+] Cross-pollination complete."
