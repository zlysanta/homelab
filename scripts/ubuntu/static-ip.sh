#!/usr/bin/env bash
set -e

# ---- SUDO START ----
echo "[Homelab] Requesting sudo access..."
sudo -v

# ---- CHECK NMCLI ----
if ! command -v nmcli &>/dev/null; then
  echo "[Homelab] nmcli not found. Install NetworkManager first."
  exit 1
fi

# ---- GET CONNECTION LIST ----
mapfile -t CON_LIST < <(nmcli -t -f NAME con show)

if [[ ${#CON_LIST[@]} -eq 0 ]]; then
  echo "[Homelab] No network connections found."
  exit 1
fi

echo "[Homelab] Available connections:"
for i in "${!CON_LIST[@]}"; do
  echo "  [$i] ${CON_LIST[$i]}"
done

echo

# ---- SELECT CONNECTION ----
if [[ -t 0 ]]; then
  read -rp "[Homelab] Select connection number: " CON_INDEX
else
  read -rp "[Homelab] Select connection number: " CON_INDEX < /dev/tty
fi

if ! [[ "$CON_INDEX" =~ ^[0-9]+$ ]] || [[ "$CON_INDEX" -ge "${#CON_LIST[@]}" ]]; then
  echo "[Homelab] Invalid selection."
  exit 1
fi

CON_NAME="${CON_LIST[$CON_INDEX]}"
echo "[Homelab] Selected: $CON_NAME"

# ---- IP ADDRESS ----
if [[ -t 0 ]]; then
  read -rp "[Homelab] Enter static IP: " IP_ADDR
else
  read -rp "[Homelab] Enter static IP: " IP_ADDR < /dev/tty
fi

# ---- GATEWAY ----
if [[ -t 0 ]]; then
  read -rp "[Homelab] Enter gateway: " GATEWAY
else
  read -rp "[Homelab] Enter gateway: " GATEWAY < /dev/tty
fi

# ---- DNS ----
if [[ -t 0 ]]; then
  read -rp "[Homelab] Enter DNS servers (comma-separated): " DNS
else
  read -rp "[Homelab] Enter DNS servers (comma-separated): " DNS < /dev/tty
fi

if [[ -z "$CON_NAME" || -z "$IP_ADDR" || -z "$GATEWAY" || -z "$DNS" ]]; then
  echo "[Homelab] Missing required values. Exiting."
  exit 1
fi

echo "[Homelab] Applying static configuration..."

# ---- APPLY CONFIG ----
sudo nmcli con mod "$CON_NAME" ipv4.addresses "$IP_ADDR"
sudo nmcli con mod "$CON_NAME" ipv4.gateway "$GATEWAY"
sudo nmcli con mod "$CON_NAME" ipv4.dns "$DNS"
sudo nmcli con mod "$CON_NAME" ipv4.method manual
sudo nmcli con mod "$CON_NAME" ipv4.ignore-auto-dns yes

echo "[Homelab] Restarting connection..."
sudo nmcli con down "$CON_NAME" || true
sudo nmcli con up "$CON_NAME"

echo "[Homelab] Done."
nmcli -p con show "$CON_NAME"