#!/usr/bin/env bash
# openclaw-backup: restore the OpenClaw state directory from a Tigris bucket.
# Dry-run by default; pass --yes to write. Stop the Gateway first.
set -euo pipefail
umask 077                                        # created files are owner-only

STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
STATE_DIR="${STATE_DIR%/}"
# Operate on the real path so a symlinked state dir isn't stranded, while the
# user's symlink keeps pointing at the restored location.
if [ -L "$STATE_DIR" ]; then
  STATE_DIR="$(readlink -f "$STATE_DIR" 2>/dev/null || echo "$STATE_DIR")"
fi
REMOTE="${TIGRIS_BACKUP_REMOTE:-tigris}"
BUCKET="${TIGRIS_BACKUP_BUCKET:?Set TIGRIS_BACKUP_BUCKET to the bucket to restore from}"
PREFIX="${TIGRIS_BACKUP_PREFIX:-openclaw-state}"
CONFIRM="${1:-}"
LOCKDIR="${TMPDIR:-/tmp}/openclaw-backup.lock.d"

command -v rclone >/dev/null || { echo "error: rclone not found on PATH" >&2; exit 1; }

# Portable mutex shared with backup.sh (see note there).
if ! mkdir "$LOCKDIR" 2>/dev/null; then
  echo "error: another openclaw-backup/restore appears to be running" >&2
  echo "       (lock: $LOCKDIR). Remove it if you're sure it is stale." >&2
  exit 1
fi
STAGING=""
cleanup() { [ -n "$STAGING" ] && rm -rf "$STAGING"; rmdir "$LOCKDIR" 2>/dev/null || true; }
trap cleanup EXIT

echo "==> Restore source: $REMOTE:$BUCKET/$PREFIX/"
echo "==> Restore target: $STATE_DIR"

if [ "$CONFIRM" != "--yes" ]; then
  echo "==> DRY RUN (pass --yes to apply). Changes that would be made:"
  rclone copy "$REMOTE:$BUCKET/$PREFIX/" "$STATE_DIR" --dry-run
  exit 0
fi

# Best-effort guard. This substring check is advisory only — the real
# protection is the download-then-swap below, which never writes into a live
# state directory. Override a false positive with OPENCLAW_RESTORE_FORCE=1.
others="$(pgrep -f 'openclaw' | grep -vx -e "$$" -e "$PPID" 2>/dev/null || true)"
if [ -n "$others" ] && [ "${OPENCLAW_RESTORE_FORCE:-}" != "1" ]; then
  echo "error: an OpenClaw process may be running (PIDs:" $others ")." >&2
  echo "       Stop the Gateway before restoring. If this is a false match" >&2
  echo "       (the check is a substring test), set OPENCLAW_RESTORE_FORCE=1." >&2
  exit 1
fi

# 1) Download to a staging dir FIRST. Nothing touches the live state directory
#    until the transfer fully succeeds, so a network drop, expired credential,
#    or full disk leaves current state untouched rather than half-restored.
STAGING="$(mktemp -d "${TMPDIR:-/tmp}/openclaw-restore.XXXXXX")"
echo "==> Downloading backup to staging..."
rclone copy "$REMOTE:$BUCKET/$PREFIX/" "$STAGING" --transfers 8 --checksum

# 2) Move existing state aside (only now that we have a complete copy in hand).
if [ -d "$STATE_DIR" ] && [ -n "$(ls -A "$STATE_DIR" 2>/dev/null)" ]; then
  SAFETY="${STATE_DIR}.pre-restore.$(date -u +%Y%m%dT%H%M%SZ)"
  echo "==> Existing state moved aside to $SAFETY"
  mv "$STATE_DIR" "$SAFETY"
else
  rm -rf "$STATE_DIR"
fi

# 3) Swap staging into place atomically, then lock down modes. S3/rclone do not
#    carry Unix permissions, so without this, restored credential files
#    (openclaw.json, tokens) would come back world-readable under the umask.
mkdir -p "$(dirname "$STATE_DIR")"
mv "$STAGING" "$STATE_DIR"
STAGING=""                                        # consumed; don't clean it up
chmod 700 "$STATE_DIR"
find "$STATE_DIR" -type d -exec chmod 700 {} +
find "$STATE_DIR" -type f -exec chmod 600 {} +

echo "==> Restore complete. Review $STATE_DIR, then start the Gateway."
[ -f "$STATE_DIR/.tigris-backup.json" ] && cat "$STATE_DIR/.tigris-backup.json"
