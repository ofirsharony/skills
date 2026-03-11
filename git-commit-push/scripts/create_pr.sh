#!/bin/bash
set -e

TITLE=""
BODY=""
LABELS=""
OPEN_BROWSER=true

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case $1 in
    --title)
      TITLE="$2"
      shift 2
      ;;
    --body)
      BODY="$2"
      shift 2
      ;;
    --label)
      LABELS="$2"
      shift 2
      ;;
    --no-browser)
      OPEN_BROWSER=false
      shift
      ;;
    *)
      shift
      ;;
  esac
done

if ! command -v gh &> /dev/null; then
  echo "❌ GitHub CLI (gh) is not installed. Install it: https://cli.github.com/"
  exit 1
fi

if ! gh auth status &> /dev/null 2>&1; then
  echo "❌ Not authenticated with GitHub CLI. Run: gh auth login"
  exit 1
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)
DEFAULT_BRANCH=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}')
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"

if [ "$BRANCH" = "$DEFAULT_BRANCH" ]; then
  echo "❌ You're on $DEFAULT_BRANCH — create a feature branch first."
  exit 1
fi

EXISTING_PR=$(gh pr view "$BRANCH" --json url --jq '.url' 2>/dev/null || true)
if [ -n "$EXISTING_PR" ]; then
  echo "⚠️  A PR already exists for this branch: $EXISTING_PR"
  if [ "$OPEN_BROWSER" = true ]; then
    gh pr view --web
  fi
  exit 0
fi

if [ -z "$TITLE" ]; then
  TITLE=$(git log -1 --format='%s')
fi

# Use temp file to avoid newline issues in shell arguments
TMPFILE=$(mktemp /tmp/pr_body_XXXXXX.txt)

if [ -n "$BODY" ]; then
  echo -e "$BODY" > "$TMPFILE"
else
  echo -e "## Summary\n\nCreated from branch \`$BRANCH\`." > "$TMPFILE"
fi

PR_CMD=(gh pr create --title "$TITLE" --body-file "$TMPFILE")

if [ -n "$LABELS" ]; then
  IFS=',' read -ra LABEL_ARRAY <<< "$LABELS"
  for label in "${LABEL_ARRAY[@]}"; do
    PR_CMD+=(--label "$label")
  done
fi

echo "🔄 Creating PR: $TITLE"
"${PR_CMD[@]}"

rm -f "$TMPFILE"

echo ""
echo "✅ PR created for branch $BRANCH"

if [ "$OPEN_BROWSER" = true ]; then
  gh pr view --web
fi
