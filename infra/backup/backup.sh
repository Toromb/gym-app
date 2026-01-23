#!/bin/bash

# ==============================================================================
# Gym App - Daily Backup Script
# ==============================================================================
# This script creates a compressed dump of the PostgreSQL database,
# uploads it to Google Drive using rclone, and manages retention.
#
# Usage: ./backup.sh
# Dependencies: docker, rclone, gzip
# ==============================================================================

# --- Configuration ---
BACKUP_DIR="/root/gym-app-backups"
CONTAINER_NAME="gym_app_db_prod" # Must match docker-compose container_name
DB_USER="postgres"
DB_NAME="gym_db"                 # Default DB name
RCLONE_REMOTE="gdrive"           # Name of the remote configured in 'rclone config'
RCLONE_DEST="gym-app-backups"    # Folder in Google Drive
RETENTION_DAYS=7                 # How many days to keep backups

# --- Setup ---
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="gym_db_$TIMESTAMP.sql.gz"
FULLPATH="$BACKUP_DIR/$FILENAME"

# Ensure local backup directory exists
mkdir -p $BACKUP_DIR

echo "[$(date)] Starting backup process..."

# --- 1. Create Backup (Dump & Compress) ---
# We use docker exec to run pg_dump inside the container
if docker exec -t $CONTAINER_NAME pg_dump -U $DB_USER $DB_NAME | gzip > "$FULLPATH"; then
    echo "[OK] Database dumped and compressed to: $FILENAME"
    echo "     Size: $(du -h "$FULLPATH" | cut -f1)"
else
    echo "[ERROR] Failed to create database dump!"
    exit 1
fi

# --- 2. Upload to Cloud (Google Drive) ---
echo "[...] Uploading to $RCLONE_REMOTE:$RCLONE_DEST..."
if rclone copy "$FULLPATH" "$RCLONE_REMOTE:$RCLONE_DEST"; then
    echo "[OK] Upload successful."
else
    echo "[ERROR] Upload failed. Check rclone configuration."
    # We don't exit here so we can still try to cleanup local files if needed
    # but preferably we want to keep it if upload failed.
fi

# --- 3. Remote Cleanup (Retention Policy) ---
echo "[...] Applying retention policy (Keeping $RETENTION_DAYS days)..."
rclone delete --min-age ${RETENTION_DAYS}d "$RCLONE_REMOTE:$RCLONE_DEST"
# rclone delete sometimes returns non-zero if nothing to delete, so we ignore exit code or handle it gently

# --- 4. Local Cleanup ---
# We keep local backups for 2 days just in case, to save disk space on VPS
find "$BACKUP_DIR" -name "gym_db_*.sql.gz" -mtime +2 -delete
echo "[OK] Local cleanup (older than 2 days) validation."

echo "[$(date)] Backup process completed successfully."
exit 0
