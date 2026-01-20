# Fedora Server - Podman Home Stack

A complete Home Assistant stack running on **Fedora Server** with **Podman** (ARM64/M1 compatible). Includes Home Assistant, Z-Wave JS UI, Matter Server/Hub, and a self-hosted GitHub Actions runner.

## 🏠 Services

| Service | Description | Ports |
|---------|-------------|-------|
| **Home Assistant** | Home automation platform | `8123` (host network) |
| **Z-Wave JS UI** | Z-Wave controller & configuration | `8091` (UI), `3000` (WebSocket) |
| **Matter Server** | Matter protocol support for HA | Host network |
| **Matter Hub** | Bridges HA devices to Google Home | Host network |
| **Prowlarr** | Indexer manager/proxy | `9696` |
| **GitHub Runner** | Self-hosted Actions runner | N/A |
| **Context7 MCP** | Live documentation for AI agents | `8002` (HTTP) |
| **Sosumi MCP** | Apple docs (Swift, SwiftUI, HIG) | `8001` (HTTP) |

## 📋 Prerequisites

- **Fedora Server** (or compatible Linux with Podman)
- **Podman** and **podman-compose**
- **Z-Wave USB stick** (e.g., Zooz ZST39) at `/dev/ttyUSB0`

### Install Podman & Compose

```bash
sudo dnf install -y podman podman-compose
```

### Enable Podman Socket (for GitHub Runner)

```bash
sudo systemctl enable --now podman.socket
```

## 🚀 Quick Start

1. **Clone this repository** to your server:
   ```bash
   git clone git@github.com:XonDesk/MacContainers.git ~/FedoraServer
   cd ~/FedoraServer
   ```

2. **Setup Environment Variables**:
   ```bash
   cp .env.example .env
   nano .env  # Add your secrets and configuration here
   ```

3. **Start all services**:
   ```bash
   sudo podman-compose up -d
   ```

3. **Enable container restart on reboot**:
   ```bash
   sudo systemctl enable podman-restart
   ```
   > ⚠️ Unlike Docker, Podman requires this service for containers to restart after a system reboot.

4. **Access Home Assistant** at `http://<your-server-ip>:8123`

## ⚙️ Configuration

### Timezone
Update the `TZ` environment variable in `podman-compose.yaml` for each service:
```yaml
- TZ=America/Los_Angeles  # Change to your timezone
```

### Z-Wave USB Device
If your Z-Wave stick is at a different path, update the `devices` section:
```yaml
devices:
  - /dev/ttyUSB0:/dev/zwave  # Change /dev/ttyUSB0 to your device
```

### Matter Hub Token
Generate a Long-Lived Access Token in Home Assistant:
1. Go to your Profile → Security → Long-Lived Access Tokens
2. Create a new token and paste it in `HAMH_HOME_ASSISTANT_ACCESS_TOKEN`

### GitHub Actions Runner
The runner is pre-configured for the AudioVibes repository. To use with a different repo:
1. Go to **Repository Settings → Actions → Runners → New self-hosted runner**
2. Copy the token and update `RUNNER_TOKEN` in `podman-compose.yaml`
3. Update `REPO_URL` to your repository

## 🔄 Auto-Update Setup

This repo includes systemd units for automatic updates from GitHub.

### Install the Timer

```bash
# Copy the service and timer files
sudo cp podman-update.service /etc/systemd/system/
sudo cp podman-update.timer /etc/systemd/system/

# Edit paths in the service file to match your setup
sudo nano /etc/systemd/system/podman-update.service

# Enable and start the timer
sudo systemctl daemon-reload
sudo systemctl enable --now podman-update.timer

# Check timer status
systemctl list-timers | grep podman
```

The timer will:
- Run 5 minutes after boot
- Run every hour thereafter
- Pull changes from `main` and restart containers if updates are found

## 🤖 MCP Servers (for Remote Agents)

MCP servers exposed over HTTP using Supergateway, allowing remote AI agents to connect.

### Endpoints

| Server | Local Endpoint | Description |
|--------|----------------|-------------|
| **Sosumi** | `http://<server-ip>:8001/mcp` | Apple Developer docs (Swift, SwiftUI, HIG) |
| **Context7** | `http://<server-ip>:8002/mcp` | Live library documentation and code examples |

> 💡 Sosumi can also be accessed directly at `https://sosumi.ai/mcp`

### Connecting from Remote Agents

Configure your MCP client to use Streamable HTTP transport:

```json
{
  "mcpServers": {
    "sosumi": {
      "type": "http",
      "url": "http://<server-ip>:8001/mcp"
    },
    "context7": {
      "type": "http",
      "url": "http://<server-ip>:8002/mcp"
    }
  }
}
```

### Health Checks

Each MCP server exposes a `/health` endpoint:
- `http://<server-ip>:8001/health` - Sosumi
- `http://<server-ip>:8002/health` - Context7

### Build MCP Containers
```bash
sudo podman-compose build sosumi-mcp context7-mcp
sudo podman-compose up -d sosumi-mcp context7-mcp
```

## 📁 Directory Structure

```
FedoraServer/
├── podman-compose.yaml      # Main compose file
├── Dockerfile.mcp-servers   # MCP server container
├── podman-update.service    # Systemd service for auto-updates
├── podman-update.timer      # Systemd timer (hourly)
├── update_containers.sh     # Update script
├── config/                  # Service data (gitignored)
│   ├── ha/                  # Home Assistant config
│   ├── zwave-js-ui/         # Z-Wave JS UI data
│   ├── matter/              # Matter Server data
│   ├── matter-hub/          # Matter Hub data
│   └── prowlarr/            # Prowlarr config
└── README.md
```

## 🛠️ Useful Commands

```bash
# View all running containers
sudo podman ps

# View logs for a specific service
sudo podman logs -f homeassistant

# Restart a single service
sudo podman-compose restart homeassistant

# Stop all services
sudo podman-compose down

# Pull latest images and restart
sudo podman-compose pull && sudo podman-compose up -d
```

## 📝 Notes

- **Transferring to new device?** See [TRANSFER_GUIDE.md](TRANSFER_GUIDE.md) for how to move your secrets and config.
- Services using `network_mode: host` share the host's network for mDNS/UPnP discovery
- The `:Z` volume suffix enables SELinux compatibility
- Config directories are persisted locally and excluded from git
