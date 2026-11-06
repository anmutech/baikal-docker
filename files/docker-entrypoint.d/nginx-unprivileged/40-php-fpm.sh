#!/bin/sh

# Start PHP-FPM directly, not via the package's init script:
#  * the sury init script's start action first runs
#    `systemd-tmpfiles --remove --create /usr/lib/tmpfiles.d/php*-fpm.conf`
#    to build /run/php owned by www-data. As the non-root `nginx` user that
#    mkdir/chown fails (EACCES), and the script then *skips do_start()* and
#    exits 0 — PHP-FPM silently never runs, leaving the FastCGI socket
#    missing (nginx: [crit] connect() to unix:… failed).
#  * the init script's name (php8.5-fpm) differs from the binary
#    (php-fpm8.5), so a find-glob can silently match nothing (find with no
#    matches exits 0).
# All state paths are pre-created and owned by `nginx` in the Dockerfile
# (pid /var/lib/php-fpm/php-fpm.pid, socket /var/lib/php-fpm/php-fpm.sock,
# error_log /var/log/php<ver>-fpm.log), so a non-root daemon works here.
# With `set -e`, a failed start aborts the container loudly instead of
# serving a broken app.
set -e

FPM_BIN=$(ls /usr/sbin/php-fpm* 2>/dev/null | head -n1)
if [ -z "$FPM_BIN" ]; then
  echo "ERROR: no php-fpm binary found in /usr/sbin" >&2
  exit 1
fi
FPM_CONF=$(ls -d /etc/php/*/fpm/php-fpm.conf 2>/dev/null | head -n1)
if [ -z "$FPM_CONF" ]; then
  echo "ERROR: no php-fpm.conf found under /etc/php" >&2
  exit 1
fi

"$FPM_BIN" --daemonize --fpm-config "$FPM_CONF"
