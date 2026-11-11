#!/bin/sh
# Verify that Baikal's data volumes are writable by the container's runtime
# user BEFORE the web server boots. This works under any `docker run --user
# <uid>:<gid>`, not just the default nginx (101).
# For all users, except root, the user cannot chown files it does not own.
# Failing fast at boot gives the user the exact host-side remedy.

ME=$(basename "$0")
BAIKAL_ROOT="${BAIKAL_ROOT:-/var/www/baikal}"
RUN_USER="$(id -un 2>/dev/null || echo unknown)"
RUN_UID="$(id -u 2>/dev/null || echo '?')"
RUN_GID="$(id -g 2>/dev/null || echo '?')"
FAILED=""

for dir in config Specific
do
  D="$BAIKAL_ROOT/$dir"
  if [ ! -d "$D" ]
  then
    FAILED="$FAILED $D (missing)"
    continue
  fi
  PROBE="$D/.writability-check.$$"
  if ! touch "$PROBE" 2>/dev/null
  then
    rm -f "$PROBE" 2>/dev/null
    FAILED="$FAILED $D (not writable by $RUN_USER)"
    continue
  fi
  rm -f "$PROBE"
done

# This image cannot chown (non-root), so the flag can never do real work.
if [ -n "${BAIKAL_ENABLE_CHOWN:-}" ]
then
  echo "$ME: WARN: BAIKAL_ENABLE_CHOWN is not supported in the unprivileged image; a non-root user cannot chown files it does not own, so the variable is ignored (value: $BAIKAL_ENABLE_CHOWN)"
fi

if [ -n "$FAILED" ]
then
  echo "$ME: FAIL: Baikal data volume(s) not writable by $RUN_USER (uid=$RUN_UID gid=$RUN_GID):$FAILED"
  echo "$ME: Fix this ON THE HOST before starting the container. Two options:"
  echo "$ME:   1. Match host ownership to the container's runtime user:"
  echo "$ME:        chown -R $RUN_UID:$RUN_GID <host path mounted at /var/www/baikal/config>"
  echo "$ME:        chown -R $RUN_UID:$RUN_GID <host path mounted at /var/www/baikal/Specific>"
  echo "$ME:        (running as the default 'nginx' user = 101, or whatever you pass via --user)"
  echo "$ME:   2. Or run the container as a host user that already owns the dirs:"
  echo "$ME:        docker run --user <uid>:<gid> ..."
  exit 1
fi

exit 0
