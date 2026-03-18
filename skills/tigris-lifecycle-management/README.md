# tigris-lifecycle-management

Automate object expiration, storage tier transitions, and cleanup with lifecycle rules.

## What It Covers

- **Lifecycle rules** — JSON format, CLI commands, prefix filtering
- **Common patterns** — temp cleanup, log archival, backup retention, session TTL
- **Storage tiers** — STANDARD, STANDARD_IA, GLACIER and when to use each
- **Cost modeling** — when transitions save money vs deletion
- **Application-level TTL** — metadata-based expiration for complex cases
- **Snapshot interaction** — how lifecycle rules work with snapshots

## Installation

**Claude Code:**

```bash
cp -r skills/tigris-lifecycle-management ~/.claude/skills/
```

**claude.ai:**

Add `skills/tigris-lifecycle-management` to project knowledge or paste `SKILL.md` contents into the conversation.

## Usage

This skill activates when you mention:

- "Lifecycle rules", "auto-delete", "expiration"
- "TTL", "storage tiers", "archive"
- "Cleanup old files", "object expiration"

## Example Prompts

```text
Set up auto-deletion for temporary uploads after 24 hours
```

```text
Archive old logs to cheaper storage tiers
```

```text
Configure backup retention policy on my Tigris bucket
```

## License

MIT
