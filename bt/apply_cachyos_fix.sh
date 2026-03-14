#!/bin/bash
# CachyOS Hackable Bluetooth Fix Installer

echo "Installing CachyOS Bluetooth Hackable Fix..."

# 1. Apply Patch 1 (BR/EDR Classic Bluetooth)
echo "[1/4] Applying Classic Bluetooth Patch..."
echo "admin0" | sudo -S sed -i 's/^#\?ControllerMode = .*/ControllerMode = bredr/' /etc/bluetooth/main.conf

# 2. Create the unified restart script
echo "[2/4] Creating unified restart script..."
echo "admin0" | sudo -S bash -c 'cat << "EOF" > /usr/local/bin/bt-restart
#!/bin/bash
[ -n "$1" ] && sleep "$1"

if /usr/bin/systemctl restart bluetooth; then
    notify-send "Bluetooth" "Service Restarted Successfully" -i network-bluetooth 2>/dev/null
else
    notify-send "Bluetooth" "Restart Failed!" -i dialog-error 2>/dev/null
fi
EOF'
echo "admin0" | sudo -S chmod +x /usr/local/bin/bt-restart

# 3. Create Desktop Integrations
echo "[3/4] Creating Desktop Shortcuts and Autostart..."

mkdir -p ~/.local/share/applications/
cat << 'EOF' > ~/.local/share/applications/restart-bluetooth.desktop
[Desktop Entry]
Type=Application
Name=Restart Bluetooth
Comment=Restarts the bluetooth system service
Exec=/usr/local/bin/bt-restart
Icon=network-bluetooth
Terminal=false
Categories=System;
StartupNotify=false
EOF

mkdir -p ~/.config/autostart/
cat << 'EOF' > ~/.config/autostart/restart-bluetooth-login.desktop
[Desktop Entry]
Type=Application
Name=Restart Bluetooth on Login
Exec=/usr/local/bin/bt-restart 15
Icon=network-bluetooth
Terminal=false
X-KDE-autostart-phase=2
StartupNotify=false
EOF

# 4. Create Polkit Authorization
echo "[4/4] Configuring Polkit for passwordless restarts..."
echo "admin0" | sudo -S bash -c 'cat << "EOF" > /etc/polkit-1/rules.d/10-restart-bluetooth.rules
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        action.lookup("unit") == "bluetooth.service" &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOF'

echo "admin0" | sudo -S systemctl restart bluetooth

echo "============================================="
echo "Installation Complete!"
echo "A 'Restart Bluetooth' application has been created."
echo "You can find it in your application menu and pin it to your panel."