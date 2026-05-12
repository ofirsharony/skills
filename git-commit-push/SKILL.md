---
name: git-commit-push
description: Stage, commit, and push git changes with conventional commit messages, and optionally create a GitHub PR. Use when user wants to commit and push changes, mentions pushing to remote, asks to save and push their work, or wants to create a pull request. Also activates when user says "push changes", "commit and push", "push this", "push to github", "create a PR", "open a pull request", or similar git workflow requests.
---

# Git Commit & Push Workflow

Stage all changes, create a conventional commit, push to the remote branch, and optionally create a GitHub PR.

## When to Use

Activate when the user:

- Asks to push changes ("push this", "commit and push")
- Mentions saving work to remote ("save to github", "push to remote")
- Completes a feature and wants to share it
- Says phrases like "let's push this up" or "commit these changes"
- Wants to create a pull request ("create a PR", "open a PR", "submit a PR")

## Safety Checks (CRITICAL)

Before running the script, ALWAYS perform these checks:

1. **Only commit/push when the user explicitly asks**: Do NOT commit or push as a side effect of other work (e.g., editing code, testing, fixing a bug). Committing and pushing must always be a separate, user-initiated action.
2. **NEVER push unless the user EXPLICITLY says to push**: Words like "commit", "save", "move changes to branch" do NOT mean push. Only push when the user says "push", "push it", "push to remote", "push to github", or similar. **When in doubt, use `--no-push` and ask.** This is the most important rule.
3. **Verify the current branch**: Run `git branch --show-current` and confirm you are on the expected branch.
   - **NEVER push directly to `main` or `master`** unless the user explicitly says "push to master/main".
   - If you are on `main`/`master` and the user hasn't explicitly asked to push there, STOP and ask the user which branch to push to.

## Pre-flight: No Git Repo Yet

If the directory has no `.git` folder, set one up before running the script:

1. **Create the remote repo** (adjust name/visibility as needed):
   ```bash
   gh repo create <repo-name> --private --confirm
   ```

2. **Init locally and link with HTTPS** (prefer HTTPS — SSH often fails behind VPNs/corporate networks):
   ```bash
   git init
   git remote add origin https://github.com/<owner>/<repo-name>.git
   ```

Then proceed with the script below — it will handle the first commit and push.

## Commit Message Generation (CRITICAL)

**NEVER use the default `chore: update code` message.** Before calling the script, ALWAYS:

1. Run `git diff --cached --stat` (or `git diff --stat` if not yet staged) to understand what changed.
2. Generate a conventional commit message with type, optional scope, and description:
   - Format: `type(scope): description` or `type: description`
   - The scope should reflect the area of the codebase changed (e.g., `auth`, `api`, `ui`, `db`, `config`)
   - Use a scope when the change is localized to a specific module/area
   - Omit scope for cross-cutting changes

### Conventional Commit Prefixes

| Prefix | Use for |
|--------|---------|
| `feat:` | New feature |
| `fix:` | Bug fix |
| `refactor:` | Code restructuring |
| `docs:` | Documentation only |
| `style:` | Formatting, no logic change |
| `test:` | Adding or updating tests |
| `chore:` | Maintenance, deps, config |
| `ci:` | CI/CD changes |

### Examples

```
feat(auth): add JWT token refresh flow
fix(api): handle null response from payment gateway
refactor(db): extract query builder into separate module
docs: update README with deployment instructions
chore(deps): upgrade React to v19
```

## Workflow

**ALWAYS use the script** — do NOT run manual git commands.

**Default to `--no-push`**. Only omit `--no-push` when the user EXPLICITLY asks to push.

```bash
# Default: commit only, do NOT push
bash ~/.cursor/skills/git-commit-push/scripts/smart_commit.sh --no-push "feat(auth): add login endpoint"

# Only when user explicitly says "push":
bash ~/.cursor/skills/git-commit-push/scripts/smart_commit.sh "feat(auth): add login endpoint"
```

### Flags

| Flag | Effect |
|------|--------|
| `--no-stage` | Skip `git add .` — only commit what's already staged |
| `--no-push` | Commit locally without pushing to remote |
| `--dry-run` | Show what would be committed/pushed, then exit without changes |
| `--branch <name>` | Create or switch to a branch before committing |
| `--pr` | Create a GitHub PR after pushing (opens in browser) |
| `--pr-label <labels>` | Comma-separated labels for the PR (requires `--pr`) |

