#!/usr/bin/env bash

# Share the available CPUs between simultaneous generators and their model
# workers. A nonzero workerCount in a fixture's config still takes precedence
# over this environment fallback, just as it does when invoking Tonik directly.
configure_setup_workers() {
  local cpu_count="$1"
  local worker_budget=1

  if [[ -n "${INTEGRATION_SETUP_JOBS+x}" && ! "$INTEGRATION_SETUP_JOBS" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: INTEGRATION_SETUP_JOBS must be a positive integer." >&2
    return 64
  fi
  if [[ -n "${TONIK_WORKERS:-}" && ! "$TONIK_WORKERS" =~ ^(0|[1-9][0-9]*)$ ]]; then
    echo "Error: TONIK_WORKERS must be a non-negative integer." >&2
    return 64
  fi

  if [ "${TONIK_WORKERS:-}" = 0 ]; then
    worker_budget=$((cpu_count - 1))
    [ "$worker_budget" -ge 1 ] || worker_budget=1
    [ "$worker_budget" -le 16 ] || worker_budget=16
  elif [ -n "${TONIK_WORKERS:-}" ]; then
    # Compare lengths first to avoid overflowing shell arithmetic for a large
    # override. Tonik itself validates its supported integer range.
    if [ "${#TONIK_WORKERS}" -gt "${#cpu_count}" ] || [ "$TONIK_WORKERS" -ge "$cpu_count" ]; then
      worker_budget="$cpu_count"
    else
      worker_budget="$TONIK_WORKERS"
    fi
  fi

  SETUP_JOBS=$((cpu_count / worker_budget))
  [ "$SETUP_JOBS" -le 4 ] || SETUP_JOBS=4
  SETUP_JOBS="${INTEGRATION_SETUP_JOBS-$SETUP_JOBS}"

  if [ -z "${TONIK_WORKERS:-}" ]; then
    if [ "${#SETUP_JOBS}" -gt "${#cpu_count}" ] || [ "$SETUP_JOBS" -ge "$cpu_count" ]; then
      TONIK_WORKERS=1
    else
      TONIK_WORKERS=$((cpu_count / SETUP_JOBS))
    fi
  fi
  export TONIK_WORKERS
}

# xargs maintains a rolling pool without wait -n, which macOS Bash 3.2 lacks.
# Run every command and wait for every child even if one command fails.
run_commands() {
  local max_jobs="$1"
  shift
  local command_count="$#"

  if [[ ! "$max_jobs" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: command concurrency must be a positive integer." >&2
    return 64
  fi
  [ "$command_count" -gt 0 ] || return 0
  if [ "${#max_jobs}" -gt "${#command_count}" ] || [ "$max_jobs" -gt "$command_count" ]; then
    max_jobs="$command_count"
  fi

  printf '%s\0' "$@" | xargs -0 -n 1 -P "$max_jobs" bash -c '
    SECONDS=0
    if bash -c "$1"; then
      echo "Completed (${SECONDS}s): $1"
    else
      status=$?
      echo "Error: command failed (exit $status, ${SECONDS}s): $1" >&2
      # In particular, never forward exit 255: that makes xargs stop early.
      exit 1
    fi
  ' integration-setup
}
