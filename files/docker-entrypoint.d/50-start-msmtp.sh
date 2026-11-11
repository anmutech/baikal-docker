#!/bin/sh

# See https://github.com/ckulka/baikal-docker/discussions/61
set -e
ME=$(basename "$0")

# Insert sendmail mailer definitions
if [ ! -z ${MSMTPRC+x} ]
then
  if [ ! -z ${UNPRIVILEGED+x} ]
  then
    RC=/tmp/msmtprc
    echo "$MSMTPRC" > "$RC"
    chmod 644 "$RC"
  else
    RC=/etc/msmtprc
    echo "$MSMTPRC" > "$RC"
    chown root:msmtp "$RC"
    chmod 644 "$RC"
  fi
  echo "$ME: info: wrote msmtp config to $RC (sendmail_path: msmtp --file=$RC -t -i)"
  
else
  echo "$ME: info: no MSMTPRC set; mail disabled"
fi
