#!/bin/bash
set -e

# --- Defaults ---
NO_STAGE=false
NO_PUSH=false
DRY_RUN=false
MESSAGE=""
BRANCH_NAME=""

# Patterns that should never be committed (checked even if .gitignore exists)
SUSPECT_PATTERNS=('.env' '.env.*' '*.pem' '*.key' '*.p12' '*.pfx' 'credentials.json' 'secrets.json' 'token.json' '.idea/' '.vscode/' '*.iml' '.DS_Store' 'Thumbs.db' 'node_modules/' '__pycache__/' '*.pyc' '.cache/' 'dist/' 'build/' '*.log')

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case $1 in
    --no-stage)
      NO_STAGE=true
      shift
      ;;
    --no-push)
      NO_PUSH=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --branch)
      BRANCH_NAME="$2"
      shift 2
      ;;
    *)
      MESSAGE="$1"
      shift
      ;;
  esac
done

# --- Check if we're in a git repo ---
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "❌ Not inside a git repository"
  exit 1
fi

# --- .gitignore auto-generation ---
if [ ! -f .gitignore ]; then
  echo "⚠️  No .gitignore found — generating one."

  GITIGNORE_CONTENT="# OS
.DS_Store
Thumbs.db

# IDE
.idea/
.vscode/
*.iml
*.swp
*.swo
*~

# Secrets
.env
.env.*
*.pem
*.key
*.p12
*.pfx
credentials.json
secrets.json
token.json

# Logs
*.log
"

  # Detect project type and add specific ignores
  if [ -f "package.json" ]; then
    GITIGNORE_CONTENT+="
# Node
node_modules/
dist/
build/
.cache/
coverage/
"
  fi

  if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "Pipfile" ]; then
    GITIGNORE_CONTENT+="
# Python
__pycache__/
*.pyc
*.pyo
.venv/
venv/
env/
*.egg-info/
dist/
build/
.pytest_cache/
.mypy_cache/
"
  fi

  if [ -f "go.mod" ]; then
    GITIGNORE_CONTENT+="
# Go
/vendor/
"
  fi

  if [ -f "Cargo.toml" ]; then
    GITIGNORE_CONTENT+="
# Rust
/target/
"
  fi

  if [ -f "Gemfile" ]; then
    GITIGNORE_CONTENT+="
# Ruby
/vendor/bundle/
/.bundle/
"
  fi

  echo "$GITIGNORE_CONTENT" > .gitignore
  echo "   Created .gitignore (detected project files and added relevant patterns)"
  echo ""
fi

# --- Switch or create branch if requested ---
if [ -n "$BRANCH_NAME" ]; then
  CURRENT=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  if [ "$CURRENT" != "$BRANCH_NAME" ]; then
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME" 2>/dev/null; then
      git checkout "$BRANCH_NAME"
    else
      git checkout -b "$BRANCH_NAME"
    fi
    echo "📌 On branch: $BRANCH_NAME"
  fi
fi

# --- Stage changes unless --no-stage ---
if [ "$NO_STAGE" = false ]; then
  git add .
else
  # Warn about unstaged changes when --no-stage is used
  UNSTAGED=$(git diff --name-only 2>/dev/null)
  if [ -n "$UNSTAGED" ]; then
    UNSTAGED_COUNT=$(echo "$UNSTAGED" | wc -l | tr -d ' ')
    echo "⚠️  $UNSTAGED_COUNT file(s) with unstaged changes will NOT be included:"
    echo "$UNSTAGED" | head -10 | sed 's/^/   /'
    if [ "$UNSTAGED_COUNT" -gt 10 ]; then
      echo "   ... and $((UNSTAGED_COUNT - 10)) more"
    fi
    echo ""
  fi
fi

# --- Check if there's anything to commit ---
if git diff --cached --quiet; then
  echo "⚠️  Nothing to commit (no staged changes)"
  exit 0
fi

# --- Suspect file check ---
STAGED_FILES=$(git diff --cached --name-only)
SUSPECT_FOUND=""

for pattern in "${SUSPECT_PATTERNS[@]}"; do
  # Match staged files against each pattern
  MATCHES=$(echo "$STAGED_FILES" | grep -E "(^|/)${pattern//\*/.*}$" 2>/dev/null || true)
  if [ -n "$MATCHES" ]; then
    SUSPECT_FOUND="${SUSPECT_FOUND}${MATCHES}"$'\n'
  fi
done

# Deduplicate
SUSPECT_FOUND=$(echo "$SUSPECT_FOUND" | sort -u | sed '/^$/d')

if [ -n "$SUSPECT_FOUND" ]; then
  echo "🚨 Potentially dangerous files staged for commit:"
  echo "$SUSPECT_FOUND" | sed 's/^/   /'
  echo ""
  echo "   These look like secrets, IDE config, or build artifacts."
  echo "   Unstaging them. Add to .gitignore or re-stage manually if intentional."
  echo ""

  # Unstage suspect files
  echo "$SUSPECT_FOUND" | while IFS= read -r file; do
    if [ -n "$file" ]; then
      git reset HEAD -- "$file" > /dev/null 2>&1 || true
    fi
  done

  # Re-check if anything remains
  if git diff --cached --quiet; then
    echo "⚠️  Nothing left to commit after removing suspect files"
    exit 0
  fi
fi

# --- Build file summary ---
COMMITTED_FILES=$(git diff --cached --name-status)
FILE_COUNT=$(echo "$COMMITTED_FILES" | wc -l | tr -d ' ')

# --- Default message if none provided ---
MESSAGE="${MESSAGE:-chore: update code}"

# --- Dry run: show what would happen and exit ---
if [ "$DRY_RUN" = true ]; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  echo "🔍 Dry run — no changes will be made"
  echo ""
  echo "   Branch:  $BRANCH"
  echo "   Message: $MESSAGE"
  echo "   Files ($FILE_COUNT):"
  echo "$COMMITTED_FILES" | sed 's/^/      /'
  echo ""
  echo "   Run without --dry-run to commit and push."

  # Unstage if we staged (don't leave side effects)
  if [ "$NO_STAGE" = false ]; then
    git reset HEAD > /dev/null 2>&1
  fi
  exit 0
fi

# --- Commit ---
git commit -m "$MESSAGE"

# --- Get current branch ---
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# --- Push (unless --no-push) ---
if [ "$NO_PUSH" = false ]; then
  git push -u origin "$BRANCH"

  echo ""
  echo "✅ Successfully committed and pushed to $BRANCH"
else
  echo ""
  echo "✅ Successfully committed to $BRANCH (not pushed)"
fi

echo ""
echo "   Commit:  $MESSAGE"
echo "   Files ($FILE_COUNT):"
echo "$COMMITTED_FILES" | sed 's/^/      /'
