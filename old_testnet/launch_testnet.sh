#!/usr/bin/env bash

# Configuration with defaults
I2PD_BIN="${I2PD_BIN:-$(command -v i2pd)}"
BASE_DIR="${BASE_DIR:-./nodes/node}"

if [ -z "$I2PD_BIN" ] || [ ! -x "$I2PD_BIN" ]; then
    echo "[!] Error: i2pd binary not found or not executable. Set I2PD_BIN."
    exit 1
fi

shopt -s nullglob
NODE_CONFS=( "${BASE_DIR}"_*/i2pd.conf )
shopt -u nullglob

if [ ${#NODE_CONFS[@]} -eq 0 ]; then
    echo "[!] No nodes found matching ${BASE_DIR}_*. Run setup first."
    exit 1
fi

echo "[*] Inferred ${#NODE_CONFS[@]} nodes."
echo "[*] Launching testnet routers..."

PIDS=()
for conf in "${NODE_CONFS[@]}"; do
    NODE_DIR="$(dirname "$conf")"
    "$I2PD_BIN" --datadir="$NODE_DIR" --conf="$conf" &
    PIDS+=($!)
done

# Clean shutdown handler
shutdown() {
    echo -e "\n[*] Caught signal! Tearing down testnet..."
    kill -INT "${PIDS[@]}" 2>/dev/null
    sleep 2
    kill -9 "${PIDS[@]}" 2>/dev/null
    exit 0
}

trap shutdown SIGINT SIGTERM

echo "[+] Testnet is live. Press Ctrl+C to shut everything down."
wait
