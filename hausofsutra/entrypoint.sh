#!/bin/bash
set -e

echo "=== Haus of Sutra Instagram Sync Container ==="
echo "Started at: $(date)"

# Setup SSH key
echo "Setting up SSH..."
if [ -f /home/syncuser/.ssh/id_ed25519_mounted ]; then
    cp /home/syncuser/.ssh/id_ed25519_mounted /home/syncuser/.ssh/id_ed25519
    chmod 600 /home/syncuser/.ssh/id_ed25519
    chown syncuser:syncuser /home/syncuser/.ssh/id_ed25519
    echo "SSH key configured"
else
    echo "WARNING: No SSH key mounted at /home/syncuser/.ssh/id_ed25519_mounted"
    echo "Git push operations will fail!"
fi

# Add GitHub to known_hosts
echo "Adding GitHub to known_hosts..."
ssh-keyscan -t ed25519 github.com >> /home/syncuser/.ssh/known_hosts 2>/dev/null
chown syncuser:syncuser /home/syncuser/.ssh/known_hosts
chmod 644 /home/syncuser/.ssh/known_hosts

# Setup git config
echo "Configuring git..."
su - syncuser -c "git config --global user.name '${GIT_USER_NAME:-Hausofsutra Bot}'"
su - syncuser -c "git config --global user.email '${GIT_USER_EMAIL:-bot@hausofsutra.local}'"

# Clone repo if not present
if [ ! -d /app/repo/.git ]; then
    echo "Cloning repository..."
    su - syncuser -c "git clone ${GITHUB_REPO} /app/repo"
else
    echo "Repository already exists, pulling latest..."
    su - syncuser -c "cd /app/repo && git pull --rebase"
fi

# Ensure syncuser owns the app directory
chown -R syncuser:syncuser /app

# Export environment variables for cron
printenv | grep -E '^(GIT_|GITHUB_|TZ)' > /etc/environment

# Run initial sync
echo "Running initial sync..."
su - syncuser -c "/app/sync.sh" || echo "Initial sync completed (or failed - check logs)"

# Start cron in foreground
echo "Starting cron daemon..."
echo "Sync will run every 12 hours (midnight and noon)"
exec cron -f
