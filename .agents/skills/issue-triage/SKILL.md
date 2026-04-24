# Issue Triage Skill

This skill automatically triages new GitHub issues by analyzing their content, applying appropriate labels, assigning priority levels, and providing an initial response to the issue author.

## What It Does

1. **Analyzes issue content** — Reads the issue title, body, and any attached code snippets or logs
2. **Classifies the issue type** — Bug report, feature request, question, documentation gap, or performance issue
3. **Applies labels** — Adds relevant labels based on classification (e.g., `bug`, `enhancement`, `question`, `docs`, `performance`)
4. **Assigns priority** — Determines priority (P0–P3) based on severity indicators in the issue
5. **Posts an initial response** — Acknowledges the issue and asks clarifying questions if needed
6. **Links related issues** — Searches for duplicate or related issues and surfaces them

## Triggers

- A new issue is opened in the repository
- An issue is reopened after being closed
- Manual trigger via workflow dispatch with an issue number

## Inputs

| Input | Description | Required |
|-------|-------------|----------|
| `issue_number` | The GitHub issue number to triage | Yes |
| `repo` | Repository in `owner/repo` format | Yes |
| `github_token` | GitHub token with issues read/write permission | Yes |

## Outputs

| Output | Description |
|--------|-------------|
| `labels_applied` | Comma-separated list of labels that were applied |
| `priority` | Assigned priority level (P0, P1, P2, P3) |
| `issue_type` | Classified issue type |
| `response_posted` | Whether an initial response was posted (`true`/`false`) |

## Priority Levels

- **P0** — Critical: data loss, security vulnerability, complete service outage
- **P1** — High: major feature broken, significant performance regression
- **P2** — Medium: minor feature broken, workaround available
- **P3** — Low: cosmetic issue, minor inconvenience, documentation improvement

## Label Taxonomy

The skill applies labels from the following categories:

- **Type**: `bug`, `enhancement`, `question`, `documentation`, `performance`
- **Priority**: `priority:P0`, `priority:P1`, `priority:P2`, `priority:P3`
- **Status**: `needs-info`, `needs-reproduction`, `good-first-issue`
- **Component**: `agents`, `tools`, `tracing`, `guardrails`, `examples`

## Configuration

The skill reads optional configuration from `.agents/skills/issue-triage/config.yaml` if present, allowing customization of label names, response templates, and classification thresholds.

## Notes

- The skill will not overwrite labels that were manually applied before the triage ran
- If the issue is from a first-time contributor, it adds a welcome message
- Security-related issues (P0) trigger an immediate notification to maintainers
