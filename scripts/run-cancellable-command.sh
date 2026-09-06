#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -eq 0 ]]; then
  echo "Usage: $0 <command> [args...]" >&2
  exit 2
fi

command_pid=""
terminate_command() {
  trap - INT TERM HUP
  if [[ -n "${command_pid}" ]] && kill -0 "${command_pid}" 2>/dev/null; then
    kill -TERM "${command_pid}" 2>/dev/null || true
  fi
}
trap terminate_command INT TERM HUP

set +e
"$@" &
command_pid=$!
wait "${command_pid}"
command_status=$?
set -e

trap - INT TERM HUP
exit "${command_status}"
