#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
CONFIG_FILE="$CONFIG_DIR/copyparty.conf"
SERVICE_FILE="$CONFIG_DIR/systemd/user/copyparty.service"

echo "=== Copyparty Setup Script ==="
echo ""

# Check if copyparty is installed
if ! command -v copyparty &> /dev/null; then
    echo "Copyparty is not installed. Installing via paru..."
    paru -S --needed --noconfirm copyparty
    echo "Copyparty installed successfully."
else
    echo "Copyparty is already installed."
fi

# Prompt for configuration
echo ""
echo "Please provide the following configuration:"
echo ""

# Get current username as default
CURRENT_USER=$(whoami)
read -p "Username (default: $CURRENT_USER): " USERNAME
USERNAME=${USERNAME:-$CURRENT_USER}

read -sp "Password: " PASSWORD
echo ""

read -p "Shared directory (default: $HOME/Videos): " SHARED_DIR
SHARED_DIR=${SHARED_DIR:-$HOME/Videos}

read -p "Port (default: 3923): " PORT
PORT=${PORT:-3923}

# Validate shared directory exists
if [ ! -d "$SHARED_DIR" ]; then
    echo "Directory $SHARED_DIR does not exist. Creating it..."
    mkdir -p "$SHARED_DIR"
fi

# Create config directory
mkdir -p "$CONFIG_DIR"

# Create configuration file
echo ""
echo "Creating configuration file at $CONFIG_FILE..."
cat > "$CONFIG_FILE" <<EOF
[global]
p: $PORT

[accounts]
$USERNAME: $PASSWORD

[/]
$SHARED_DIR
accs:
  rwmd: $USERNAME
EOF

# Set secure permissions on config file
chmod 600 "$CONFIG_FILE"
echo "Configuration file created with secure permissions."

# Create systemd user service directory
mkdir -p "$CONFIG_DIR/systemd/user"

# Create systemd service file
echo ""
echo "Creating systemd service file at $SERVICE_FILE..."
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Copyparty File Server
After=network.target

[Service]
Type=simple
ExecStart=$(which copyparty) -c $CONFIG_FILE
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

# Reload systemd user daemon
echo ""
echo "Reloading systemd user daemon..."
systemctl --user daemon-reload

# Enable service to start on boot
echo "Enabling service to start on boot..."
systemctl --user enable copyparty.service

# Start the service
echo "Starting copyparty service..."
systemctl --user start copyparty.service

# Enable lingering (so service runs even when not logged in)
echo "Enabling lingering for user service..."
sudo loginctl enable-linger "$USER" || echo "Note: Could not enable lingering. Service may stop when you log out."

# Verify service is running
echo ""
echo "Verifying service status..."
sleep 2
if systemctl --user is-active --quiet copyparty.service; then
    echo "✓ Copyparty service is running successfully."
else
    echo "✗ Copyparty service failed to start. Check logs with: journalctl --user -u copyparty.service"
    exit 1
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Access your file server at: http://localhost:$PORT"
echo ""
echo "Useful commands:"
echo "  Check status:  systemctl --user status copyparty.service"
echo "  View logs:     journalctl --user -u copyparty.service -f"
echo "  Stop service:  systemctl --user stop copyparty.service"
echo "  Start service: systemctl --user start copyparty.service"
echo ""
