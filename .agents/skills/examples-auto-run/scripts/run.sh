#!/usr/bin/env bash
# examples-auto-run/scripts/run.sh
# Automatically discovers and runs all examples in the repository,
# capturing output and reporting pass/fail status for each.

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
EXAMPLES_DIR="${REPO_ROOT}/examples"
LOG_DIR="${REPO_ROOT}/.agents/skills/examples-auto-run/logs"
TIMEOUT_SECONDS=${TIMEOUT_SECONDS:-60}
PYTHON=${PYTHON:-python}
PASSED=0
FAILED=0
SKIPPED=0
FAILED_EXAMPLES=()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { echo "[examples-auto-run] $*"; }
info() { log "INFO  $*"; }
warn() { log "WARN  $*"; }
err()  { log "ERROR $*" >&2; }

require_command() {
  if ! command -v "$1" &>/dev/null; then
    err "Required command not found: $1"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
require_command "$PYTHON"
require_command "timeout"

mkdir -p "$LOG_DIR"

if [[ ! -d "$EXAMPLES_DIR" ]]; then
  err "Examples directory not found: $EXAMPLES_DIR"
  exit 1
fi

# ---------------------------------------------------------------------------
# Collect example files
# ---------------------------------------------------------------------------
# An example is any *.py file directly under examples/ or one level deep.
# Files prefixed with '_' or named 'conftest.py' are skipped.
mapfile -t EXAMPLE_FILES < <(
  find "$EXAMPLES_DIR" -maxdepth 2 -name '*.py' \
    ! -name '_*' \
    ! -name 'conftest.py' \
    | sort
)

if [[ ${#EXAMPLE_FILES[@]} -eq 0 ]]; then
  warn "No example files found under $EXAMPLES_DIR"
  exit 0
fi

info "Found ${#EXAMPLE_FILES[@]} example file(s) to run."
info "Logs will be written to: $LOG_DIR"
echo ""

# ---------------------------------------------------------------------------
# Run each example
# ---------------------------------------------------------------------------
for example in "${EXAMPLE_FILES[@]}"; do
  rel="${example#"$REPO_ROOT/"}"
  safe_name="$(echo "$rel" | tr '/' '__' | tr ' ' '_')"
  log_file="${LOG_DIR}/${safe_name%.py}.log"

  # Check for an optional skip marker inside the file
  if grep -q 'SKIP_AUTO_RUN' "$example" 2>/dev/null; then
    warn "SKIP  $rel  (SKIP_AUTO_RUN marker found)"
    (( SKIPPED++ )) || true
    continue
  fi

  info "RUN   $rel"

  # Run with a timeout; capture combined stdout+stderr
  set +e
  timeout "$TIMEOUT_SECONDS" \
    "$PYTHON" "$example" \
    > "$log_file" 2>&1
  exit_code=$?
  set -e

  if [[ $exit_code -eq 0 ]]; then
    info "PASS  $rel"
    (( PASSED++ )) || true
  elif [[ $exit_code -eq 124 ]]; then
    err  "TIMEOUT $rel  (exceeded ${TIMEOUT_SECONDS}s)"
    echo "[TIMEOUT after ${TIMEOUT_SECONDS}s]" >> "$log_file"
    FAILED_EXAMPLES+=("$rel (timeout)")
    (( FAILED++ )) || true
  else
    err  "FAIL  $rel  (exit code $exit_code)"
    FAILED_EXAMPLES+=("$rel (exit $exit_code)")
    (( FAILED++ )) || true
    # Print last 20 lines of output to help with debugging
    tail -n 20 "$log_file" | sed 's/^/    /' >&2
  fi
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
info "==============================="
info "Results: PASSED=$PASSED  FAILED=$FAILED  SKIPPED=$SKIPPED"
info "==============================="

if [[ $FAILED -gt 0 ]]; then
  err "The following examples failed:"
  for f in "${FAILED_EXAMPLES[@]}"; do
    err "  - $f"
  done
  exit 1
fi

info "All examples passed."
exit 0
