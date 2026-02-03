#!/bin/bash
set -e

echo "=== Instagram Sync Started: $(date) ==="

cd /app/repo

# Pull latest changes
echo "Pulling latest changes..."
git pull --rebase

# Run the Instagram scraper
echo "Running grab_posts.py..."
if [ -f instagram/grab_posts.py ]; then
    python instagram/grab_posts.py
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
    echo "Changes pushed successfully!"
else
    echo "No changes detected"
fi

echo "=== Instagram Sync Completed: $(date) ==="
