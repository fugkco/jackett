#!/usr/bin/env sh

set -eux

# if first arg looks like a flag, assume we want to run tvheadend server
if [ "${1:0:1}" = '-' ]; then
  set -- /jackett/jackett "$@"
fi

# disable log file
[ ! -L /config/log.txt ] && rm -f /config/log.txt && ln -fs /dev/null /config/log.txt

exec "$@"
