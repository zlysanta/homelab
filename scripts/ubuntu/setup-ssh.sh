#!/usr/bin/env bash

set -e

# ---- SUDO START ----
echo "Requesting sudo access..."
sudo -v

# ---- USER INPUT ----
echo "Paste your public SSH key (single line):"

if [[ -t 0 ]]; then
  read -rp "Enter SSH key: " SSH_KEY
else
  read -rp "Enter SSH key: " SSH_KEY < /dev/tty
fi

if [[ -z "$SSH_KEY" ]]; then
  echo "No SSH key provided. Exiting."
  exit 1
fi

# ---- AUTHORIZED KEYS SETUP ----
USER_HOME="$HOME"
SSH_DIR="$USER_HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

touch "$AUTHORIZED_KEYS"
chmod 600 "$AUTHORIZED_KEYS"

if grep -qxF "$SSH_KEY" "$AUTHORIZED_KEYS"; then
  echo "Key already exists in authorized_keys."
else
  echo "Adding SSH key..."
  echo "$SSH_KEY" >> "$AUTHORIZED_KEYS"
fi

# ---- SSH CONFIG HARDENING ----
SSHD_CONFIG="/etc/ssh/sshd_config"

backup="/etc/ssh/sshd_config.bak.$(date +%F-%H%M%S)"
sudo cp "$SSHD_CONFIG" "$backup"
echo "Backup created at $backup"

set_or_replace() {
  local key="$1"
  local value="$2"

  if grep -qE "^#?\s*${key}" "$SSHD_CONFIG"; then
    sudo sed -i "s|^#\?\s*${key}.*|${key} ${value}|" "$SSHD_CONFIG"
  else
    echo "${key} ${value}" | sudo tee -a "$SSHD_CONFIG" >/dev/null
  fi
}

echo "Updating sshd_config..."

set_or_replace "PermitRootLogin" "no"
set_or_replace "PubkeyAuthentication" "yes"
set_or_replace "PasswordAuthentication" "no"

# ---- VALIDATE CONFIG ----
echo "Validating SSH config..."
sudo sshd -t

# ---- RESTART SSH ----
echo "Restarting SSH service..."
if systemctl is-active --quiet ssh; then
  sudo systemctl restart ssh
elif systemctl is-active --quiet sshd; then
  sudo systemctl restart sshd
else
  echo "Warning: SSH service not found via systemctl."
fi

echo "Done. SSH hardened and key installed."
