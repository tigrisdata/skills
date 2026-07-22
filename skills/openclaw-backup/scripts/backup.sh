#!/usr/bin/env bash
# tigris-backup: consistent backup of the OpenClaw state directory to Tigris.
# Requires: rclone, sqlite3. Optional: tigris CLI (for bucket snapshots).
set -euo pipefail

STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
REMOTE="${TIGRIS_BACKUP_REMOTE:-tigris}"
BUCKET="${TIGRIS_BACKUP_BUCKET:?Set TIGRIS_BACKUP_BUCKET to your backup bucket name}"
PREFIX="${TIGRIS_BACKUP_PREFIX:-openclaw-state}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"

command -v rclone >/dev/null || { echo "error: rclone not found on PATH" >&2; exit 1; }
command -v sqlite3 >/dev/null || { echo "error: sqlite3 not found on PATH" >&2; exit 1; }
[ -d "$STATE_DIR" ] || { echo "error: state dir not found: $STATE_DIR" >&2; exit 1; }

STAGING="$(mktemp -d "${TMPDIR:-/tmp}/openclaw-backup.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT

echo "==> Staging consistent copy of $STATE_DIR"

# 1) Everything except SQLite files (and journals/WALs, which belong to the
#    live database and must not be backed up raw).
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
# No --delete: removing remote data is a deliberate, manual act.
rclone copy "$STAGING" "$REMOTE:$BUCKET/$PREFIX/" --transfers 8 --checksum

# 4) Bucket snapshot, if the tigris CLI is available.
if command -v tigris >/dev/null; then
  if tigris snapshots take "$BUCKET" "backup-$STAMP" 2>/dev/null; then
    echo "==> Snapshot taken: backup-$STAMP"
  else
    echo "note: snapshot skipped (bucket may not be snapshot-enabled)" >&2
  fi
else
  echo "note: tigris CLI not found; skipping bucket snapshot" >&2
fi

echo "==> Backup complete: $REMOTE:$BUCKET/$PREFIX/ @ $STAMP"
