#!/bin/sh

# Ensure correct file permissions if flag is set
if [ ! -z ${BAIKAL_ENABLE_CHOWN+x} ]
then
  # chown only volumes sitting inside the baikal install
  grep -E " /var/www/baikal/" /proc/self/mountinfo |
  while read -r _ _ _ _ mnt _; do
      chown -R www-data:www-data "$mnt"
  done
fi
