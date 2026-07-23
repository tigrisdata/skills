# openclaw-backup

Back up and restore your OpenClaw assistant's state to a Tigris bucket — and
roll the whole assistant back to a point in time.

## What It Covers

- **Consistent backups** — SQLite via the backup API (never raw copies of
  live databases), WAL/journal files excluded
- **Restore anywhere** — dry-run by default, pre-restore safety copy,
  refuses to run over a live Gateway
- **Point-in-time rollback** — every backup takes a bucket snapshot; restore
  the state from before a bad update via a fork
- **Clone your assistant** — fork the backup bucket and restore it onto a
  second machine, zero-copy
- **Scheduling** — OpenClaw cron or system cron; incremental sync

## Requirements

`rclone` and `sqlite3` on PATH; optionally the `tigris` CLI for snapshots
and forks. A Tigris bucket and access key:
https://www.tigrisdata.com/docs/iam/manage-access-key/

## Installation

**OpenClaw (ClawHub):**

```bash
openclaw skills install @tigrisdata/openclaw-backup
```

**Manual:**

```bash
cp -r skills/openclaw-backup ~/.openclaw/skills/
```

## Usage

See [SKILL.md](SKILL.md) for setup (rclone remote), backup and restore
commands, rollback via snapshots, and the safety rules.
