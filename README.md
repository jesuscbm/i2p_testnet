# I2P Isolated Docker Testnet

This repository provides a fully dockerized, isolated I2P network (Testnet) for
security research and client modification testing.

The entire network is designed to be **ephemeral**. All data, routing tables,
and cryptographic keys are destroyed upon shutdown, guaranteeing a clean slate
for every test.

## Quick Start

> NOTE: The testnet includes configuration for an attacker and sybils using
> custom code. This code is not included in the repository, so removing them
> from the docker-compose.yml is the quickest way to launch the testnet.

**1. Start the Network**
Build the images and start all nodes in the background. It takes 30-60 seconds
for cryptographic keys to generate and exploratory tunnels to stabilize.

```bash
docker compose up -d --build
```

**2. Access the Network**
The founder nodes expose their web interfaces to your host machine:

* i2pd Researcher: `http://localhost:7069`
* Java Researcher: `http://localhost:7657`

**3. Browse the Victim Website**
The `victim` container hosts a lightweight internal website (eepsite). To visit
it, find its `.b32.i2p` address in its local control panel
(`http://localhost:7071`), and use the researcher proxy from your host:

```bash
curl -x http://127.0.0.1:4444 http://<victim-address>.b32.i2p
```

**4. Tear Down**
You must destroy the network and its shared volumes to clear the NetDB for the
next session.

```bash
docker compose down -v
```

## Node Architecture

The testnet uses a custom NetID (87) to strictly prevent nodes from bridging
into the public mainnet.

### The Target

* **`victim/`**: An i2pd node hosting a functional HTTP website using a
  built-in busybox server. This acts as your primary target for routing,
  eclipse, or deanonymization attacks.

### The Experimental Sandbox (Incomplete by Design)

* **`attacker/`** & **`sybil/`**: These nodes are intentionally incomplete.
  They are workspaces designed to compile and run modified I2P source code
  located in their respective `src/` directories. If you do not need them for
  your current test, you can easily remove or comment them out in the
  `docker-compose.yml` without breaking the network.

### The Core Infrastructure

* **`reseed/`**: A local HTTPS server that bundles and distributes the initial
  network map (`su3` files).
* **Founders (`researcher_node/`, `java_researcher/`)**: Standard nodes that
  bridge the testnet to your host machine for observation.
* **Network Swarm (`i2pd/`, `i2p/`)**: Background nodes used to scale the
  network, provide cover traffic, and build stable multi-hop tunnels.

## The Bootstrap Process

Bootstrapping an isolated I2P network requires existing peers. This testnet
solves the "chicken and egg" problem automatically using a shared volume:

1. **Founder Initialization:** The `researcher_node` and `java_researcher` boot
   first and generate their cryptographic identities.
2. **Identity Injection:** The founder nodes extract their RouterInfo hashes
   and copy them directly into a shared Docker volume (`shared_netdb`).
3. **Reseed Packaging:** The `reseed` container waits until exactly two
   RouterInfos are present in the shared volume. Once verified, it
   cryptographically signs them into an `i2pseeds.su3` file and starts serving
   it via HTTPS.
4. **Swarm Ignition:** The rest of the network (`victim`, `attacker`, swarm
   nodes) boots, queries the local reseed server, downloads the initial map,
   and instantly discovers the founders.

## Configuration

Configuration is managed at two levels:

**1. docker-compose.yml**
This is the main control surface. You can quickly adjust the scale of the
network by changing the `replicas` value under the swarm services (e.g.,
`replicas: 10`). Some environment variables are available to configure the
nodes

**2. Template Files**
Core I2P parameters (tunnel lengths, bandwidth limits) are located in files
like `i2pd.conf.template` or `router.config.template` inside each directory.
The entrypoint scripts use `envsubst` to dynamically inject IP addresses and
variables into these templates at runtime. Edit these files before building to
alter the behavior of specific node types.

## TODO

These are some areas of improvement for the Test Network.
- Improved bootstrapping. Right now only the two researcher nodes act as the
  initial seeds for the network. Ideally, the amount of initial seeders should
  be easily scalable.
- Post-Quantum encryption. For an unknown reason, I2P and I2Pd nodes fail to
  communicate using ML-KEM in this setup. Right now, the testnet configures
  I2Pd nodes not to use Post-Quantum.
- Subnets. Docker does allow to customize subnets of specific containers using
  IPAM. However, easily scaling random-looking IP assignment is not
  supported. The alternative would involve a script to automatically generate
  many individual docker-compose.yml entries, or using completely different
  technologies.
