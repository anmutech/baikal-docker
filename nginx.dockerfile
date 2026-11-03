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
FROM nginx:1
ARG PHP_VERSION

# Install dependencies: PHP (with libffi6 dependency) & SQLite3
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
  sed -i 's/www-data/nginx/' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf &&\
  sed -i 's/^listen = .*/listen = \/var\/run\/php-fpm.sock/' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

# Add Baikal & nginx configuration
ENV BAIKAL_VOLUME_OWNER=nginx:nginx
COPY files/docker-entrypoint.d/*.sh files/docker-entrypoint.d/*.php files/docker-entrypoint.d/nginx/ /docker-entrypoint.d/
COPY --from=builder --chown=nginx:nginx baikal /var/www/baikal
COPY files/nginx.conf /etc/nginx/conf.d/default.conf

VOLUME /var/www/baikal/config
VOLUME /var/www/baikal/Specific
