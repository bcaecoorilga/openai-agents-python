#!/usr/bin/env bash
# Changelog Generator Script
# Generates a changelog from git commits between two refs or since the last tag.
# Usage: ./run.sh [--from <ref>] [--to <ref>] [--output <file>]

set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
FROM_REF=""
TO_REF="HEAD"
OUTPUT_FILE="CHANGELOG_DRAFT.md"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '.')"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)
      FROM_REF="$2"
      shift 2
      ;;
    --to)
      TO_REF="$2"
      shift 2
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--from <ref>] [--to <ref>] [--output <file>]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolve FROM_REF to the latest tag if not supplied
# ---------------------------------------------------------------------------
if [[ -z "$FROM_REF" ]]; then
  FROM_REF="$(git describe --tags --abbrev=0 2>/dev/null || echo '')" 
  if [[ -z "$FROM_REF" ]]; then
    echo "No tags found and --from not specified; using first commit as base."
    FROM_REF="$(git rev-list --max-parents=0 HEAD)"
  fi
fi

echo "Generating changelog from '${FROM_REF}' to '${TO_REF}'..."

# ---------------------------------------------------------------------------
# Collect commits in the range
# ---------------------------------------------------------------------------
GIT_LOG_FORMAT="%H|||%s|||%an|||%ad"
GIT_LOG_ARGS=("--date=short" "--no-merges" "--format=${GIT_LOG_FORMAT}")

if [[ "$FROM_REF" == "$TO_REF" ]]; then
  echo "FROM_REF and TO_REF are identical; nothing to generate." >&2
  exit 0
fi

COMMITS="$(git log "${FROM_REF}..${TO_REF}" "${GIT_LOG_ARGS[@]}")"

if [[ -z "$COMMITS" ]]; then
  echo "No commits found in range ${FROM_REF}..${TO_REF}." >&2
  exit 0
fi

# ---------------------------------------------------------------------------
# Categorise commits by Conventional Commit prefix
# ---------------------------------------------------------------------------
declare -a FEAT_LINES BUG_LINES PERF_LINES REFACTOR_LINES DOCS_LINES CHORE_LINES OTHER_LINES

while IFS='|||' read -r hash subject author date; do
  short_hash="${hash:0:7}"
  entry="- ${subject} (${short_hash}, ${author}, ${date})"

  case "$subject" in
    feat:*|feat\(*)
      FEAT_LINES+=("$entry") ;;
    fix:*|fix\(*)
      BUG_LINES+=("$entry") ;;
    perf:*|perf\(*)
      PERF_LINES+=("$entry") ;;
    refactor:*|refactor\(*)
      REFACTOR_LINES+=("$entry") ;;
    docs:*|docs\(*)
      DOCS_LINES+=("$entry") ;;
    chore:*|chore:*|ci:*|build:*|test:*)
      CHORE_LINES+=("$entry") ;;
    *)
      OTHER_LINES+=("$entry") ;;
  esac
done <<< "$COMMITS"

# ---------------------------------------------------------------------------
# Write the changelog draft
# ---------------------------------------------------------------------------
OUTPUT_PATH="${REPO_ROOT}/${OUTPUT_FILE}"
TODAY="$(date +%Y-%m-%d)"

{
  echo "# Changelog"
  echo ""
  echo "## [Unreleased] — ${TODAY}"
  echo ""
  echo "> Range: \`${FROM_REF}\` → \`${TO_REF}\`"
  echo ""

  write_section() {
    local title="$1"
    shift
    local lines=("$@")
    if [[ ${#lines[@]} -gt 0 ]]; then
      echo "### ${title}"
      echo ""
      for line in "${lines[@]}"; do
        echo "$line"
      done
      echo ""
    fi
  }

  write_section "🚀 Features"      "${FEAT_LINES[@]+${FEAT_LINES[@]}}"
  write_section "🐛 Bug Fixes"     "${BUG_LINES[@]+${BUG_LINES[@]}}"
  write_section "⚡ Performance"   "${PERF_LINES[@]+${PERF_LINES[@]}}"
  write_section "♻️  Refactoring"  "${REFACTOR_LINES[@]+${REFACTOR_LINES[@]}}"
  write_section "📝 Documentation" "${DOCS_LINES[@]+${DOCS_LINES[@]}}"
  write_section "🔧 Chores / CI"   "${CHORE_LINES[@]+${CHORE_LINES[@]}}"
  write_section "📦 Other"         "${OTHER_LINES[@]+${OTHER_LINES[@]}}"

} > "$OUTPUT_PATH"

echo "Changelog draft written to: ${OUTPUT_PATH}"
