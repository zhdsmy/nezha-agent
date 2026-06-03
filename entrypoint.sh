#!/bin/sh
set -eu

CONFIG_FILE="${NEZHA_AGENT_CONFIG:-/etc/nezha-agent/config.yml}"

if [ "$#" -gt 0 ]; then
  exec "$@"
fi

# shellcheck disable=SC2086
exec /usr/bin/nezha-agent -c "${CONFIG_FILE}" ${NEZHA_AGENT_ARGS:-}
