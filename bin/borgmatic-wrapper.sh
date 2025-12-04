#!/usr/bin/env bash
# usage: borgmatic-wrapper.sh <job_name>
# - Fails (exit 1) if the passphrase file is unavailable (home not unlocked)
# - Otherwise execs borgmatic on /etc/borgmatic.d/<job_name>.yaml
# - Exits with borgmatic's exit code so systemd OnFailure works

set -uo pipefail
JOB="${1:?missing job name}"; shift
CFG="/etc/borgmatic.d/${JOB}.yaml"
SECRET="/etc/secrets/borg"

# Basic sanity
if [[ ! -r "$CFG" ]]; then
  echo "[borgmatic-wrapper] Config not readable: $CFG" >&2
  exit 2
fi

if [[ ! -r "$SECRET" ]]; then
  echo "[borgmatic-wrapper] Secret not present, skipping job '$JOB' at $(date -Is)" >&2
  exit 1
fi

# Run borgmatic for this job
exec /usr/bin/borgmatic --config "$CFG" --syslog-verbosity -2 --verbosity 1 create prune compact

