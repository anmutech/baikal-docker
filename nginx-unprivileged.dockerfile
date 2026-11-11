# Multi-stage build, see https://docs.docker.com/develop/develop-images/multistage-build/
#
# Versions: this Dockerfile has NO defaults for BAIKAL_VERSION / PHP_VERSION.
# The caller must always pass them, e.g.:
#   docker build \
#     --build-arg BAIKAL_VERSION=<value> \
#     --build-arg PHP_VERSION=<value> \
#     -f nginx.dockerfile -t baikal:nginx .
# versions.env at the repo root is the single edit point for the values this
# project ships.

FROM alpine AS builder
ARG BAIKAL_VERSION

ADD https://github.com/sabre-io/Baikal/releases/download/$BAIKAL_VERSION/baikal-$BAIKAL_VERSION.zip .
RUN apk add unzip && unzip -q baikal-$BAIKAL_VERSION.zip

# Final Docker image
FROM nginx/nginx-unprivileged:1
ARG PHP_VERSION

# Install dependencies: PHP (with libffi6 dependency) & SQLite3
USER root
RUN curl -o /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg &&\
  apt update                  &&\
  apt install -y lsb-release  &&\
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list &&\
  apt remove -y lsb-release   &&\
  apt update                  &&\
    apt install -y            \
    php${PHP_VERSION}-curl    \
    php${PHP_VERSION}-fpm     \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-mysql   \
    php${PHP_VERSION}-pgsql   \
    php${PHP_VERSION}-sqlite3 \
    php${PHP_VERSION}-xml     \
    sqlite3                   \
    msmtp msmtp-mta           &&\
  rm -rf /var/lib/apt/lists/* &&\
  # Socket and pid go to /tmp (world-writable 1777 in all Debian images)
  sed -i 's/^listen = .*/listen = \/tmp\/php-fpm.sock/' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf &&\
  # Any-UID support: delete pool directives (user/group and listen.owner/group)
  # FPM inherits the user and group of the runner.
  sed -i -E '/^(user|group|listen\.owner|listen\.group)[[:space:]]*=/d' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf &&\
  # Unprivileged nginx cannot connect to fpm, unless socket is world-writable.
  # 0666 works in every case: root FPM, any-UID FPM.
  echo 'listen.mode = 0666' >> /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf &&\
  # Fixed-path mail: Use the absolute msmtp path and a fixed 0600 config written at
  # boot by 50-start-msmtp.sh (which holds the contents of $MSMTPRC).
  echo 'php_admin_value[sendmail_path] = "/usr/bin/msmtp --file=/tmp/msmtprc -t -i"' >> /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf &&\
  # Error log: symlink to /dev/stderr (same pattern as the base nginx image
  # for /var/log/nginx/error.log), so it lands in docker logs.
  ln -sf /dev/stderr /var/log/php${PHP_VERSION}-fpm.log &&\
  # pid in /tmp (1777, any runner can write).
  sed -i 's|^pid = .*|pid = /tmp/php-fpm.pid|' /etc/php/${PHP_VERSION}/fpm/php-fpm.conf

# Add Baikal & nginx configuration
COPY files/docker-entrypoint.d/*.sh files/docker-entrypoint.d/*.php files/docker-entrypoint.d/nginx-unprivileged/ /docker-entrypoint.d/
COPY --from=builder --chown=nginx:nginx baikal /var/www/baikal
# Any-UID support: CalDAV directory must be world-writable for Home Assistant fix.
RUN chmod 777 /var/www/baikal/vendor/sabre/dav/lib/CalDAV
COPY files/nginx-unprivileged.conf /etc/nginx/conf.d/default.conf
# Any-UID support: 40-disable-nginx-ipv6-if-unsupported.sh does `sed -i` on
# /etc/nginx/conf.d/default.conf at runtime; sed -i creates a temp file in
# the SAME directory, so the directory and file must be world-writable.
RUN chmod 777 /etc/nginx/conf.d && chmod 666 /etc/nginx/conf.d/default.conf

VOLUME /var/www/baikal/config
VOLUME /var/www/baikal/Specific
ENV UNPRIVILEGED=true
USER nginx
