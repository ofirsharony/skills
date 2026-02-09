---
name: git-commit-push
description: Stage, commit, and push git changes with conventional commit messages. Use when user wants to commit and push changes, mentions pushing to remote, or asks to save and push their work. Also activates when user says "push changes", "commit and push", "push this", "push to github", or similar git workflow requests.
---

# Git Commit & Push Workflow

Stage all changes, create a conventional commit, and push to the remote branch.

## When to Use

Activate when the user:

- Asks to push changes ("push this", "commit and push")
- Mentions saving work to remote ("save to github", "push to remote")
- Completes a feature and wants to share it
- Says phrases like "let's push this up" or "commit these changes"

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

## Workflow

**ALWAYS use the script** — do NOT run manual git commands:

```bash
bash ~/.cursor/skills/git-commit-push/scripts/smart_commit.sh
```

With a custom message:

```bash
bash ~/.cursor/skills/git-commit-push/scripts/smart_commit.sh "feat: add user authentication"
```

### What the Script Does

1. Checks there are actually changes to commit
2. Stages all changes (`git add .`)
3. Commits with the provided message (defaults to `chore: update code`)
4. Pushes to the current branch with `-u` flag

### Conventional Commit Prefixes

When choosing a message, use:

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

### Important Notes

- The script stages **all** changes. If you need selective staging, do it manually before running the script with `--no-stage` flag.
- If push fails (auth, conflicts), the script will report the error — address it and re-run.
- If SSH push fails (`Connection reset`, `Permission denied`), switch the remote to HTTPS:
  ```bash
  git remote set-url origin https://github.com/<owner>/<repo>.git
  ```
  Then re-run the push: `git push -u origin $(git rev-parse --abbrev-ref HEAD)`
