#!/bin/sh

# Former flag was set, warn about the change
if [ -n "${BAIKAL_SKIP_CHOWN:-}" ]
then
  echo "$ME: WARN: legacy flag BAIKAL_SKIP_CHOWN is no longer supported (value: ${BAIKAL_SKIP_CHOWN}) and is ignored;"
fi

echo "$ME: WARN: skipping chown is default behaviour; you can enable chown by setting BAIKAL_ENABLE_CHOWN=true"

# Ensure correct file permissions if flag is set
if [ ! -z ${BAIKAL_ENABLE_CHOWN+x} ]
then
  # chown only volumes sitting inside the baikal install
  grep -E " /var/www/baikal/" /proc/self/mountinfo |
  while read -r _ _ _ _ mnt _; do
      chown -R www-data:www-data "$mnt"
  done
fi
