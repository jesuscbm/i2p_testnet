> This is an older, simpler test network

# i2pd Testnet Toolkit

A lightweight suite of bash scripts designed to rapidly deploy, manage, and
cross-pollinate local i2pd test networks. No reseeding server is simulated,
initial router discovery is done manually. All nodes use the same network
interface, meaning they share the same IP, and they will use port ranges.

## Scripts Overview

* **`create_testnet.sh <number_of_nodes>`**: Generates the specified number of
  testnet nodes, provisions their `i2pd.conf` files, launches them temporarily
  to generate cryptographic keys, and cross-pollinates their `router.info`
  files so they know about each other.
* **`launch_testnet.sh`**: Discovers all configured nodes in the `BASE_DIR` and
  launches them concurrently. Includes graceful shutdown handling via `Ctrl+C`.
* **`crosspolinate.sh <target_directory>`**: Injects an external node (e.g., a
  victim or attacker node) into the testnet's `netDb`, and conversely injects
  the testnet nodes into the external node's `netDb`.

## Environment Variables

All scripts respect the following environment variables to allow flexible
execution without editing the source code:

* `I2PD_BIN`: Path to the `i2pd` executable. (Defaults to the system `i2pd`).
* `BASE_DIR`: The prefix directory for the testnet nodes. (Defaults to
  `./nodes/node`).

---

## Example Scenario: Victim vs. Attacker

In this scenario, we will deploy a 5-node testnet using a standard binary,
while launching an "attacker" node and a "victim" node, each using their own
custom-compiled `i2pd` binaries (e.g., the victim could use sanitizer and the
attacker malicious software).

### 1. Create the Testnet

First, generate a 5-node baseline network using your testnet binary.

```bash
export I2PD_BIN="/path/to/testnet_build/i2pd"
export BASE_DIR="./testnet/node"

./create_testnet.sh 5
```

### 2. Initialize the External Nodes

Before cross-pollinating, the attacker and victim nodes must run at least once
to generate their initial cryptographic identities (`router.info`).

```bash
# Initialize Victim
mkdir -p ./victim
/path/to/victim_build/i2pd --datadir=./victim &
VIC_PID=$!
sleep 5 && kill -INT $VIC_PID

# Initialize Attacker
mkdir -p ./attacker
/path/to/attacker_build/i2pd --datadir=./attacker &
ATT_PID=$!
sleep 5 && kill -INT $ATT_PID
```

### 3. Cross-Pollinate

Integrate the victim and attacker into the 5-node testnet. This ensures the
testnet floodfills know about the external nodes, and the external nodes know
about the testnet.

```bash
# Export BASE_DIR so the script knows where the testnet is located
export BASE_DIR="./testnet/node"

./crosspolinate.sh ./victim
./crosspolinate.sh ./attacker
```

*(Note: To ensure the attacker and victim know about each other immediately
without waiting for exploratory network database lookups, you can manually copy
`./victim/router.info` to `./attacker/netDb/routerInfo-victim.dat` and vice
versa).*

### 4. Launch the Environment

Start the testnet using the `launch_testnet.sh` script, then manually start the
victim and attacker using their respective custom binaries.

```bash
# 1. Start the testnet
I2PD_BIN="/path/to/testnet_build/i2pd" BASE_DIR="./testnet/node"
./launch_testnet.sh

# 2. Start the Victim
/path/to/victim_build/i2pd --datadir=./victim --conf=./victim/i2pd.conf

# 3. Start the Attacker
/path/to/attacker_build/i2pd --datadir=./attacker --conf=./attacker/i2pd.conf
```

---

## TODO / Future Enhancements

* **Virtual Interfaces & Subnets:** Currently, all testnet nodes bind to
  `127.0.0.1` using incrementing ports. To better simulate WAN routing,
  distance metrics, and prevent localized Sybil protections from triggering,
  the deployment scripts should be updated to utilize virtual networking
  interfaces (e.g., `ip link add type dummy` or `tuntap`). This will allow
  binding each testnet node to a unique `10.x.x.x` or `172.16.x.x` IP address
  across different simulated subnets.

* **Support for the Java implementation:** Allowing to have a mixed testnet.
