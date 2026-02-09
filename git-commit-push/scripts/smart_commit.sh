#!/bin/bash
set -e

NO_STAGE=false
MESSAGE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --no-stage)
      NO_STAGE=true
      shift
      ;;
    *)
      MESSAGE="$1"
      shift
      ;;
  esac
done

# Default message if none provided
MESSAGE="${MESSAGE:-chore: update code}"

# Check if we're in a git repo
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "❌ Not inside a git repository"
  exit 1
fi

# Stage changes unless --no-stage
if [ "$NO_STAGE" = false ]; then
  git add .
fi

# Check if there's anything to commit
if git diff --cached --quiet; then
  echo "⚠️  Nothing to commit (no staged changes)"
  exit 0
fi

# Commit
git commit -m "$MESSAGE"

# Get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Push with upstream tracking
git push -u origin "$BRANCH"

echo "✅ Successfully pushed to $BRANCH"
