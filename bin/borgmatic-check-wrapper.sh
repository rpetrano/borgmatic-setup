#!/usr/bin/env bash
# usage: borgmatic-check-wrapper.sh
# - Fails (exit 1) if the passphrase file is unavailable (home not unlocked)
# - Otherwise execs borgmatic check on all /etc/borgmatic.d/*.yaml files
# - Notifies of failure on each failed check, and returns error code if any of them failed

set -uo pipefail

SECRET="/etc/secrets/borg"

if [[ ! -r "$SECRET" ]]; then
  echo "[borgmatic-check-wrapper] Secret not present, skipping backup check at $(date -Is)" 2>&1
  echo "[borgmatic-check-wrapper] Secret not present, skipping backup check" | backup-notify.sh check "*" failure
  exit 1
fi

JOBS=()
failed=0

for CFG in /etc/borgmatic.d/*.yaml; do
  JOBFILE="$(basename "$CFG")"
  JOB="${JOBFILE%.*}"
  JOBS+=("$JOB")

  # Basic sanity
  if [[ ! -r "$CFG" ]]; then
    echo "[borgmatic-check-wrapper] Config not readable: $CFG" >&2
    echo "[borgmatic-check-wrapper] Config not readable: $CFG" >&2 | backup-notify.sh check "$JOB" failure
    failed=1
    continue
  fi

  # Run borgmatic for this job
  /usr/bin/borgmatic --config "$CFG" --syslog-verbosity -2 --verbosity 1 check
  if [ "$?" -ne 0 ]; then
    echo "[borgmatic-check-wrapper] Backup check failed: $JOB" >&2
    backup-notify.sh check "$JOB" failure
    failed=1
  fi
done

if [ "$failed" -eq 0 ]; then
  backup-notify.sh check "${JOBS[@]}" success
fi

exit $failed

