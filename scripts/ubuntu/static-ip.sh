#!/usr/bin/env bash
set -e

# ---- SUDO START ----
echo "[Homelab] Requesting sudo access..."
sudo -v

# ---- CHECK NMCLI ----
if ! command -v nmcli &>/dev/null; then
  echo "[Network] nmcli not found. Install NetworkManager first."
  exit 1
fi

# ---- SHOW CONNECTIONS ----
echo "[Network] Available connections:"
nmcli con show

echo

# ---- CONNECTION NAME ----
if [[ -t 0 ]]; then
  read -rp "[Network] Enter connection name to modify: " CON_NAME
else
  read -rp "[Network] Enter connection name to modify: " CON_NAME < /dev/tty
fi

# ---- IP ADDRESS ----
if [[ -t 0 ]]; then
  read -rp "[Network] Enter static IP (e.g. 192.168.1.50/24): " IP_ADDR
else
  read -rp "[Network] Enter static IP (e.g. 192.168.1.50/24): " IP_ADDR < /dev/tty
fi

# ---- GATEWAY ----
if [[ -t 0 ]]; then
  read -rp "[Network] Enter gateway (e.g. 192.168.1.1): " GATEWAY
else
  read -rp "[Network] Enter gateway (e.g. 192.168.1.1): " GATEWAY < /dev/tty
fi

# ---- DNS ----
if [[ -t 0 ]]; then
  read -rp "[Network] Enter DNS servers (comma-separated): " DNS
else
  read -rp "[Network] Enter DNS servers (comma-separated): " DNS < /dev/tty
fi

if [[ -z "$CON_NAME" || -z "$IP_ADDR" || -z "$GATEWAY" || -z "$DNS" ]]; then
  echo "[Network] Missing required values. Exiting."
  exit 1
fi

echo "[Network] Applying static configuration..."

# ---- APPLY CONFIG ----
sudo nmcli con mod "$CON_NAME" ipv4.method manual
sudo nmcli con mod "$CON_NAME" ipv4.addresses "$IP_ADDR"
sudo nmcli con mod "$CON_NAME" ipv4.gateway "$GATEWAY"
sudo nmcli con mod "$CON_NAME" ipv4.dns "$DNS"
sudo nmcli con mod "$CON_NAME" ipv4.ignore-auto-dns yes

echo "[Network] Restarting connection..."
sudo nmcli con down "$CON_NAME" || true
sudo nmcli con up "$CON_NAME"

echo "[Network] Done."
nmcli -p con show "$CON_NAME"