### Examples

```bash
# Standard: stage everything, commit (NO push — this is the default)
bash ~/.cursor/skills/git-commit-push/scripts/smart_commit.sh --no-push "fix: resolve race condition in worker pool"

# Selective staging: stage manually first, then commit only staged files
git add src/auth/
bash ~/.cursor/skills/git-commit-push/scripts/smart_commit.sh --no-stage --no-push "feat(auth): add OAuth2 provider"

# Preview what would be committed (only when user asks for dry run)
bash ~/.cursor/skills/git-commit-push/scripts/smart_commit.sh --dry-run "refactor: simplify error handling"

# Stage everything, commit AND push (ONLY when user explicitly asks to push)
bash ~/.cursor/skills/git-commit-push/scripts/smart_commit.sh "feat: add push notifications"

# Push to a new feature branch (ONLY when user explicitly asks to push)
bash ~/.cursor/skills/git-commit-push/scripts/smart_commit.sh --branch feature/notifications "feat: add push notifications"

# Commit, push, and open a PR (ONLY when user explicitly asks for PR)
bash ~/.cursor/skills/git-commit-push/scripts/smart_commit.sh --pr "feat(auth): add OAuth2 login"

# Commit, push, and open a labeled PR
bash ~/.cursor/skills/git-commit-push/scripts/smart_commit.sh --pr --pr-label "enhancement,auth" "feat(auth): add OAuth2 login"

# Full workflow: new branch + commit + push + PR
bash ~/.cursor/skills/git-commit-push/scripts/smart_commit.sh --branch feature/oauth --pr "feat(auth): add OAuth2 login"
```

### What the Script Does

1. Verifies we're in a git repo
2. **Auto-generates `.gitignore`** if missing (detects project type: Node, Python, Go, Rust, Ruby)
3. Creates/switches branch if `--branch` is used
4. Stages all changes (unless `--no-stage`)
5. Warns about unstaged files when `--no-stage` is used
6. **Safety check**: auto-unstages suspect files (secrets, IDE config, build artifacts, etc.)
7. Commits with the provided message
8. Pushes to the current branch with `-u` flag (unless `--no-push`)
9. Prints a summary of committed files
10. Creates a GitHub PR and opens it in the browser (if `--pr` is used)

### Safety: Auto-Unstaged Files

The script automatically detects and unstages files that likely shouldn't be committed:

- **Secrets**: `.env`, `*.pem`, `*.key`, `credentials.json`, `token.json`
- **IDE config**: `.idea/`, `.vscode/`, `*.iml`
- **OS junk**: `.DS_Store`, `Thumbs.db`
- **Build artifacts**: `node_modules/`, `__pycache__/`, `dist/`, `build/`

If any are found, they are unstaged and a warning is printed. Add them to `.gitignore` to suppress future warnings.

### PR Creation Details

When `--pr` is used (or `create_pr.sh` is called directly), the script:

1. Verifies `gh` CLI is installed and authenticated
2. Checks you're not on the default branch
3. Detects if a PR already exists for the branch (opens it instead of creating a duplicate)
4. Uses a temp file for the PR body to avoid shell newline issues
5. Creates the PR via `gh pr create`
6. Opens the PR in the browser

You can also call the PR script standalone (e.g., when changes are already pushed):

```bash
bash ~/.cursor/skills/git-commit-push/scripts/create_pr.sh --title "feat: add login" --body "## Summary\nAdded login flow" --label "enhancement"
```

| Flag | Effect |
|------|--------|
| `--title <text>` | PR title (defaults to last commit message) |
| `--body <text>` | PR body (supports `\n` for newlines) |
| `--label <labels>` | Comma-separated labels |
| `--no-browser` | Skip opening the PR in the browser |

### Important Notes

- If push fails (auth, conflicts), the script will report the error — address it and re-run.
- If SSH push fails (`Connection reset`, `Permission denied`), switch the remote to HTTPS:
  ```bash
  git remote set-url origin https://github.com/<owner>/<repo>.git
  ```
  Then re-run the push: `git push -u origin $(git rev-parse --abbrev-ref HEAD)`
