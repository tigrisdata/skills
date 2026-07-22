#!/usr/bin/env bash
# openclaw-backup: restore the OpenClaw state directory from a Tigris bucket.
# Dry-run by default; pass --yes to write. Stop the Gateway first.
set -euo pipefail
umask 077                                        # created files are owner-only

STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
STATE_DIR="${STATE_DIR%/}"
# Resolve one level of symlink without `readlink -f` (unsupported on macOS), so
# a symlinked state dir isn't stranded and the user's symlink keeps pointing at
# the restored location.
if [ -L "$STATE_DIR" ]; then
  _t="$(readlink "$STATE_DIR")"
  case "$_t" in
    /*) STATE_DIR="$_t" ;;
    *)  STATE_DIR="$(cd "$(dirname "$STATE_DIR")" && pwd -P)/$_t" ;;
  esac
  STATE_DIR="${STATE_DIR%/}"
fi
REMOTE="${TIGRIS_BACKUP_REMOTE:-tigris}"
BUCKET="${TIGRIS_BACKUP_BUCKET:?Set TIGRIS_BACKUP_BUCKET to the bucket to restore from}"
PREFIX="${TIGRIS_BACKUP_PREFIX:-openclaw-state}"
CONFIRM="${1:-}"
LOCKDIR="${TMPDIR:-/tmp}/openclaw-backup.lock.d"

command -v rclone >/dev/null || { echo "error: rclone not found on PATH" >&2; exit 1; }

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
  echo
  echo "DRY RUN. A real restore (--yes) REPLACES the target directory:"
  echo "  - current contents of $STATE_DIR move to a .pre-restore.* safety copy"
  echo "  - the restored tree contains exactly what is in the backup below"
  echo "  - local-only files not in the backup will NOT be in the restored"
  echo "    tree (they remain in the safety copy, not deleted)"
  echo
  echo "Backup that would be restored:"
  rclone size "$REMOTE:$BUCKET/$PREFIX/"
  exit 0
fi

# Best-effort guard (advisory). The real protection is the download-then-swap
# below. Override a false positive with OPENCLAW_RESTORE_FORCE=1.
others="$(pgrep -f 'openclaw' | grep -vx -e "$$" -e "$PPID" 2>/dev/null || true)"
if [ -n "$others" ] && [ "${OPENCLAW_RESTORE_FORCE:-}" != "1" ]; then
  echo "error: an OpenClaw process may be running (PIDs: ${others//$'\n'/ })." >&2
  echo "       Stop the Gateway before restoring. If this is a false match" >&2
  echo "       (the check is a substring test), set OPENCLAW_RESTORE_FORCE=1." >&2
  exit 1
fi

# 1) Download to a staging dir on the SAME filesystem as the target, so the
#    final swap is an atomic rename (a cross-filesystem mv degrades to
#    copy+delete and is not atomic). Nothing touches live state until the
#    transfer fully succeeds.
STAGING="$(mktemp -d "$(dirname "$STATE_DIR")/.openclaw-restore.XXXXXX")"
echo "==> Downloading backup to staging..."
rclone copy "$REMOTE:$BUCKET/$PREFIX/" "$STAGING" --transfers 8 --checksum

# 2) Move existing state aside (only now that a complete copy is in hand).
if [ -d "$STATE_DIR" ] && [ -n "$(ls -A "$STATE_DIR" 2>/dev/null)" ]; then
  SAFETY="${STATE_DIR}.pre-restore.$(date -u +%Y%m%dT%H%M%SZ)"
  echo "==> Existing state moved aside to $SAFETY"
  mv "$STATE_DIR" "$SAFETY"
else
  rm -rf "$STATE_DIR"
fi

# 3) Atomic rename into place (same filesystem), then tighten permissions.
#    S3/rclone do not carry Unix modes, so restored files arrive under the
#    umask; `go-rwx` guarantees owner-only without stripping owner execute bits
#    that legitimately-executable files may carry. Note: object storage does not
#    preserve execute bits, so anything relying on them (e.g. skill scripts)
#    should be reinstalled rather than restored.
mv "$STAGING" "$STATE_DIR"
STAGING=""                                        # consumed; don't clean it up
chmod -R go-rwx "$STATE_DIR"

echo "==> Restore complete. Review $STATE_DIR, then start the Gateway."
[ -f "$STATE_DIR/.tigris-backup.json" ] && cat "$STATE_DIR/.tigris-backup.json"
