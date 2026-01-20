# Transferring MacContainers to a New Device

Since this repository uses a secured setup with `.gitignore`, your secrets and configuration files are **NOT** stored in GitHub. You must manually transfer them when setting up a new device.

## 1. Clone the Repository
On your new personal device:

```bash
git clone git@github.com:XonDesk/MacContainers.git ~/MacContainers
cd ~/MacContainers
```

## 2. Transfer Secured Files
You need to copy the `.env` file and the `config/` directory from your existing server/machine to the new one.

### Option A: Secure Copy (SCP)
Run this command **on your NEW device** (replace `user@old-machine-ip` with your source machine's details):

```bash
# Copy .env file
scp user@old-machine-ip:~/MacContainers/.env ~/MacContainers/

# Copy config directory (recursive)
scp -r user@old-machine-ip:~/MacContainers/config ~/MacContainers/
```

### Option B: Manual Creation
If you can't SCP, you can manually recreate the configuration:

1. **Create .env**:
   ```bash
   cp .env.example .env
   nano .env
   # Fill in your secrets (Tokens, Session IDs, Timezone)
   ```

2. **Restore Config Files**:
   - `config/firebase-mcp/service-account.json` (Required for Firebase MCP)
   - Other configs in `config/` will be auto-created by containers on first run if you don't care about preserving previous service data (like Z-Wave pairings or Home Assistant database).

## 3. Verify & Start
Check that your secrets are in place:
```bash
ls -la .env
ls -la config/
```

Start the stack:
```bash
sudo podman-compose up -d
```
