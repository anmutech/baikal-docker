#!/bin/sh
# Verify that Baikal's data volumes are writable by the unprivileged image
# user BEFORE the web server boots.
#
# A host directory that is owned by someone else cannot be fixed from inside
# the container: a non-root user cannot chown files it does not own (the old
# BAIKAL_ENABLE_CHOWN path therefore does not work in this image and has been
# removed). Failing fast at boot gives the user the exact host-side remedy
# instead of a 500 error later in the init wizard.
#
# The official nginx entrypoint runs this under `set -e`, so the `exit 1`
# below aborts container startup with the diagnostics above.

ME=$(basename "$0")
BAIKAL_ROOT="${BAIKAL_ROOT:-/var/www/baikal}"
RUN_USER="$(id -un 2>/dev/null || echo unknown)"
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
  echo "$ME: FAIL: Baikal data volume(s) not writable by $RUN_USER:$FAILED"
  echo "$ME: Fix this ON THE HOST before starting the container, e.g.:"
  echo "$ME:   chown -R 101:101 <host path mounted at /var/www/baikal/config>"
  echo "$ME:   chown -R 101:101 <host path mounted at /var/www/baikal/Specific>"
  echo "$ME: (101 is the UID of the 'nginx' user this image runs as)"
  exit 1
fi

exit 0
