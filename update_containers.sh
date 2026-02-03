#!/bin/bash

# Configuration
PROJECT_DIR="/Users/mjackson/Documents/MacContainers" # ADJUST THIS PATH TO YOUR SERVER'S PATH
BRANCH="main"

# Navigate to project directory
cd "$PROJECT_DIR" || exit 1

# Fetch the latest changes from the remote
# We use sudo -u to run git commands as the directory owner if we are running as root
# This prevents file permission issues
DIR_OWNER=$(stat -c '%U' "$PROJECT_DIR")

if [ "$(id -u)" -eq 0 ] && [ "$DIR_OWNER" != "root" ]; then
    GIT_CMD="sudo -u $DIR_OWNER git"
else
    GIT_CMD="git"
fi

$GIT_CMD fetch origin

# Check if we are behind the remote
LOCAL=$($GIT_CMD rev-parse @)
REMOTE=$($GIT_CMD rev-parse "origin/$BRANCH")

if [ "$LOCAL" != "$REMOTE" ]; then
    echo "Updates detected. Pulling changes..."
    
    # helper for logging
    log() {
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    }

    log "Pulling from $BRANCH..."
    $GIT_CMD pull origin "$BRANCH"
    
    log "Restarting containers..."
    # Configured to run as root via systemd since containers are rootful
    podman-compose down
    podman-compose up -d
    
    log "Update complete."
else
    echo "No updates found."
fi
