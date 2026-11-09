#!/bin/sh

# Based on /etc/docker-entrypoint.d/10-listen-on-ipv6-by-default.sh, since the
# same one cannot be used because the checksum of the default.conf differs.

set -e
ME=$(basename $0)

# Disable IPv6 configuration if not supported or nginx is not installed
# Added to resolve https://github.com/ckulka/baikal-docker/issues/73
# Updated to use same ipv6 availability check as nginx entrypoint script 10-listen-on-ipv6-by-default.sh
if [ ! -f "/proc/net/if_inet6" ]; then
    echo "$ME: info: Disable IPv6 in configuration"
    sed -i 's/listen \[::\]:8080;/# listen \[::\]:8080/' /etc/nginx/conf.d/default.conf
fi
