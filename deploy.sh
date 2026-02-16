#!/usr/bin/env bash
# Deploy rendered dashboard to GitHub Pages (gh-pages branch)
# Usage: bash deploy.sh

set -e

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
SITE_DIR="$REPO_ROOT/dashboard/_site"

# 1. Render
echo ">> Rendering dashboard..."
cd "$REPO_ROOT/dashboard"
quarto render index.qmd
quarto render trends.qmd

# 2. Deploy to gh-pages
echo ">> Deploying to gh-pages..."
cd "$REPO_ROOT"
git stash --quiet 2>/dev/null || true
git checkout gh-pages

# Clear old files (keep .git)
git rm -rf . --quiet 2>/dev/null || true

# Copy rendered output
cp -r "$SITE_DIR"/* .

# Commit and push
git add -A
git commit -m "Deploy $(date +%Y-%m-%d)" --allow-empty
git push upstream gh-pages

# Return to main
git checkout main --quiet
git stash pop --quiet 2>/dev/null || true

echo ">> Done! Site will update in ~1 minute."
