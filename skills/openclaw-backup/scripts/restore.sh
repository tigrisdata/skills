#!/usr/bin/env bash
# tigris-backup: restore the OpenClaw state directory from a Tigris bucket.
# Dry-run by default; pass --yes to write. Stop the Gateway first.
set -euo pipefail

STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
REMOTE="${TIGRIS_BACKUP_REMOTE:-tigris}"
BUCKET="${TIGRIS_BACKUP_BUCKET:?Set TIGRIS_BACKUP_BUCKET to the bucket to restore from}"
PREFIX="${TIGRIS_BACKUP_PREFIX:-openclaw-state}"
CONFIRM="${1:-}"

command -v rclone >/dev/null || { echo "error: rclone not found on PATH" >&2; exit 1; }

# Refuse to restore over a running Gateway: live SQLite + incoming file
# writes would corrupt both directions.
if pgrep -f "openclaw" >/dev/null 2>&1; then
  echo "error: an openclaw process appears to be running. Stop the Gateway" >&2
  echo "       before restoring (live databases must not be overwritten)." >&2
  exit 1
fi

echo "==> Restore source: $REMOTE:$BUCKET/$PREFIX/"
echo "==> Restore target: $STATE_DIR"

if [ "$CONFIRM" != "--yes" ]; then
  echo "==> DRY RUN (pass --yes to apply). Changes that would be made:"
  rclone copy "$REMOTE:$BUCKET/$PREFIX/" "$STATE_DIR" --dry-run
  exit 0
fi

# Keep a local safety copy of whatever is currently in place.
if [ -d "$STATE_DIR" ] && [ -n "$(ls -A "$STATE_DIR" 2>/dev/null)" ]; then
  SAFETY="${STATE_DIR}.pre-restore.$(date -u +%Y%m%dT%H%M%SZ)"
  echo "==> Existing state found; moving it aside to $SAFETY"
  mv "$STATE_DIR" "$SAFETY"
fi
mkdir -p "$STATE_DIR"

rclone copy "$REMOTE:$BUCKET/$PREFIX/" "$STATE_DIR" --transfers 8 --checksum

echo "==> Restore complete. Review $STATE_DIR, then start the Gateway."
[ -f "$STATE_DIR/.tigris-backup.json" ] && cat "$STATE_DIR/.tigris-backup.json"
