# PR Review Skill

This skill enables automated pull request review capabilities, providing structured feedback on code changes, documentation, test coverage, and adherence to project conventions.

## Overview

The PR Review skill analyzes pull requests and generates comprehensive review comments covering:

- **Code quality**: Style, readability, and maintainability concerns
- **Logic correctness**: Potential bugs, edge cases, and error handling
- **Test coverage**: Missing or insufficient tests for changed code
- **Documentation**: Missing or outdated docstrings, comments, and README updates
- **Security**: Common vulnerability patterns and unsafe practices
- **Performance**: Obvious inefficiencies or anti-patterns

## Usage

This skill is triggered automatically on pull request creation or update events, or can be invoked manually via the agent interface.

### Inputs

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pr_number` | integer | Yes | The pull request number to review |
| `repo` | string | No | Repository in `owner/name` format (defaults to current repo) |
| `focus_areas` | list | No | Specific areas to focus on (e.g., `["security", "tests"]`) |
| `severity_threshold` | string | No | Minimum severity to report: `info`, `warning`, `error` (default: `warning`) |

### Outputs

The skill produces a structured review with:
- Summary of changes reviewed
- Categorized findings with file/line references
- Suggested fixes where applicable
- Overall recommendation: `approve`, `request_changes`, or `comment`

## Configuration

Skill behavior can be customized via `.agents/skills/pr-review/config.yaml`:

```yaml
review:
  max_files: 50          # Skip review if PR touches more than N files
  max_diff_lines: 2000   # Skip review if diff exceeds N lines
  auto_approve: false    # Never auto-approve, only suggest
  post_inline_comments: true
  post_summary_comment: true
```

## Agent Integration

See `agents/openai.yaml` for the OpenAI Agents SDK configuration used to power this skill.

## Scripts

- `scripts/run.sh` — Main entrypoint for Linux/macOS CI environments
- `scripts/run.ps1` — Main entrypoint for Windows CI environments

## Examples

### Manual invocation

```bash
bash .agents/skills/pr-review/scripts/run.sh --pr 42 --focus security,tests
```

### GitHub Actions

```yaml
- name: PR Review
  uses: ./.agents/skills/pr-review
  with:
    pr_number: ${{ github.event.pull_request.number }}
    severity_threshold: warning
```
