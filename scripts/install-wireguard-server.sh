#!/usr/bin/env bash
set -euo pipefail
# For a normal Ubuntu VPS you own, physically located in India.
# Do NOT run inside Termux/PRoot. Review provider firewall before use.

if [[ "${EUID}" -ne 0 ]]; then echo "Run with sudo: sudo bash $0"; exit 1; fi
if ! grep -qi ubuntu /etc/os-release; then echo "Ubuntu Server required."; exit 1; fi
if ! command -v systemctl >/dev/null 2>&1; then echo "systemd is required; this is not a Termux/PRoot environment."; exit 1; fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y wireguard iptables curl qrencode
WAN_IF="$(ip -o -4 route show to default | awk '{print $5}' | head -n1)"
[[ -n "$WAN_IF" ]] || { echo "Could not detect network interface."; exit 1; }

umask 077
install -d -m 700 /etc/wireguard/clients
SERVER_PRIV="$(wg genkey)"; SERVER_PUB="$(printf '%s' "$SERVER_PRIV" | wg pubkey)"
CLIENT_PRIV="$(wg genkey)"; CLIENT_PUB="$(printf '%s' "$CLIENT_PRIV" | wg pubkey)"
PSK="$(wg genpsk)"
PUBLIC_IP="$(curl -4fsS --max-time 8 https://api.ipify.org || true)"
[[ -n "$PUBLIC_IP" ]] || PUBLIC_IP="REPLACE_WITH_VPS_PUBLIC_IPV4"

cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = 10.66.66.1/24
ListenPort = 51820
PrivateKey = ${SERVER_PRIV}
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ${WAN_IF} -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ${WAN_IF} -j MASQUERADE

[Peer]
PublicKey = ${CLIENT_PUB}
PresharedKey = ${PSK}
AllowedIPs = 10.66.66.2/32
EOF

cat > /etc/sysctl.d/99-wireguard-forward.conf <<'EOF'
net.ipv4.ip_forward=1
EOF
sysctl --system >/dev/null

cat > /etc/wireguard/clients/android.conf <<EOF
[Interface]
PrivateKey = ${CLIENT_PRIV}
Address = 10.66.66.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = ${SERVER_PUB}
PresharedKey = ${PSK}
Endpoint = ${PUBLIC_IP}:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
chmod 600 /etc/wireguard/wg0.conf /etc/wireguard/clients/android.conf
systemctl enable --now wg-quick@wg0

echo
echo "WireGuard service started."
echo "Detected public IP: $PUBLIC_IP"
echo "Detected network interface: $WAN_IF"
echo
echo "REQUIRED MANUAL STEPS:"
echo "1) Allow inbound UDP 51820 in your VPS/cloud firewall/security rules."
echo "2) If UFW is enabled: sudo ufw allow 51820/udp"
echo "3) Confirm the endpoint IP is really in India."
echo "4) Securely transfer /etc/wireguard/clients/android.conf to your Android device."
echo "5) Do NOT upload the client config to GitHub or share it publicly."
echo
echo "Optional QR display in a private SSH terminal:"
echo "qrencode -t ansiutf8 < /etc/wireguard/clients/android.conf"
