# Test Results: tigris-backup skill (backup.sh / restore.sh)

Date: 2026-07-21 (UTC timestamps below from script output)
Bucket under test: `tigris:tigris-dlt-demo` — only the `openclaw-state/` prefix was
touched, and it was purged after testing.

## Environment

| Component  | Version / detail |
|------------|------------------|
| macOS      | 26.5.2 (build 25F84), Darwin 25.5.0, arm64 (Apple Silicon) |
| rclone     | v1.74.4 (official `rclone-current-osx-arm64.zip` binary; Homebrew was not installed on this machine, so brew was not usable) |
| sqlite3    | 3.51.0 (system) |
| rsync      | openrsync, protocol version 29 (macOS system rsync) |
| shellcheck | v0.11.0 (official darwin.aarch64 release binary) |
| tigris CLI | **not installed** (per instructions, not installed for the test) |

Environment deviations from the test premise:

- `TIGRIS_BACKUP_BUCKET` was **not** set in the environment and no rclone remote
  existed; the bucket name and credentials were supplied by the user mid-test.
- `~/.config/rclone/rclone.conf` does not exist on this machine and was **never
  created or modified**. A temporary config (mode 600, in the session scratchpad)
  was used via `RCLONE_CONFIG=...` for every rclone invocation, and deleted at
  cleanup. rclone and shellcheck were installed as standalone official release
  binaries in the session scratchpad (nothing installed system-wide).
- `~/.openclaw` was never touched; all state dirs were `/tmp/fake-*`.

## Step results

| # | Step | Result |
|---|------|--------|
| 1 | rclone / sqlite3 / rsync on PATH | **PASS** (rclone + shellcheck installed as noted above; sqlite3/rsync were system-provided) |
| 1 | `shellcheck scripts/*.sh` | **PASS** — zero findings on both scripts |
| 1 | `chmod +x scripts/*.sh` | **PASS** |
| 2 | Smoke backup of `/tmp/fake-openclaw` (openclaw.json, workspace/note.txt, workspace/nested/deep.txt, sessions.db with 3 rows, touched sessions.db-wal) | **PASS** — all files present under `openclaw-state/`, `sessions.db-wal` **absent** (WAL exclusion works), `.tigris-backup.json` present |
| 3 | `restore.sh` without `--yes` | **PASS** — dry run only; exit 0, listed 5 pending copies, target dir `/tmp/fake-restore` was **not created** and nothing was written to disk |
| 3 | `restore.sh --yes` round-trip | **PASS** — `diff -r` (excluding `-wal` and `.tigris-backup.json`) clean for all regular files; `sqlite3 sessions.db "PRAGMA integrity_check"` → `ok`; all 3 rows (alpha/beta/gamma) intact. Note: `sessions.db` is not byte-identical to the source (expected — `sqlite3 .backup` produces a consistent, logically identical copy, not a byte copy); `.dump` output of source and restored DB is identical |
| 4 | `restore.sh --yes` onto NON-empty target | **PASS** — existing dir moved aside to `/tmp/fake-restore.pre-restore.20260721T182147Z`, sentinel file preserved inside it, restored dir contained only backup contents |
| 4 | `backup.sh` with `TIGRIS_BACKUP_BUCKET` unset | **PASS** — exits 1 with the single clear message `TIGRIS_BACKUP_BUCKET: Set TIGRIS_BACKUP_BUCKET to your backup bucket name`, no stack trace (the check fires before the rclone check, so it works even without rclone installed) |
| 4 | Filename with a space (`file with space.txt`) and with a single quote (`dave's file.txt`) | **PASS** — both survived backup and restore with contents intact |
| 4 | `backup.sh` twice in a row | **PASS** — second (and third) runs succeeded; incremental sync, idempotent |
| 4 | Snapshot step | **SKIPPED GRACEFULLY** — tigris CLI not installed; backup.sh printed `note: tigris CLI not found; skipping bucket snapshot` and completed successfully. The snapshot code path itself was therefore not exercised |
| 5 | Script changes | **NONE** — no bugs found; zero modifications to either script. All safety behaviors observed working: dry-run default, no-delete sync (`rclone copy`, no `--delete`), WAL/journal exclusion, safety copy on restore. The live-process `pgrep -f openclaw` guard did not false-positive during testing but was not positively exercised (no live process was simulated, to keep the test non-invasive) |

## Script changes

None.

## Final `rclone ls tigris:tigris-dlt-demo` (before cleanup purge)

```
      96 openclaw-state/.tigris-backup.json
      29 openclaw-state/openclaw.json
    8192 openclaw-state/sessions.db
      14 openclaw-state/workspace/dave's file.txt
      14 openclaw-state/workspace/file with space.txt
      10 openclaw-state/workspace/nested/deep.txt
      16 openclaw-state/workspace/note.txt
```

## Cleanup performed

- `rclone purge tigris:tigris-dlt-demo/openclaw-state/` — that prefix only; the
  bucket itself, access key, and rclone config were left untouched
- Deleted `/tmp/fake-openclaw`, `/tmp/fake-restore`,
  `/tmp/fake-restore.pre-restore.*`
- Deleted the temporary scratchpad `rclone.conf` containing the credentials

**Security note:** the access key pair used for this test was pasted into the
chat in plaintext; rotating it afterwards is recommended (not done here — key
management was out of scope per the test rules).
