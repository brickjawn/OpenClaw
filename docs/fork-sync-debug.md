# Fork sync and “missing stuff” debugging

Use this when one clone (e.g. desktop) is missing files or commits that you expect from the GitHub repo.

## 1. Confirm what’s on GitHub

On any machine that can push to your fork:

```bash
git fetch origin
git log origin/main --oneline -3
git ls-tree -r origin/main --name-only | grep -E '\.cursor/rules|project-diary|ci\.yml'
```

- **Your fork** (`brickjawn/OpenClaw`) **main** should include:
  - `.cursor/rules/*.mdc` (personas)
  - `docs/project-diary.md`
  - `.github/workflows/ci.yml` (with `dependency-review` and Codecov)

If those paths exist on `origin/main`, GitHub has your customizations.

## 2. On the machine that’s “missing stuff” (e.g. desktop)

Run:

```bash
cd /path/to/openclaw
git remote -v
git branch -vv
git fetch origin
git status
git log origin/main --oneline -3
```

Check:

| Issue | What to check | Fix |
|-------|----------------|-----|
| Wrong remote | `origin` points to `openclaw/openclaw` or another org | `git remote set-url origin https://github.com/brickjawn/OpenClaw.git` then `git fetch origin` |
| Wrong branch | Current branch isn’t `main` or isn’t tracking `origin/main` | `git checkout main` then `git branch --set-upstream-to=origin/main` |
| Stale refs | `git log origin/main` doesn’t show your merge/custom commits | `git fetch origin` (and ensure you’re not on a branch that was reset) |
| Local main behind | `git status` says “Your branch is behind ‘origin/main’” | `git pull origin main` (or `git pull --rebase origin main`) |

## 3. After fixing remote/branch

```bash
git pull origin main
ls .cursor/rules/
ls docs/project-diary.md
grep -l dependency-review .github/workflows/ci.yml
```

If those exist, the clone is in sync with your fork.

## 4. Keeping fork in sync with upstream (optional)

If you added an `upstream` remote pointing at `openclaw/openclaw` and merged `upstream/main` into your fork, your fork’s **main** is ahead of upstream and still has your files (merge keeps your tree). To update from upstream again later:

```bash
git fetch upstream
git checkout main
git merge upstream/main
# resolve conflicts if any, then:
git push origin main
```

Always push to **origin** (brickjawn/OpenClaw) so your other clones get your customizations when they `git pull origin main`.

## Quick reference

- **Your fork (source of truth for your customizations):** `https://github.com/brickjawn/OpenClaw`
- **Branch to pull:** `main`
- **Customizations to expect:** `.cursor/rules/`, `docs/project-diary.md`, CI dependency-review + Codecov in `.github/workflows/ci.yml`
