# !/bin/bash
apt-get update
apt-get install -y wireguard awscli

# Generate keys
SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo $SERVER_PRIVATE_KEY | wg pubkey)

echo $SERVER_PRIVATE_KEY | aws ssm put-parameter --name "/wireguard/server_private_key" --value - --type SecureString --overwrite --region ${AWS_REGION:-us-east-1}

# Setup WG config
cat > /etc/wireguard/wg0.conf << EOC
[Interface]
Address = 10.8.0.1/24
PrivateKey = $SERVER_PRIVATE_KEY
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOC

systemctl enable --now wg-quick@wg0
