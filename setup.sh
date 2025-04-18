#!/bin/bash

set -e  # Exit on error
set -o pipefail

echo "🚀 Starting system update..."
sudo apt-get update && sudo apt-get upgrade -y

echo "📦 Installing required packages..."
sudo apt install -y \
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

echo "🍞 Installing Bun..."
curl -fsSL https://bun.sh/install | bash

echo "✅ All done! You may need to restart the terminal or source your .bashrc again."