---
name: auto-merge-conflicts
description: Resolve git merge conflicts non-interactively, validate build and tests, and finalize resolution. Use when a branch has unresolved merge conflicts, when the user mentions conflict markers, merge failures, or asks to fix conflicts after a merge, rebase, or cherry-pick.
---

# Auto Merge Conflicts

## Workflow

### 1. Survey conflicts

```bash
git diff --name-only --diff-filter=U
```

Read each conflicting file and note every `<<<<<<<` / `=======` / `>>>>>>>` block.

### 2. Resolve each file

For every conflict hunk, apply these rules in order:

| Priority | Strategy | When to use |
|----------|----------|-------------|
| 1 | Keep both sides | Changes are additive and independent (e.g. two new imports, two new list items) |
| 2 | Prefer the incoming change | Incoming side is a strict superset or a clear bug-fix |
| 3 | Prefer the current change | Incoming side removes behavior the current branch intentionally added |
| 4 | Manual merge | Overlapping edits to the same logic — combine carefully |

After editing, verify **zero** conflict markers remain:

```bash
rg '<<<<<<<|=======|>>>>>>>' <file>
```

### 3. Handle lockfiles

Never hand-edit lockfiles. Instead:

| Lockfile | Recovery command |
|----------|----------------|
| `package-lock.json` | `npm install` |
| `yarn.lock` | `yarn install` |
| `pnpm-lock.yaml` | `pnpm install` |
| `Pipfile.lock` | `pipenv lock` |
| `poetry.lock` | `poetry lock --no-update` |
| `Gemfile.lock` | `bundle install` |
| `Cargo.lock` | `cargo generate-lockfile` |

Accept the **current** version of the lockfile first (`git checkout --ours <lockfile>`), then regenerate.

### 4. Validate

Run the project's compile, lint, and test steps. At minimum:

```bash
# Detect available tooling and run what exists
# Examples:
#   npm run build && npm run lint && npm test
#   cargo build && cargo clippy && cargo test
#   go build ./... && go vet ./... && go test ./...
```

If a step fails, fix the root cause in the conflicting files — do not introduce unrelated changes.

### 5. Finalize

```bash
git add <resolved files>
```

Do **not** commit, push, or tag. Leave the final commit to the user (or to the git-commit-push skill if requested).

## Guardrails

- Keep edits minimal — resolve the conflict, nothing more.
- No conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) may remain in any tracked file.
- No broad refactors during resolution.
- No force-push, no tagging.
- If a resolution choice is ambiguous, explain the trade-off and ask the user before proceeding.

## Output

Summarize at the end:

1. **Files resolved** — list each file and the strategy used.
2. **Notable decisions** — any non-trivial choices or trade-offs.
3. **Build / test outcome** — pass/fail status of compile, lint, and tests.
