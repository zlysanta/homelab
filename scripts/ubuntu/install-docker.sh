#!/usr/bin/env bash

set -e

echo "[Homelab] Requesting sudo access..."
sudo -v

# ---- REMOVE OLD DOCKER VERSIONS ----
echo "[Homelab] Removing old Docker versions (if any)..."
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# ---- UPDATE + DEPENDENCIES ----
echo "[Homelab] Updating system and installing dependencies..."
sudo apt update
sudo apt install -y ca-certificates curl

# ---- ADD DOCKER GPG KEY ----
echo "[Homelab] Adding Docker GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# ---- ADD DOCKER REPOSITORY ----
echo "[Homelab] Adding Docker repository..."
echo \
  "Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc" | \
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null

# ---- INSTALL DOCKER ----
echo "[Homelab] Installing Docker..."
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# ---- ENABLE SERVICE ----
echo "[Homelab] Ensuring Docker is running..."
sudo systemctl enable docker
sudo systemctl start docker

# ---- OPTIONAL: NON-ROOT USER ----
if [[ -t 0 ]]; then
  read -rp "[Homelab] Add current user to docker group? (y/N): " ADD_USER
else
  read -rp "[Homelab] Add current user to docker group? (y/N): " ADD_USER < /dev/tty
fi

if [[ "$ADD_USER" =~ ^[Yy]$ ]]; then
  sudo usermod -aG docker "$USER"
  echo "[Homelab] Added $USER to docker group (log out/in required)."
fi

# ---- VERIFY INSTALL ----
echo "[Homelab] Running test container..."
sudo docker run hello-world

echo "[Homelab] Docker installation complete."
echo "[Homelab] Run: docker --version"
