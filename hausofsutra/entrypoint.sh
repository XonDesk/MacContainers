#!/bin/bash
# Don't use set -e — volume mounts in rootless podman can cause
# permission errors on chown that we need to handle gracefully.

echo "=== Haus of Sutra Instagram Sync Container ==="
echo "Started at: $(date)"

# Setup SSH key
echo "Setting up SSH..."
if [ -f /home/syncuser/.ssh/id_ed25519_mounted ]; then
    cp /home/syncuser/.ssh/id_ed25519_mounted /home/syncuser/.ssh/id_ed25519
    chmod 600 /home/syncuser/.ssh/id_ed25519
    chown syncuser:syncuser /home/syncuser/.ssh/id_ed25519 2>/dev/null || true
    echo "SSH key configured"
else
    echo "WARNING: No SSH key mounted at /home/syncuser/.ssh/id_ed25519_mounted"
    echo "Git push operations will fail!"
fi

# Add GitHub to known_hosts
echo "Adding GitHub to known_hosts..."
ssh-keyscan -t ed25519 github.com >> /home/syncuser/.ssh/known_hosts 2>/dev/null
chown syncuser:syncuser /home/syncuser/.ssh/known_hosts 2>/dev/null || true
chmod 644 /home/syncuser/.ssh/known_hosts

# Setup git config
echo "Configuring git..."
su - syncuser -c "git config --global user.name '${GIT_USER_NAME:-Hausofsutra Bot}'"
su - syncuser -c "git config --global user.email '${GIT_USER_EMAIL:-bot@hausofsutra.local}'"

# Fix ownership on directories — tolerate failures on volume mounts
chown -R syncuser:syncuser /app 2>/dev/null || true
mkdir -p /app/session
chown -R syncuser:syncuser /app/session 2>/dev/null || true

# Fix log directory permissions so cron can write logs
chown -R syncuser:syncuser /var/log/hausofsutra 2>/dev/null || chmod 777 /var/log/hausofsutra

# Clone repo if not present
if [ ! -d /app/repo/.git ]; then
    echo "Cloning repository..."
    su - syncuser -c "git clone ${GITHUB_REPO} /app/repo"
else
    echo "Repository already exists, pulling latest..."
    su - syncuser -c "cd /app/repo && git pull --rebase"
fi

# Write environment variables into the crontab wrapper so cron picks them up
ENV_FILE="/app/sync-env.sh"
{
    echo "#!/bin/bash"
    echo "export PATH='/usr/local/bin:/usr/bin:/bin'"
    echo "export GIT_USER_NAME='${GIT_USER_NAME:-Hausofsutra Bot}'"
    echo "export GIT_USER_EMAIL='${GIT_USER_EMAIL:-bot@hausofsutra.local}'"
    echo "export GITHUB_REPO='${GITHUB_REPO}'"
    echo "export TZ='${TZ:-America/Los_Angeles}'"
} > "$ENV_FILE"
chmod +x "$ENV_FILE"
chown syncuser:syncuser "$ENV_FILE" 2>/dev/null || true

# Run initial sync
echo "Running initial sync..."
su - syncuser -c "/app/sync.sh" || echo "Initial sync failed — will retry on next cron run"

# Start cron in foreground
echo "Starting cron daemon..."
echo "Sync will run every 12 hours (midnight and noon)"
exec cron -f
