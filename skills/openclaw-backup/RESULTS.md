# Test Results: openclaw-backup skill (rewritten scripts, re-test from scratch)

Date: 2026-07-22 (UTC timestamps below from script output)
Bucket under test: `tigris:tigris-dlt-demo` (key `tigris-dlt-key`) — only the
`openclaw-state/` and script-created `archive/` prefixes were touched; both were
purged after testing.

## Environment

| Component  | Version / detail |
|------------|------------------|
| macOS      | 26.5.2 (build 25F84), Darwin 25.5.0, arm64 |
| rclone     | v1.74.4 (official standalone binary in session scratchpad; Homebrew not installed on this machine) |
| sqlite3    | 3.51.0 (system) |
| rsync      | openrsync, protocol version 29 (macOS system rsync) |
| shellcheck | v0.11.0 (official standalone binary) |
| tigris CLI | not installed (per instructions, not installed) |

Notes:

- `TIGRIS_BACKUP_BUCKET` was not set in the environment and no rclone remote
  existed; bucket name and credentials were supplied by the user mid-test.
  `~/.config/rclone/rclone.conf` does not exist and was never created or
  modified — a temporary mode-600 config in the session scratchpad was used via
  `RCLONE_CONFIG` and deleted at cleanup. `~/.openclaw` was never touched.
- The key initially had no bucket permissions (ListObjects/HeadObject 403);
  the user granted access mid-test, after which all cloud steps ran.

## Step results

| # | Step | Result |
|---|------|--------|
| 1 | rclone / sqlite3 / rsync available | **PASS** (rclone + shellcheck as standalone official binaries, nothing system-wide) |
| 1 | `shellcheck scripts/*.sh` | **PASS after 1 fix** (SC2086, see script changes; clean afterwards) |
| 1 | `chmod +x scripts/*.sh` | **PASS** |
| 2 | Smoke backup of `/tmp/fake-openclaw` | **PASS** — all files present under `openclaw-state/`; `sessions.db-wal` absent; `logs/gateway.log` absent (logs exclusion); symlink `link-to-note.txt` captured as a real file with target content (`--copy-links`); `.tigris-backup.json` present; lock released after run |
| 3 | `restore.sh` without `--yes` | **PASS** — dry run prints replace-semantics warning + `rclone size` summary; target dir not created, no staging dir, nothing written, lock released |
| 3 | `restore.sh --yes` round-trip | **PASS** — diff clean for all regular files; symlink restored as real file (documented behavior); `PRAGMA integrity_check` → `ok`, 3 rows intact, `.dump` identical to source; restored tree owner-only (700/600) per `umask 077` + `chmod -R go-rwx`; staging consumed by atomic rename; lock released |
| 4 | Lock mutex (new) | **PASS** — with the lock dir pre-created, both scripts refuse with a clear message and exit 1, and neither removes the foreign lock on exit (trap installed only after acquisition). Also verified: failed runs release their own lock; unset-bucket failure occurs before lock acquisition so nothing leaks |
| 4 | `backup.sh` with `TIGRIS_BACKUP_BUCKET` unset | **PASS** — single clear message, exit 1, no stack trace, no lock leaked |
| 4 | Filenames with a space and a single quote (regular files) | **PASS** — both survived backup and restore with content intact |
| 4 | SQLite db named `dave's sessions.db` (quote in a **db** path) | **FAIL → FIXED → PASS** — exposed a real bug in the `VACUUM INTO` escaping (see script changes). After the fix: backed up, restored, `integrity_check` ok, row intact |
| 4 | `backup.sh` twice in a row | **PASS** — both runs succeeded (idempotent). Unchanged `sessions.db` was not re-uploaded (`--checksum` + byte-stable `VACUUM INTO` output) |
| 4 | Mirror + archive semantics (new `rclone sync --backup-dir`) | **PASS** — locally deleted `workspace/nested/deep.txt` disappeared from `openclaw-state/` on the next run and was preserved at `archive/20260722T164402Z/workspace/nested/deep.txt`; each run's replaced `.tigris-backup.json` was archived; a subsequent restore correctly does not resurrect the deleted file |
| 4 | Live-process guard (positively exercised this time) | **PASS** — with a decoy process matching `openclaw` running, `restore.sh --yes` refused with exit 1 and listed the PID (57536); `OPENCLAW_RESTORE_FORCE=1` overrode as documented; backup's version of the check is advisory-only as designed |
| 4 | Restore onto NON-empty target | **PASS** — existing dir moved aside to `/tmp/fake-restore.pre-restore.20260722T164436Z` with sentinel file preserved; restored tree contained exactly the backup contents |
| 4 | Snapshot step | **SKIPPED GRACEFULLY** — tigris CLI not installed; `note: tigris CLI not found; skipping bucket snapshot`, run still succeeded. The new snapshot-failure WARNING path was therefore not exercised |

## Script changes (2)

1. **[scripts/backup.sh] — real bug, quote escaping in `VACUUM INTO` (the
   round-trip for quote-named databases failed without this):**
   `esc="${dest//\'/\'\'}"` kept the backslashes literally (inside double
   quotes, bash does not treat `\'` as just `'` in the replacement), producing
   `dave\'\'s` and an invalid SQL string literal — `sqlite3` failed with
   `unrecognized token: "\"` and the whole backup aborted for any `.db` path
   containing a single quote. Replaced with an unambiguous form:
   ```bash
   q="'"
   esc="${dest//$q/$q$q}"
   ```
   which correctly doubles quotes (`dave''s`).
2. **[scripts/restore.sh] — shellcheck SC2086 (info):** the refusal message
   echoed unquoted `$others`; replaced with quoted `${others//$'\n'/ }` so
   PIDs stay space-joined on one line. Cosmetic; no behavior change.

No safety behavior was weakened: dry-run default, no-delete-without-archive
sync, WAL/journal exclusion, lock mutex, live-process refusal, and the
pre-restore safety copy were all left intact and all verified working.

## Final `rclone ls tigris:tigris-dlt-demo` (before cleanup purge)

```
      96 archive/20260722T164348Z/.tigris-backup.json
      96 archive/20260722T164350Z/.tigris-backup.json
      96 archive/20260722T164402Z/.tigris-backup.json
      10 archive/20260722T164402Z/workspace/nested/deep.txt
      96 openclaw-state/.tigris-backup.json
    8192 openclaw-state/dave's sessions.db
      29 openclaw-state/openclaw.json
    8192 openclaw-state/sessions.db
      14 openclaw-state/workspace/dave's file.txt
      14 openclaw-state/workspace/file with space.txt
      16 openclaw-state/workspace/link-to-note.txt
      16 openclaw-state/workspace/note.txt
```

## Cleanup performed

- `rclone purge` of `openclaw-state/` and `archive/` (both created by this
  test) — bucket itself, access key, and rclone config untouched
- Deleted `/tmp/fake-openclaw`, `/tmp/fake-restore`,
  `/tmp/fake-restore.pre-restore.*`, `/tmp/fake-openclaw-decoy.sh`
- Deleted the temporary scratchpad `rclone.conf`

**Security note:** the access key pair was pasted into chat in plaintext;
rotating `tigris-dlt-key` afterwards is recommended (key management was out of
scope for this test).
