# Changelog Generator Skill

Automatically generates and updates the CHANGELOG.md file based on merged pull requests, commit history, and semantic versioning conventions.

## Overview

This skill analyzes git history and pull request metadata to produce well-structured changelog entries following the [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format. It groups changes by type (Added, Changed, Deprecated, Removed, Fixed, Security) and organizes them under appropriate version headings.

## Trigger Conditions

This skill should be invoked when:
- A new release tag is created (e.g., `v*.*.*`)
- A pull request targeting `main` is merged with the label `changelog`
- Manually triggered via workflow dispatch
- A milestone is closed

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `version` | The version string for the new changelog entry | Yes | — |
| `from_ref` | Git ref (tag/commit/branch) to start changelog from | No | Previous tag |
| `to_ref` | Git ref to end changelog at | No | `HEAD` |
| `include_prs` | Whether to include PR titles and numbers | No | `true` |
| `dry_run` | Print output without writing to file | No | `false` |

## Outputs

- Updated `CHANGELOG.md` with new version section prepended
- Summary comment posted to the triggering PR or release (if applicable)

## Behavior

### Change Classification

Commits and PRs are classified using conventional commit prefixes and labels:

| Prefix / Label | Changelog Section |
|----------------|-------------------|
| `feat:`, `feature` label | Added |
| `fix:`, `bugfix` label | Fixed |
| `refactor:`, `perf:` | Changed |
| `deprecate:` | Deprecated |
| `remove:` | Removed |
| `security:`, `security` label | Security |
| `docs:` | (omitted by default) |
| `chore:`, `ci:`, `test:` | (omitted by default) |

### Version Handling

- Validates that the provided version follows SemVer (`MAJOR.MINOR.PATCH`)
- Checks that the new version is greater than the most recent version in `CHANGELOG.md`
- Adds release date automatically using UTC timestamp

### Duplicate Prevention

- Skips commits that are already captured in an existing changelog entry
- De-duplicates entries that appear in both commit log and PR titles

## Example Output

```markdown
## [1.4.0] - 2025-06-15

### Added
- Support for streaming tool call responses (#312)
- New `max_turns` parameter on `Runner.run()` (#298)

### Fixed
- Correctly handle empty tool output in tracing (#321)
- Prevent duplicate lifecycle hooks on agent handoff (#315)

### Changed
- Improved error messages for invalid model names (#308)
```

## Files

- `SKILL.md` — This document
- `agents/openai.yaml` — Agent model configuration
- `scripts/run.sh` — Main execution script
