#!/bin/bash
# Don't use set -e so we can handle errors gracefully

echo "=== Instagram Sync Started: $(date) ==="

# Ensure SSH uses the correct key (cron has a minimal environment)
export GIT_SSH_COMMAND="ssh -i /home/syncuser/.ssh/id_ed25519 -o StrictHostKeyChecking=no"

cd /app/repo

# Pull latest changes
echo "Pulling latest changes..."
git pull --rebase

# Run the Instagram scraper with retry logic
echo "Running grab_posts.py..."
if [ -f instagram/grab_posts.py ]; then
    # Load Instagram session if available
    INSTA_SESSION_ARGS=""
    if [ -f /app/session/session-hausofsutra ]; then
        echo "Using saved Instagram session"
        # Copy session to expected location
        mkdir -p ~/.config/instaloader
        cp /app/session/session-hausofsutra ~/.config/instaloader/
        INSTA_SESSION_ARGS="--login hausofsutra"
    fi

    # Run with timeout and capture exit code
    timeout 300 python instagram/grab_posts.py
    SYNC_RESULT=$?

    if [ $SYNC_RESULT -eq 124 ]; then
        echo "WARNING: Sync timed out after 5 minutes"
    elif [ $SYNC_RESULT -ne 0 ]; then
        echo "WARNING: grab_posts.py exited with code $SYNC_RESULT"
        echo "This may be due to Instagram rate limiting. Will retry next scheduled run."
    fi
else
    echo "ERROR: instagram/grab_posts.py not found!"
    exit 1
fi

# Check for changes and commit if any
if [ -n "$(git status --porcelain)" ]; then
    echo "Changes detected, committing..."
    git add -A
    git commit -m "Auto-sync Instagram feed [skip ci]"
    git push
    PUSH_RESULT=$?
    if [ $PUSH_RESULT -eq 0 ]; then
        echo "Changes pushed successfully!"
    else
        echo "WARNING: git push failed with code $PUSH_RESULT"
    fi
else
    echo "No changes detected"
fi

echo "=== Instagram Sync Completed: $(date) ==="
