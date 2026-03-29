#!/bin/bash

# Configuration
PROJECT_DIR="/home/mjackson/MacContainers" # ADJUST THIS PATH TO YOUR SERVER'S PATH
BRANCH="main"

# Navigate to project directory
cd "$PROJECT_DIR" || exit 1

# Fetch the latest changes from the remote
git fetch origin

# Check if we are behind the remote
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "origin/$BRANCH")

# helper for logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

if [ "$LOCAL" != "$REMOTE" ]; then
    log "Updates detected. Pulling from $BRANCH..."
    git pull origin "$BRANCH"

    log "Restarting containers after update..."
    podman-compose down
fi

# Always ensure all containers are running (idempotent)
log "Ensuring containers are up..."
podman-compose up -d
log "Done."
