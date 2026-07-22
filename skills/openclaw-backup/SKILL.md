---
name: openclaw-backup
description: "Back up and restore the OpenClaw state directory (config, workspace, sessions, skills) to a Tigris bucket. Scheduled backups, safe SQLite handling, point-in-time rollback via bucket snapshots, and zero-copy clones via forks. Use when the user wants their assistant's state to survive machine loss, move to a new machine, or roll back to before a bad update."
---

# Tigris Backup for OpenClaw

Back up `~/.openclaw` (or `$OPENCLAW_STATE_DIR`) to a Tigris bucket, restore
it on any machine, and roll the whole state back to a point in time with
bucket snapshots. Solves the "my assistant's state should survive this box"
problem: machine loss, Gateway-update regressions, and moving between
machines.

## What gets backed up

Everything in the state directory: `openclaw.json`, workspace files, skills,
credentials, and session history. SQLite databases are backed up with
`sqlite3 .backup` (a consistent copy), never by copying live database files —
copying a live SQLite file produces corrupt backups.

## Requirements

- `rclone` and `sqlite3` on PATH
- A Tigris bucket and access key
  ([create one](https://www.tigrisdata.com/docs/iam/manage-access-key/))
- Optional, for snapshots/forks: the
  [`tigris` CLI](https://www.tigrisdata.com/docs/cli/) and a
  snapshot-enabled bucket

## Setup

Add a Tigris remote to `~/.config/rclone/rclone.conf`:

```ini
[tigris]
type = s3
provider = Other
access_key_id = tid_YOUR_ACCESS_KEY
secret_access_key = tsec_YOUR_SECRET_KEY
endpoint = https://t3.storage.dev
force_path_style = false
```

`force_path_style = false` matters: Tigris uses virtual-hosted-style
addressing.

Set the target bucket:

```bash
export TIGRIS_BACKUP_BUCKET=my-openclaw-backup
```

## Back up

```bash
scripts/backup.sh
```

The script stages a consistent copy (SQLite via `.backup`, everything else
via rsync), syncs it to `tigris:$TIGRIS_BACKUP_BUCKET/openclaw-state/`, and —
if the `tigris` CLI is available and the bucket is snapshot-enabled — takes a
named bucket snapshot so every backup run is a restorable point in time.

Schedule it with OpenClaw's own cron
([docs](https://docs.openclaw.ai/automation/cron-jobs)) or system cron. Daily
is a sensible default; the sync is incremental, so unchanged files cost
nothing to re-run.

## Restore

On a fresh machine (or after wiping state), with rclone configured the same
way:

```bash
scripts/restore.sh          # dry-run: shows what would change
scripts/restore.sh --yes    # actually restores
```

Stop the Gateway before restoring. The script refuses to run over a live
state directory unless forced.

## Roll back to before a bad update

If backups run on a snapshot-enabled bucket, every run is a point in time:

```bash
tigris snapshots list my-openclaw-backup
tigris mk my-openclaw-restore --fork-of my-openclaw-backup --source-snapshot <version>
```

Then restore from the fork
(`TIGRIS_BACKUP_BUCKET=my-openclaw-restore scripts/restore.sh --yes`). The
original backup bucket is never touched during a rollback.

## Clone your assistant

Forks are zero-copy, so the same mechanism gives you a disposable twin: fork
the backup bucket, restore the fork onto a second machine, and experiment
with config, skills, or a Gateway upgrade against your assistant's real
accumulated state — while the original keeps running untouched.

## Safety rules for agents

- Never run `restore.sh --yes` without the user explicitly confirming they
  want the local state replaced.
- Never back up while a restore is in progress, or vice versa.
- Do not add `--delete`-style flags to the backup sync; removing remote data
  requires the user to do it deliberately.
- Credentials in `rclone.conf` and the state directory are secrets; never
  print them.
