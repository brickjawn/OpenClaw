#!/usr/bin/env bash
# sync_data.sh — rsync OneDrive (or local mount) → team_sync for OpenClaw memory search
#
# Use for event-promo workflows (e.g. Louder Than Cancer) where the team edits
# docs in OneDrive and the agent needs them indexed. rsync is efficient: only
# transfers changed file parts.
#
# Prerequisites:
#   - OneDrive synced locally (official client) or mounted via rclone/WebDAV
#   - DEST path added to memorySearch.extraPaths in openclaw.json
#
# Usage:
#   ./scripts/sync_data.sh
#   TEAM_SYNC_SOURCE=/path/to/source TEAM_SYNC_DEST=/path/to/dest ./scripts/sync_data.sh
#
# Cron example (run before morning digest):
#   0 8 * * * /path/to/openclaw/scripts/sync_data.sh
#
# OpenClaw indexes Markdown in extraPaths automatically; no embed script needed.

set -euo pipefail

SOURCE="${TEAM_SYNC_SOURCE:-$HOME/OneDrive/LouderThanCancer}"
DEST="${TEAM_SYNC_DEST:-${OPENCLAW_STATE_DIR:-$HOME/.openclaw}/team_sync}"

# Expand ~ in paths
SOURCE="${SOURCE/#\~/$HOME}"
DEST="${DEST/#\~/$HOME}"

if [[ ! -d "$SOURCE" ]]; then
  echo "sync_data: SOURCE not found: $SOURCE" >&2
  echo "Set TEAM_SYNC_SOURCE to your OneDrive folder (e.g. ~/OneDrive/LouderThanCancer)" >&2
  exit 1
fi

mkdir -p "$DEST"

# -a: archive (preserve permissions, timestamps)
# -v: verbose
# --delete: remove files in DEST if deleted in SOURCE
rsync -av --delete "$SOURCE/" "$DEST/"

echo "sync_data: synced $SOURCE -> $DEST"
