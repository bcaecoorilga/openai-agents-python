# Dependency Update Skill

This skill automates the process of checking for outdated dependencies, evaluating compatibility, and proposing or applying updates to the project's dependency files.

## Overview

The dependency update skill performs the following tasks:
1. Scans dependency files (`pyproject.toml`, `requirements*.txt`) for outdated packages
2. Checks for known security vulnerabilities in current dependencies
3. Evaluates breaking changes between current and latest versions
4. Generates a structured update plan with risk assessment
5. Opens a pull request with the proposed dependency updates

## Inputs

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `update_mode` | string | No | One of `patch`, `minor`, `major`, `security-only`. Defaults to `minor`. |
| `dry_run` | boolean | No | If `true`, only reports what would be updated without making changes. Defaults to `false`. |
| `packages` | string[] | No | Specific package names to update. If omitted, all outdated packages are considered. |
| `exclude_packages` | string[] | No | Packages to skip during update evaluation. |
| `create_pr` | boolean | No | If `true`, opens a pull request with the changes. Defaults to `true`. |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `updated_packages` | object[] | List of packages that were updated, with old and new versions. |
| `skipped_packages` | object[] | Packages that were skipped and the reason why. |
| `vulnerabilities_found` | object[] | Any security vulnerabilities detected in current or updated dependencies. |
| `pr_url` | string | URL of the created pull request, if `create_pr` is `true`. |

## Behavior

### Update Modes

- **`patch`**: Only updates patch-level versions (e.g., `1.2.3` → `1.2.4`). Lowest risk.
- **`minor`**: Updates minor and patch versions (e.g., `1.2.3` → `1.3.0`). Moderate risk.
- **`major`**: Updates all versions including major bumps. Highest risk; changelog review recommended.
- **`security-only`**: Only updates packages with known CVEs, regardless of version bump level.

### Risk Assessment

Each proposed update is tagged with a risk level:
- 🟢 **Low**: Patch version bump, no API changes expected.
- 🟡 **Medium**: Minor version bump, additive changes possible.
- 🔴 **High**: Major version bump or package with known breaking changes.

### Pull Request Format

When `create_pr` is enabled, the PR will include:
- A summary table of all updated packages
- Links to changelogs or release notes for each package
- Results from the test suite run post-update
- Vulnerability report if any issues were found

## Example Usage

```yaml
skill: dependency-update
with:
  update_mode: minor
  exclude_packages:
    - numpy
    - torch
  create_pr: true
```

## Notes

- This skill requires `pip-audit` and `pip-outdated` (or equivalent) to be available in the environment.
- When running in CI, ensure the workflow has write permissions to create branches and pull requests.
- It is recommended to run this skill on a weekly schedule via a cron trigger.
