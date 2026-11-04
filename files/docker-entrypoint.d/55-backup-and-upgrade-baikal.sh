#!/bin/sh

# Opt in with (exactly the value "true" enables each):
#   AUTO_UPGRADE_DB=true          perform the automatic database upgrade
#   BACKUP_BEFORE_UPGRADE=true    create a timestamped backup of
#                                 /var/www/baikal/config/ and /var/www/baikal/Specific/,
#                                 written INSIDE each respective directory
#                                 (they are volumes, so the user can access them
#                                 from the host), before the upgrade
# Combinations:
#   both true                  backup, then upgrade
#   AUTO_UPGRADE_DB only       upgrade without a backup
#   BACKUP_BEFORE_UPGRADE only backup only; the upgrade itself is left to the user
#
# This is a hack, not an officially supported Baikal workflow: it drives
# Baikal's upgrade code out-of-band, so each action must be explicitly enabled.
#
# A backup and/or upgrade only happens when the Baikal version in the container
# (Core/Distrib.php) is newer than the version recorded in config/baikal.yaml
# (system.configured_version).
#
# Runs BEFORE the web server starts. On success the container proceeds
# normally; on upgrade failure the container is aborted by the `set -e` in
# /docker-entrypoint.sh, so Baikal never starts half-migrated.
#
# Every exit path prints a reason line, so container logs show what happened.

set -e
ME=$(basename $0)

echo "$ME: check: AUTO_UPGRADE_DB=${AUTO_UPGRADE_DB:-<unset>} BACKUP_BEFORE_UPGRADE=${BACKUP_BEFORE_UPGRADE:-<unset>}"

# The former single flag is gone. If it is still set, warn and ignore it.
if [ -n "${AUTO_BACKUP_AND_UPGRADE:-}" ]
then
  echo "$ME: WARN: legacy flag AUTO_BACKUP_AND_UPGRADE is no longer supported (value: ${AUTO_BACKUP_AND_UPGRADE}) and is ignored; use AUTO_UPGRADE_DB=true and/or BACKUP_BEFORE_UPGRADE=true instead"
fi

UPGRADE=0
if [ "${AUTO_UPGRADE_DB:-}" = "true" ]
then
  UPGRADE=1
fi
BACKUP=0
if [ "${BACKUP_BEFORE_UPGRADE:-}" = "true" ]
then
  BACKUP=1
fi

# Exit unless at least one action is enabled
if [ "$UPGRADE" -eq 0 ] && [ "$BACKUP" -eq 0 ]
then
  echo "$ME: SKIP: automatic backup + upgrade not enabled; to enable it set AUTO_UPGRADE_DB=true (upgrade) and/or BACKUP_BEFORE_UPGRADE=true (backup) (this is a non-official Baikal workflow; a pending database upgrade, if any, must otherwise be done through the web wizard)"
  exit 0
fi

BAIKAL_ROOT="${BAIKAL_ROOT:-/var/www/baikal}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HARNESS="$SCRIPT_DIR/baikal-cli-upgrade.php"

BAIKAL_CONFIG_FILE="$BAIKAL_ROOT/config/baikal.yaml"

# --- Detect a potentially pending upgrade before touching anything ---
# Compare the version shipped in the container (Core/Distrib.php:
# define("BAIKAL_VERSION", "...")) with the version recorded in
# config/baikal.yaml (system.configured_version). Only if the container is
# newer a database upgrade might be pending.
# Outcome: 
#   PENDING (continue, then backup + upgrade)
#   UPTODATE or NOVERSION (exit 0 - nothing done) 
#   FAIL (exit 0 - cannot determine a version)
DISTRIB_FILE="$BAIKAL_ROOT/Core/Distrib.php"
if [ ! -f "$DISTRIB_FILE" ]
then
  echo "$ME: FAIL: $DISTRIB_FILE not found; cannot determine the container Baikal version"
  exit 0
