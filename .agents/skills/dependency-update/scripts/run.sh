#!/usr/bin/env bash
# Dependency Update Skill - run.sh
# Scans for outdated dependencies and creates a PR with updates.
# Supports Python projects using pip/poetry/uv.

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
REPO_ROOT="$(git rev-parse --show-toplevel)"
BRANCH_PREFIX="chore/dependency-update"
DATE_STAMP="$(date +%Y%m%d)"
UPDATE_BRANCH="${BRANCH_PREFIX}-${DATE_STAMP}"
COMMIT_MSG="chore: update dependencies (${DATE_STAMP})"
PR_TITLE="chore: Automated dependency updates ${DATE_STAMP}"
PR_BODY_FILE="$(mktemp /tmp/pr_body_XXXXXX.md)"

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[dep-update]${NC} $*"; }
warn() { echo -e "${YELLOW}[dep-update]${NC} $*"; }
err()  { echo -e "${RED}[dep-update]${NC} $*" >&2; }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
require() {
  command -v "$1" &>/dev/null || { err "Required tool not found: $1"; exit 1; }
}

detect_package_manager() {
  if [[ -f "${REPO_ROOT}/pyproject.toml" ]] && grep -q '\[tool.poetry\]' "${REPO_ROOT}/pyproject.toml" 2>/dev/null; then
    echo "poetry"
  elif [[ -f "${REPO_ROOT}/uv.lock" ]] || grep -q '\[tool.uv\]' "${REPO_ROOT}/pyproject.toml" 2>/dev/null; then
    echo "uv"
  elif [[ -f "${REPO_ROOT}/requirements.txt" ]]; then
    echo "pip"
  else
    echo "unknown"
  fi
}

# ---------------------------------------------------------------------------
# Update functions
# ---------------------------------------------------------------------------
update_with_poetry() {
  log "Using Poetry to update dependencies..."
  require poetry
  poetry update --no-interaction 2>&1 | tee /tmp/poetry_update.log
  CHANGED_FILES=("pyproject.toml" "poetry.lock")
}

update_with_uv() {
  log "Using uv to update dependencies..."
  require uv
  uv lock --upgrade 2>&1 | tee /tmp/uv_update.log
  CHANGED_FILES=("uv.lock")
  [[ -f "${REPO_ROOT}/pyproject.toml" ]] && CHANGED_FILES+=("pyproject.toml")
}

update_with_pip() {
  log "Using pip-compile to update dependencies..."
  require pip-compile
  pip-compile --upgrade requirements.in -o requirements.txt 2>&1 | tee /tmp/pip_update.log
  CHANGED_FILES=("requirements.txt")
}

# ---------------------------------------------------------------------------
# PR body generation
# ---------------------------------------------------------------------------
build_pr_body() {
  local pm="$1"
  cat > "${PR_BODY_FILE}" <<EOF
## Automated Dependency Update

**Date:** ${DATE_STAMP}  
**Package manager:** ${pm}

### What changed

This PR was created automatically by the dependency-update skill.
The following files were modified:

\`\`\`
$(git diff --name-only HEAD 2>/dev/null || echo "(no diff available)")
\`\`\`

### Checklist
- [ ] CI passes
- [ ] No breaking changes introduced
- [ ] Changelog updated if required

> _Auto-generated — do not edit manually._
EOF
  log "PR body written to ${PR_BODY_FILE}"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  require git

  cd "${REPO_ROOT}"

  # Ensure we are on a clean base
  if [[ -n "$(git status --porcelain)" ]]; then
    err "Working directory is not clean. Commit or stash changes before running."
    exit 1
  fi

  local pm
  pm="$(detect_package_manager)"
  log "Detected package manager: ${pm}"

  # Create update branch
  git checkout -b "${UPDATE_BRANCH}" 2>/dev/null || git checkout "${UPDATE_BRANCH}"

  # Run the appropriate updater
  case "${pm}" in
    poetry) update_with_poetry ;;
    uv)     update_with_uv     ;;
    pip)    update_with_pip    ;;
    *)
      err "Could not detect a supported package manager (poetry / uv / pip)."
      exit 1
      ;;
  esac

  # Check whether anything actually changed
  if git diff --quiet HEAD; then
    log "All dependencies are already up-to-date. Nothing to commit."
    git checkout - && git branch -D "${UPDATE_BRANCH}" 2>/dev/null || true
    exit 0
  fi

  # Commit changes
  git add -A
  git commit -m "${COMMIT_MSG}"
  log "Committed dependency updates."

  # Push branch
  git push --set-upstream origin "${UPDATE_BRANCH}" --force-with-lease
  log "Pushed branch: ${UPDATE_BRANCH}"

  # Open PR (requires gh CLI)
  if command -v gh &>/dev/null; then
    build_pr_body "${pm}"
    gh pr create \
      --title "${PR_TITLE}" \
      --body-file "${PR_BODY_FILE}" \
      --base main \
      --head "${UPDATE_BRANCH}" \
      --label "dependencies" || warn "PR may already exist; skipping creation."
    log "Pull request created/updated."
  else
    warn "'gh' CLI not found — skipping automatic PR creation."
    warn "Push complete. Open a PR manually from branch: ${UPDATE_BRANCH}"
  fi

  # Clean up temp files
  rm -f "${PR_BODY_FILE}"
  log "Done."
}

main "$@"
