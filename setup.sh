#!/bin/bash

# 👤 Ask user for GitHub info before using sudo
read -p "📧 Enter your GitHub Email: " GIT_EMAIL
read -p "👤 Enter your GitHub Username: " GIT_USERNAME

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

# 🔧 Configure Git
echo "🔧 Configuring Git..."
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_USERNAME"

echo "📁 Setting up Drosera project..."

mkdir -p Drosera-Network && cd Drosera-Network

forge init -t drosera-network/trap-foundry-template

echo "📦 Installing Node dependencies with Bun..."
bun install

echo "🛠️ Building project with Forge..."
forge build

echo "✅ Setup complete! Your Drosera project is ready."
