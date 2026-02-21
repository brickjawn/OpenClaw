#!/usr/bin/env bash
# Backup OpenClaw config and state for event-promo flavor.
# Per Agent Requirements: local backups of config, agent state, vector indexes.
# Usage: ./scripts/backup-openclaw.sh [--full]
#   --full: include full ~/.openclaw tarball (default: config + cron only)

set -e

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
BACKUP_DIR="${OPENCLAW_BACKUP_DIR:-$OPENCLAW_HOME/backups}"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p "$BACKUP_DIR"

# Config backup (always)
if [[ -f "$OPENCLAW_HOME/openclaw.json" ]]; then
  cp "$OPENCLAW_HOME/openclaw.json" "$BACKUP_DIR/openclaw-$DATE.json"
  echo "Backed up config to $BACKUP_DIR/openclaw-$DATE.json"
fi

# Cron jobs (always)
if [[ -f "$OPENCLAW_HOME/cron/jobs.json" ]]; then
  mkdir -p "$BACKUP_DIR/cron"
  cp "$OPENCLAW_HOME/cron/jobs.json" "$BACKUP_DIR/cron/jobs-$DATE.json"
  echo "Backed up cron to $BACKUP_DIR/cron/jobs-$DATE.json"
fi

# Exec approvals (always)
if [[ -f "$OPENCLAW_HOME/exec-approvals.json" ]]; then
  cp "$OPENCLAW_HOME/exec-approvals.json" "$BACKUP_DIR/exec-approvals-$DATE.json"
  echo "Backed up exec-approvals to $BACKUP_DIR/exec-approvals-$DATE.json"
fi

# Full state (optional)
if [[ "${1:-}" == "--full" ]]; then
  TARBALL="$HOME/openclaw-full-$DATE.tar.gz"
  tar -czvf "$TARBALL" -C "$(dirname "$OPENCLAW_HOME")" "$(basename "$OPENCLAW_HOME")"
  echo "Full backup: $TARBALL"
fi

echo "Backup complete."
