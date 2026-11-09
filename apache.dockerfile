# Multi-stage build, see https://docs.docker.com/develop/develop-images/multistage-build/
#
# Versions: this Dockerfile has NO defaults for BAIKAL_VERSION / PHP_VERSION.
# The caller must always pass them, e.g.:
#   docker build \
#     --build-arg BAIKAL_VERSION=<value> \
#     --build-arg PHP_VERSION=<value> \
#     -f apache.dockerfile -t baikal:apache .
# versions.env at the repo root is the single edit point for the values this
# project ships.

# Global build arg, usable by the FROM line for the final image
ARG PHP_VERSION

FROM alpine AS builder
ARG BAIKAL_VERSION

ADD https://github.com/sabre-io/Baikal/releases/download/$BAIKAL_VERSION/baikal-$BAIKAL_VERSION.zip .
RUN apk add unzip && unzip -q baikal-$BAIKAL_VERSION.zip

# Final Docker image
FROM php:${PHP_VERSION}-apache

# Install Baikal and required dependencies
COPY --from=builder --chown=www-data:www-data baikal /var/www/baikal
RUN apt-get update            &&\
  apt-get install -y          \
    libcurl4-openssl-dev      \
    msmtp msmtp-mta           \
    libpq-dev                 &&\
  rm -rf /var/lib/apt/lists/* &&\
  docker-php-ext-install curl pdo pdo_mysql pdo_pgsql pgsql

# Configure Apache + HTTPS
COPY files/apache.conf /etc/apache2/sites-enabled/000-default.conf
RUN a2enmod rewrite ssl && openssl req -x509 -newkey rsa:2048 -subj "/C=  " -keyout /etc/ssl/private/baikal.private.pem -out /etc/ssl/private/baikal.public.pem -days 3650 -nodes
RUN sed 's/expose_php = On/expose_php = Off/g' /usr/local/etc/php/php.ini-production > /usr/local/etc/php/php.ini

# Expose HTTPS & data directory
EXPOSE 443
VOLUME /var/www/baikal/config
VOLUME /var/www/baikal/Specific

COPY files/docker-entrypoint.sh /docker-entrypoint.sh
COPY files/docker-entrypoint.d/*.sh files/docker-entrypoint.d/*.php files/docker-entrypoint.d/httpd/ /docker-entrypoint.d/
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD  [ "apache2-foreground" ]
