#!/bin/bash

set -e

echo "🔍 Fetching latest version of node_exporter from GitHub..."
NODE_EXPORTER_VERSION=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep tag_name | cut -d '"' -f 4)

DOWNLOAD_URL="https://github.com/prometheus/node_exporter/releases/download/${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION#v}.linux-amd64.tar.gz"
INSTALL_DIR="/opt/node_exporter"
SERVICE_FILE="/etc/systemd/system/node_exporter.service"

echo "🔧 Updating system packages..."
sudo apt-get update -y

echo "📦 Installing dependencies..."
sudo apt-get install -y curl tar

echo "⬇️ Downloading Node Exporter $NODE_EXPORTER_VERSION..."
curl -LO "$DOWNLOAD_URL"

echo "📂 Extracting..."
tar -xzf "node_exporter-${NODE_EXPORTER_VERSION#v}.linux-amd64.tar.gz"

echo "🚚 Moving to $INSTALL_DIR..."
sudo mkdir -p "$INSTALL_DIR"
sudo cp "node_exporter-${NODE_EXPORTER_VERSION#v}.linux-amd64/node_exporter" "$INSTALL_DIR"

echo "🧹 Cleaning up..."
rm -rf "node_exporter-${NODE_EXPORTER_VERSION#v}.linux-amd64"*

echo "⚙️ Creating systemd service..."
sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=nobody
ExecStart=$INSTALL_DIR/node_exporter
Restart=always

[Install]
WantedBy=default.target
EOF

echo "📡 Enabling and starting Node Exporter service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

echo "✅ Node Exporter ($NODE_EXPORTER_VERSION) is running on port 9100!"
echo "👉 Try: curl http://localhost:9100/metrics"
