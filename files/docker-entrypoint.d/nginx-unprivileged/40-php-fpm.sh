#!/bin/sh

# Start PHP-FPM directly, not via the package's init script.
# The socket and pid are in /tmp, the error log is symlinked to
# /dev/stderr.
#
# `--allow-to-run-as-root` (when running as uid 0, e.g. rootless Docker)
# The pool's `user`/`group` directives are deleted to support any UID.
# FPM master running as root refuses to boot without this flag.
# Workers keep uid 0, matching the volume owner (the host user behind rootless '0').
set -e
ME=$(basename "$0")

FPM_BIN=$(ls /usr/sbin/php-fpm* 2>/dev/null | head -n1)
if [ -z "$FPM_BIN" ]; then
  echo "$ME: ERROR: no php-fpm binary found in /usr/sbin" >&2
  exit 1
fi
FPM_CONF=$(ls -d /etc/php/*/fpm/php-fpm.conf 2>/dev/null | head -n1)
if [ -z "$FPM_CONF" ]; then
  echo "$ME: ERROR: no php-fpm.conf found under /etc/php" >&2
  exit 1
fi

FPM_ARGS=""
if [ "$(id -u)" = "0" ]
then
  echo "$ME: WARNING: nginx workers can write to root owned fpm socket!"
  echo "$ME: WARNING: be sure that your runtime is rootless, don't expose to the internet!"
  FPM_ARGS="--allow-to-run-as-root"
fi

# $FPM_ARGS is intentionally unquoted (empty or exactly one token).
"$FPM_BIN" --daemonize $FPM_ARGS --fpm-config "$FPM_CONF"
