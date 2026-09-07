#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -eq 0 ]]; then
  echo "Usage: $0 <command> [args...]" >&2
  exit 2
fi

command_pid=""
process_group_started=false
terminate_command() {
  trap - INT TERM HUP
  if [[ -z "${command_pid}" ]] || ! kill -0 "${command_pid}" 2>/dev/null; then
    return
  fi
  if [[ "${process_group_started}" == true ]]; then
    kill -TERM -- "-${command_pid}" 2>/dev/null || true
  elif command -v taskkill.exe >/dev/null 2>&1; then
    taskkill.exe //PID "${command_pid}" //T //F >/dev/null 2>&1 || true
  else
    kill -TERM "${command_pid}" 2>/dev/null || true
  fi
  for _ in 1 2 3 4 5; do
    kill -0 "${command_pid}" 2>/dev/null || return
    sleep 1
  done
  if [[ "${process_group_started}" == true ]]; then
    kill -KILL -- "-${command_pid}" 2>/dev/null || true
  elif kill -0 "${command_pid}" 2>/dev/null; then
    kill -KILL "${command_pid}" 2>/dev/null || true
  fi
}
trap terminate_command INT TERM HUP

set +e
if command -v setsid >/dev/null 2>&1; then
  setsid "$@" &
  process_group_started=true
else
  "$@" &
fi
command_pid=$!
wait "${command_pid}"
command_status=$?
set -e

trap - INT TERM HUP
exit "${command_status}"
