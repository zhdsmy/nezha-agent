#!/bin/sh
set -eu

CONFIG_FILE="${NEZHA_AGENT_CONFIG:-/etc/nezha-agent/config.yml}"

if [ "$#" -gt 0 ]; then
  exec "$@"
fi

if [ -n "${NEZHA_AGENT_ARGS:-}" ]; then
  set -f
  # shellcheck disable=SC2086
  set -- ${NEZHA_AGENT_ARGS}
  set +f
fi

exec /usr/bin/nezha-agent -c "${CONFIG_FILE}" "$@"
