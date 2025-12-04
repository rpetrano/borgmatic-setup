#!/usr/bin/env bash
# usage: backup-notify.sh <job> <status> <logfile>
set -euo pipefail

TYPE="${1:?backup|check}"
JOB="${2:?job-name}"
STATUS="${3:?success|failure}"

source /etc/default/backup-notify
: "${MAILTO:?MAILTO must be set in environment or in /etc/default/backup-notify}"

if [ "$TYPE" = "check" ]; then
  SERVICE=borgmatic-check.service
  TITLE=backupcheck
else
  SERVICE="borgmatic@${JOB}.service"
  TITLE=backup
fi

STDIN_CONTENT="$(timeout 0.1 cat || true)"

{
    echo "Host: $(hostname)"
    echo "Type: $TYPE"
    echo "Job:  $JOB"
    echo "When: $(date -Is)"
    echo "Status: $STATUS"
    echo
    echo "--- recent log ---"

    if [[ "$STATUS" == "failure" ]]; then
        if [[ -n "$STDIN_CONTENT" ]]; then
            echo "$STDIN_CONTENT" | tail -n 100 || true
        else
            journalctl -u "$SERVICE" -n 100 --no-pager 2>/dev/null || true
        fi
    fi
} | /usr/bin/mailx -s "[${TITLE}/${JOB}] ${STATUS^^}" "$MAILTO"

