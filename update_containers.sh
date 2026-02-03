#!/bin/bash

# Configuration
PROJECT_DIR="/Users/mjackson/Documents/MacContainers" # ADJUST THIS PATH TO YOUR SERVER'S PATH
BRANCH="main"

# Navigate to project directory
cd "$PROJECT_DIR" || exit 1

# Fetch the latest changes from the remote
# Ensure your SSH key is loaded in your agent or key is passwordless
git fetch origin

# Check if we are behind the remote
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "origin/$BRANCH")

if [ "$LOCAL" != "$REMOTE" ]; then
    echo "Updates detected. Pulling changes..."
    
    # helper for logging
    log() {
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    }

    log "Pulling from $BRANCH..."
    git pull origin "$BRANCH"
    
    log "Restarting containers..."
    # Using sudo if required, or rootless if configured
    podman-compose down
    podman-compose up -d
    
    log "Update complete."
else
    echo "No updates found."
fi
