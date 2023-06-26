#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

# Locations of source SCB file and the backup target directories
SCB_SOURCE_FILE='/var/lnd/.scb/channel.backup'
LOCAL_BACKUP_DIR="${LOCAL_BACKUP_DIR:?}"

ACTUAL_HOME=$(echo ~)
LOCAL_BACKUP_DIR="${LOCAL_BACKUP_DIR//\~/$ACTUAL_HOME}"

RUNTIME_STATUS_FILE='/run/lnd-scb/status'

# Local backup function
run_local_backup_on_change() {
  echo "Copying backup file to local storage device ..."
  echo "$1"
  cp "$SCB_SOURCE_FILE" "$1"
  echo "Success! The file has been backed up!"
}

check_writable_dir() {
  [ -w "$LOCAL_BACKUP_DIR" ] || (
    echo "Error: $LOCAL_BACKUP_DIR is not writable"
    exit 2
  )
}

rotate_old_backups() {
  find "$LOCAL_BACKUP_DIR" -type f -name 'channel-*.backup' -exec ls -1rt {} + | head -n -5 | xargs --no-run-if-empty rm
}

trap "echo 'error' > '${RUNTIME_STATUS_FILE}'" ERR

# Monitoring function
run() {
  if [ ! -f "$RUNTIME_STATUS_FILE" ]; then
    skip_inotifywait=true
    touch "$RUNTIME_STATUS_FILE"
  else
    if [ ! -s "$RUNTIME_STATUS_FILE" ]; then
      skip_inotifywait=false
    else
      skip_inotifywait=true
      echo 'Recovering from previous error ...' >&2
    fi
  fi

  while true; do
    if [ "$skip_inotifywait" = false ]; then
      inotifywait -e MODIFY $SCB_SOURCE_FILE
      echo 'channel.backup has been changed!'
    fi

    skip_inotifywait=false

    check_writable_dir

    LOCAL_BACKUP_FILE="$LOCAL_BACKUP_DIR/channel-$(date +"%Y%m%d-%H%M%S").backup"
    run_local_backup_on_change "$LOCAL_BACKUP_FILE"

    : > "$RUNTIME_STATUS_FILE"

    rotate_old_backups
  done
}

run
