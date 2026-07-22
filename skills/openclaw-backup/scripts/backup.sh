#!/usr/bin/env bash
# openclaw-backup: consistent backup of the OpenClaw state directory to Tigris.
# Requires: rclone, sqlite3. Optional: tigris CLI (for bucket snapshots).
set -euo pipefail

STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
STATE_DIR="${STATE_DIR%/}"                       # normalize: no trailing slash
REMOTE="${TIGRIS_BACKUP_REMOTE:-tigris}"
BUCKET="${TIGRIS_BACKUP_BUCKET:?Set TIGRIS_BACKUP_BUCKET to your backup bucket name}"
PREFIX="${TIGRIS_BACKUP_PREFIX:-openclaw-state}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOCKDIR="${TMPDIR:-/tmp}/openclaw-backup.lock.d"

command -v rclone  >/dev/null || { echo "error: rclone not found on PATH"  >&2; exit 1; }
command -v sqlite3 >/dev/null || { echo "error: sqlite3 not found on PATH" >&2; exit 1; }
[ -d "$STATE_DIR" ] || { echo "error: state dir not found: $STATE_DIR" >&2; exit 1; }

# Portable mutex (mkdir is atomic on macOS and Linux; flock is Linux-only).
# Prevents a scheduled backup and a restore from touching state at once.
if ! mkdir "$LOCKDIR" 2>/dev/null; then
  echo "error: another openclaw-backup/restore appears to be running" >&2
  echo "       (lock: $LOCKDIR). Remove it if you're sure it is stale." >&2
  exit 1
fi
STAGING="$(mktemp -d "${TMPDIR:-/tmp}/openclaw-backup.XXXXXX")"
trap 'rm -rf "$STAGING"; rmdir "$LOCKDIR" 2>/dev/null || true' EXIT

# Advisory only: with a live Gateway, files and databases are captured in
# separate passes, so a whole-tree copy may mix moments. Each database stays
# internally consistent (.backup); prefer running while the Gateway is idle.
if pgrep -f "openclaw" | grep -vxq -e "$$" -e "$PPID" 2>/dev/null; then
  echo "note: an OpenClaw process may be running. Per-database backups stay"  >&2
  echo "      consistent, but files and databases are captured in separate"   >&2
  echo "      passes; prefer backing up while the Gateway is idle."           >&2
fi

echo "==> Staging consistent copy of $STATE_DIR"

# 1) Everything except SQLite files (and their journals/WALs, which belong to
#    the live database and must not be backed up raw).
rsync -a \
  --exclude '*.sqlite' --exclude '*.sqlite3' --exclude '*.db' \
  --exclude '*-wal' --exclude '*-shm' --exclude '*-journal' \
  --exclude 'logs/' \
  "$STATE_DIR"/ "$STAGING"/

# 2) SQLite databases via the backup API (consistent even while in use).
while IFS= read -r -d '' db; do
  rel="${db#"$STATE_DIR"/}"
  mkdir -p "$STAGING/$(dirname "$rel")"
  sqlite3 "$db" ".backup '$STAGING/$rel'"
  echo "    sqlite backup: $rel"
done < <(find "$STATE_DIR" \( -name '*.sqlite' -o -name '*.sqlite3' -o -name '*.db' \) -type f -print0)

# 3) Record backup metadata.
printf '{"backed_up_at":"%s","source_host":"%s","state_dir":"%s"}\n' \
  "$STAMP" "$(hostname)" "$STATE_DIR" > "$STAGING/.tigris-backup.json"

echo "==> Syncing to $REMOTE:$BUCKET/$PREFIX/"
# `sync` makes the prefix a faithful mirror of current state, so a restore
# reproduces exactly what exists now (deleted files do not reappear).
# `--backup-dir` preserves every replaced or removed object under a timestamped
# archive prefix, so nothing is ever destroyed — deletes are recoverable, just
# not part of the live restore set.
rclone sync "$STAGING" "$REMOTE:$BUCKET/$PREFIX/" \
  --backup-dir "$REMOTE:$BUCKET/archive/$STAMP" \
  --transfers 8 --checksum

# 4) Bucket snapshot, if the tigris CLI is available. Distinguish "CLI absent"
#    (fine, skip) from "command failed" (surfaced loudly — a silent failure
#    would leave no recovery point while the run looked successful).
if command -v tigris >/dev/null; then
  if snap_err="$(tigris snapshots take "$BUCKET" "backup-$STAMP" 2>&1)"; then
    echo "==> Snapshot taken: backup-$STAMP"
  else
    echo "WARNING: snapshot step FAILED — the file backup uploaded, but no" >&2
    echo "         snapshot recovery point was created. Error was:"         >&2
    echo "         $snap_err"                                               >&2
    echo "         (Check the bucket is snapshot-enabled and the tigris"    >&2
    echo "         CLI is authenticated.)"                                  >&2
  fi
else
  echo "note: tigris CLI not found; skipping bucket snapshot" >&2
fi

echo "==> Backup complete: $REMOTE:$BUCKET/$PREFIX/ @ $STAMP"
