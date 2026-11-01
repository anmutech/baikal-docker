#!/bin/sh

set -e
ME=$(basename $0)

# Exit if Home Assistant fix not enabled
if [ -z ${APPLY_HOME_ASSISTANT_FIX+x} ] || [ "$APPLY_HOME_ASSISTANT_FIX" != "true" ]
then
  exit 0
fi

TARGET="/var/www/baikal/vendor/sabre/dav/lib/CalDAV/Plugin.php"

if [ ! -f "$TARGET" ]
then
  echo "$ME: FAIL: $TARGET not found"
  exit 1
fi

# The Home Assistant fix: sabre/dav parses a calendar's VTIMEZONE into a
# DateTimeZone object, which older PHP/vobject versions handle badly; instead
# construct the DateTimeZone directly from the timezone string.
# We edit the packaged file in place (granular, idempotent), rather than
# replacing the whole file, so any other local modifications are preserved.
# The edit only applies if the exact original block is present exactly once.
OLD_TEXT=$(cat <<'OLD_BLOCK'
            if (isset($tzResult[$tzProp])) {
                // This property contains a VCALENDAR with a single
                // VTIMEZONE.
                $vtimezoneObj = VObject\Reader::read($tzResult[$tzProp]);
                $calendarTimeZone = $vtimezoneObj->VTIMEZONE->getTimeZone();

                // Destroy circular references so PHP will garbage collect the
                // object.
                $vtimezoneObj->destroy();
            } else {
                // Defaulting to UTC.
                $calendarTimeZone = new DateTimeZone('UTC');
            }
OLD_BLOCK
)

NEW_TEXT=$(cat <<'NEW_BLOCK'
            if (isset($tzResult[$tzProp])) {
                // This property contains a VCALENDAR with a single
                // VTIMEZONE.
                //$vtimezoneObj = VObject\Reader::read($tzResult[$tzProp]);
                //$calendarTimeZone = $vtimezoneObj->VTIMEZONE->getTimeZone();

                // Destroy circular references so PHP will garbage collect the
                // object.
                //$vtimezoneObj->destroy();
                // Home Assistant Fix
                $calendarTimeZone = new DateTimeZone($tzResult[$tzProp]);
            } else {
                // Defaulting to UTC.
                $calendarTimeZone = new DateTimeZone('UTC');
            }
NEW_BLOCK
)

# --- Count exact occurrences --------------------------------
count=$(OLD_TEXT="$OLD_TEXT" awk '
BEGIN { old = ENVIRON["OLD_TEXT"] }
{ buf = buf $0 "\n" }
END {
    c = 0; pos = 1
    while (1) {
        i = index(substr(buf, pos), old)
        if (i == 0) break
        c++
        pos += i - 1 + length(old)
    }
    print c
}' "$TARGET")

case "$count" in
  0)
    # Either the fix is already applied, or the file was customized such that
    # the original block no longer matches. We cannot tell which, so treat it
    # as already handled instead of aborting container start.
    echo "$ME: info: original code block not found in Plugin.php; the Home Assistant fix is either already applied or the file was customized — nothing to do"
    exit 0
    ;;
  1)
    ;;
  *)
    echo "$ME: FAIL: original code block found $count times in Plugin.php; need exactly 1 — the file was likely customized, so we won't modify it. Please apply the Home Assistant fix manually."
    exit 1
    ;;
esac

# --- Replace -------------------------------------------------
TMP="${TARGET}.tmp.$$"
OLD_TEXT="$OLD_TEXT" NEW_TEXT="$NEW_TEXT" awk -v out="$TMP" '
BEGIN {
    old = ENVIRON["OLD_TEXT"]
    new = ENVIRON["NEW_TEXT"]
}
{ buf = buf $0 "\n" }
END {
    pos = index(buf, old)
    result = substr(buf, 1, pos - 1) new substr(buf, pos + length(old))
    printf "%s", result > out
    close(out)
}' "$TARGET"

mv "$TMP" "$TARGET"
echo "$ME: info: Applied Home Assistant fix to Plugin.php"
