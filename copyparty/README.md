# Copyparty File Server

Copyparty is a portable file server that provides web-based file sharing and management with authentication support. This module automates the installation and configuration of Copyparty as a systemd user service.

## What it does

- Installs Copyparty (if not already installed)
- Creates a systemd user service for automatic startup
- Configures file sharing directories with authentication
- Enables the service to run at boot and in the background

## Prerequisites

- Arch Linux with `paru` (or `yay`)
- systemd (for service management)
- A directory to share (default: `~/Videos`)

## Configuration

The script will prompt you for:
- **Username**: The account name for authentication (default: current user)
- **Password**: The password for the account
- **Shared directory**: The directory to share (default: `~/Videos`)
- **Port**: The port to run the server on (default: 3923)

A configuration file will be created at `~/.config/copyparty.conf` to store these settings securely.

## Usage

### Apply Setup

Run the setup script to install and configure Copyparty:

```bash
./apply_copyparty_setup.sh
```

The script will:
1. Check if Copyparty is installed, install if needed
2. Prompt for configuration settings
3. Create the configuration file
4. Set up the systemd user service
5. Enable and start the service

### Access the Server

After setup, access the file server at:
```
http://localhost:3923
```

### Revert Setup

To remove Copyparty configuration and stop the service:

```bash
./revert_copyparty_setup.sh
```

This will:
- Stop and disable the systemd service
- Remove the service file
- Remove the configuration file
- Optionally uninstall Copyparty (prompts for confirmation)

## Service Management

After setup, you can manage the service with:

```bash
# Check status
systemctl --user status copyparty.service

# View logs
journalctl --user -u copyparty.service -f

# Stop service
systemctl --user stop copyparty.service

# Start service
systemctl --user start copyparty.service

# Restart service
systemctl --user restart copyparty.service
```

## Security Notes

- The configuration file stores credentials in plain text at `~/.config/copyparty.conf`
- Ensure this file has appropriate permissions (600)
- Consider using a strong password
- The service runs as a user service, not as root