fi
# Container version, the line in Distrib.php is
#   define("BAIKAL_VERSION", "x.y.z");
CONTAINER_VERSION="$(sed -nE 's%.*define[[:space:]]*\([[:space:]]*"BAIKAL_VERSION"[[:space:]]*,[[:space:]]*"([^"]+)".*%\1%p' "$DISTRIB_FILE" | head -n1)"
if [ -z "$CONTAINER_VERSION" ]
then
  echo "$ME: FAIL: could not extract BAIKAL_VERSION from $DISTRIB_FILE"
  exit 0
fi

# Configured version from config/baikal.yaml ("    configured_version: x.y.z")
CONFIGURED_VERSION=""
if [ -f "$BAIKAL_CONFIG_FILE" ]
then
  CONFIGURED_VERSION="$(sed -nE 's%^[[:space:]]*configured_version[[:space:]]*:([^#]*).*%\1%p' "$BAIKAL_CONFIG_FILE" | head -n1 \
    | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/^"//; s/"$//')"
fi
if [ -z "$CONFIGURED_VERSION" ]
then
  echo "$ME: NOVERSION: no system.configured_version in $BAIKAL_CONFIG_FILE (fresh install or install wizard pending); no backup, no upgrade"
  exit 0
fi

# Compare
LOWEST_VERSION="$(printf '%s\n%s\n' "$CONTAINER_VERSION" "$CONFIGURED_VERSION" | sort -V | head -n1)"
if [ "$LOWEST_VERSION" != "$CONTAINER_VERSION" ]
then
  echo "$ME: PENDING $CONFIGURED_VERSION -> $CONTAINER_VERSION; a database upgrade might be pending (backup: $([ "$BACKUP" -eq 1 ] && echo enabled || echo disabled), automatic upgrade: $([ "$UPGRADE" -eq 1 ] && echo enabled || echo disabled))"
else
  echo "$ME: UPTODATE $CONFIGURED_VERSION (container Baikal version is $CONTAINER_VERSION); no backup, no upgrade"
  exit 0
fi

# --- Backup before upgrade (only if requested) ---
# Each archive is written INSIDE the directory it backs up (a volume, so the
# user can access it from the host), and every file matching
# *-backup-*.tar.gz is excluded, so a backup never contains earlier backups.
# The archive is created OUTSIDE the directory first and moved in afterwards:
# tar exits 1 ("file changed as we read it") if the output file is created
# inside the very directory it is reading.
# The entrypoint runs as root, so the archive ends up root:root; chown it to
# the image's web server user (BAIKAL_VOLUME_OWNER, set by the dockerfile) so
# the backup matches the ownership of the config and Specific trees.
if [ "$BACKUP" -eq 1 ]
then
  TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
  BACKED_UP=""
  for dir in config Specific
  do
    if [ -d "$BAIKAL_ROOT/$dir" ]
    then
      ARCHIVE="$BAIKAL_ROOT/$dir/$dir-backup-$TIMESTAMP.tar.gz"
      TMP_ARCHIVE="$(mktemp)"
      if tar -C "$BAIKAL_ROOT/$dir" -czf "$TMP_ARCHIVE" --exclude='*-backup-*.tar.gz' .
      then
        mv "$TMP_ARCHIVE" "$ARCHIVE"
        chmod 644 "$ARCHIVE"
        OWNER="${BAIKAL_VOLUME_OWNER:-www-data:www-data}"
        if id "${OWNER%%:*}" 2>/dev/null
        then
          chown "$OWNER" "$ARCHIVE"
          echo "$ME: created backup $ARCHIVE (owner: $OWNER)"
        else
          echo "$ME: created backup $ARCHIVE (owner: root — BAIKAL_VOLUME_OWNER='$OWNER' references an unknown user here)"
        fi
        BACKED_UP="$BACKED_UP $dir"
      else
        rm -f "$TMP_ARCHIVE"
        echo "$ME: FAIL: could not create backup for $dir"
        exit 0
      fi
    else
      echo "$ME: note: $BAIKAL_ROOT/$dir does not exist; skipping it"
    fi
  done

  if [ -z "$BACKED_UP" ]
  then
    echo "$ME: note: nothing backed up — fresh install? Exit out, potentially requires user interaction"
    exit 0
  fi
else
  echo "$ME: note: BACKUP_BEFORE_UPGRADE is not set to 'true'; no backup will be created"
fi

# Backup-only mode: no automatic upgrade was requested
if [ "$UPGRADE" -eq 0 ]
then
  echo "$ME: OK: backup only; automatic upgrade is not enabled (AUTO_UPGRADE_DB is not 'true'), performing the upgrade is left to the user (web wizard, or re-run with AUTO_UPGRADE_DB=true)"
  exit 0
fi

# --- Database upgrade ---
# php is present in every image: apache bundles it, and
# php-fpm (in nginx images) depends on php-cli.
PHP_BIN="$(command -v php)" || true
if [ -z "$PHP_BIN" ]
then
  echo "$ME: FAIL: php executable not found; cannot perform the database upgrade"
  exit 0
fi

# The CLI upgrade harness (ships next to this script)
if [ ! -f "$HARNESS" ]
then
  echo "$ME: FAIL: $HARNESS not found"
  exit 0
fi

echo "$ME: running database upgrade"
BAIKAL_ROOT="$BAIKAL_ROOT" \
BAIKAL_PATH_CONFIG="$BAIKAL_ROOT/config/" \
BAIKAL_PATH_SPECIFIC="$BAIKAL_ROOT/Specific/" \
"$PHP_BIN" "$HARNESS"

echo "$ME: OK: database upgrade finished without error"
