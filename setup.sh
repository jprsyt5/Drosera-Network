#!/bin/bash

# 👤 Ask user for GitHub info before using sudo
read -p "📧 Enter your GitHub Email: " GIT_EMAIL < /dev/tty
read -p "👤 Enter your GitHub Username: " GIT_USERNAME < /dev/tty
read -p "Enter Your Private Key: " PRIVATE_KEY < /dev/tty
read -p "Enter Your Address: " WALLET_ADDRESS < /dev/tty
read -p "Enter Your RPC: " RPC_HOLESKY < /dev/tty

echo "🌐 Detecting external IP…"
VPS_IP=$(curl -s4 ifconfig.me)
echo "ℹ️  Detected VPS IP: $VPS_IP"

set -e  # Exit on error
set -o pipefail

echo "🚀 Starting system update..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -yq
sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade -yq

echo "📦 Installing required packages..."
sudo apt install -yq \
  curl ufw iptables build-essential git wget lz4 jq make gcc nano \
  automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev \
  libleveldb-dev tar clang bsdmainutils ncdu unzip

echo "🌿 Installing Drosera..."
curl -L https://app.drosera.io/install | bash

echo "🔁 Reloading shell environment..."
source /root/.bashrc

echo "⬆️ Updating Drosera..."
droseraup

echo "🔧 Installing Foundry..."
curl -L https://foundry.paradigm.xyz | bash
source /root/.bashrc
foundryup



# 🔧 Configure Git
echo "🔧 Configuring Git..."
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_USERNAME"

echo "📁 Setting up Drosera project..."

mkdir -p Drosera-Network && cd Drosera-Network

forge init -t drosera-network/trap-foundry-template

echo "🍞 Installing Bun..."
curl -fsSL https://bun.sh/install | bash
bun install

echo "🛠️ Building project with Forge..."
forge build


echo "🛜 Configuring Network..."
# Enable firewall
sudo ufw allow ssh
sudo ufw allow 22
sudo ufw allow 31313/tcp
sudo ufw allow 31314/tcp
sudo ufw --force enable

echo "📝 Configuring drosera.toml..."
cat > drosera.toml <<EOF
ethereum_rpc      = "$RPC_HOLESKY"
drosera_rpc       = "https://seed-node.testnet.drosera.io"
eth_chain_id      = 17000
drosera_address   = "0xea08f7d533C2b9A62F40D5326214f39a8E3A32F8"

[traps]

[traps.mytrap]
path                    = "out/HelloWorldTrap.sol/HelloWorldTrap.json"
response_contract       = "0xdA890040Af0533D98B9F5f8FE3537720ABf83B0C"
response_function       = "helloworld(string)"
cooldown_period_blocks  = 33
min_number_of_operators = 1
max_number_of_operators = 2
block_sample_size       = 10
private                 = true
whitelist               = ["$WALLET_ADDRESS"]
private_trap            = true
EOF

source /root/.bashrc

DROSERA_PRIVATE_KEY=$PRIVATE_KEY drosera apply

echo "✅ Trap Deployed!"

echo "Configuring Operator CLI..."
curl -LO https://github.com/drosera-network/releases/releases/download/v1.16.2/drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
tar -xvf drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
sudo cp drosera-operator /usr/bin


echo "🔑 Registering operator…"

drosera-operator register --eth-rpc-url "$RPC_HOLESKY" --eth-private-key "$PRIVATE_KEY"


echo "✅ Operator Succefully registered!"

echo "Configuring SystemD..."

sudo tee /etc/systemd/system/drosera.service > /dev/null <<EOF
[Unit]
Description=drosera node service
After=network-online.target

[Service]
User=$USER
Restart=always
RestartSec=15
LimitNOFILE=65535
ExecStart=$(which drosera-operator) node --db-file-path $HOME/.drosera.db --network-p2p-port 31313 --server-port 31314 \
    --eth-rpc-url $RPC_HOLESKY \
    --eth-backup-rpc-url https://1rpc.io/holesky \
    --drosera-address 0xea08f7d533C2b9A62F40D5326214f39a8E3A32F8 \
    --eth-private-key $PRIVATE_KEY \
    --listen-address 0.0.0.0 \
    --network-external-p2p-address $VPS_IP \
    --disable-dnr-confirmation true

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable drosera
sudo systemctl start drosera

echo "🎉 All done — your node + operator are running under systemd.."

