# Baikal

[![Latest images](https://github.com/anmutech/baikal-docker/actions/workflows/build-latest.yaml/badge.svg)](https://github.com/anmutech/baikal-docker/actions/workflows/build-latest.yaml) [![Experimental images](https://github.com/anmutech/baikal-docker/actions/workflows/build-experimental.yaml/badge.svg)](https://github.com/anmutech/baikal-docker/actions/workflows/build-experimental.yaml) ![Docker Pulls](https://img.shields.io/docker/pulls/anmutech/baikal) ![Docker Architectures](https://img.shields.io/badge/arch-amd64%20%7C%20arm32v7%20%7C%20arm64v8%20%7C%20i386-informational)

This dockerfile provides a ready-to-go [Baïkal server](http://sabre.io/baikal/).

For more details, see [anmutech/baikal-docker (GitHub)](https://github.com/anmutech/baikal-docker).

## Supported tags and respective Dockerfile links

Tags without a version are [weekly re-builds](https://github.com/anmutech/baikal-docker/actions/workflows/build-latest.yaml) to include the latest base image with the most recent updates:

- `latest` and `apache` are re-builds of the latest `*-apache` version
- `apache-php8.3` are re-builds of the latest `*-apache-php8.3` version
- `nginx` are re-builds of the latest `*-nginx` version
- `nginx-php8.3` are re-builds of the latest `*-nginx-php8.3` version

I follow the same version naming scheme as [Baïkal](http://sabre.io/baikal/) themselves.

The following tags support multiple architectures, e.g. `amd64`, `arm32v7`, `arm64v8` and `i386`.
Previous versions by ckulka:

- [`0.10.1`, `0.10.1-apache`](https://github.com/ckulka/baikal-docker/blob/0.10.1+hafix/apache.dockerfile)
- [`0.10.1-apache-php8.2`, `0.10.1-php8.2`](https://github.com/ckulka/baikal-docker/blob/0.10.1+hafix/apache-php8.2.dockerfile)
- [`0.10.1-nginx`](https://github.com/ckulka/baikal-docker/blob/0.10.1+hafix/nginx.dockerfile)
- [`0.10.1-nginx-php8.2`](https://github.com/ckulka/baikal-docker/blob/0.10.1+hafix/nginx-php8.2.dockerfile)
- [`0.10.0`, `0.10.0-apache`](https://github.com/ckulka/baikal-docker/blob/0.10.0/apache.dockerfile)
- [`0.10.0-apache-php8.2`, `0.10.0-php8.2`](https://github.com/ckulka/baikal-docker/blob/0.10.0/apache-php8.2.dockerfile)
- [`0.10.0-nginx`](https://github.com/ckulka/baikal-docker/blob/0.10.0/nginx.dockerfile)
- [`0.10.0-nginx-php8.2`](https://github.com/ckulka/baikal-docker/blob/0.10.0/nginx-php8.2.dockerfile)
- [`0.9.5`, `0.9.5-apache`](https://github.com/ckulka/baikal-docker/blob/0.9.5/apache.dockerfile)
- [`0.9.5-apache-php8.2`, `0.9.5-php8.2`](https://github.com/ckulka/baikal-docker/blob/0.9.5/apache-php8.2.dockerfile)
- [`0.9.5-nginx`](https://github.com/ckulka/baikal-docker/blob/0.9.5/nginx.dockerfile)
- [`0.9.5-nginx-php8.2`](https://github.com/ckulka/baikal-docker/blob/0.9.5/nginx-php8.2.dockerfile)

For earlier versions all the way back to version 0.2.7, please search in the [ckulka tags](https://hub.docker.com/r/ckulka/baikal/tags) tab. Version 0.4.5 and older are only available for `amd64`. Version 0.9.0 and older do not support `i386`.

## Quick reference

- **Where to file issues**:
  [https://github.com/anmutech/baikal-docker/issues](https://github.com/anmutech/baikal-docker/issues)
- **Supported architectures** ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64)):
  `amd64`, `arm32v7`, `arm64v8`, `i386`
- **Image updates**:
  [PRs for anmutech/baikal-docker](https://github.com/anmutech/baikal-docker/pulls)
- **Source of this description**:
  [https://github.com/anmutech/baikal-docker](https://github.com/anmutech/baikal-docker)

## What is Baikal?

From [sabre.io/baikal](http://sabre.io/baikal/):

> Baïkal is a lightweight CalDAV+CardDAV server.
> It offers an extensive web interface with easy management of users, address books and calendars.
> It is fast and simple to install and only needs a basic php capable server.
> The data can be stored in a MySQL, a PostgreSQL or an SQLite database.
> Baïkal allows to seamlessly access your contacts and calendars from every device.
> It is compatible with iOS, Mac OS X, DAVx5 on Android, Mozilla Thunderbird and every other CalDAV and CardDAV capable application.
> Protect your privacy by hosting calendars and contacts yourself - with Baïkal.
> Baïkal is free and [open-source](https://github.com/sabre-io/Baikal), developed by [Net Gusto](http://netgusto.com) and [fruux](fruux.com) together with many [contributors](https://github.com/sabre-io/Baikal/graphs/contributors).
> It is released under the GNU GPL v3 license.
> Baïkal is powered by sabre/dav, while offering an administrative interface for easy management.

## How to use this image

The following command will start Baïkal:

```bash
docker run --rm -it -p 80:80 anmutech/baikal:nginx
```

Alternatively, use the provided [examples/docker-compose.yaml](https://github.com/anmutech/baikal-docker/blob/master/examples/docker-compose.yaml) from the Git repository:

```bash
docker compose up
```

You can now open [http://localhost](http://localhost) or [http://host-ip](http://host-ip) in your browser and use Baïkal.

### Persistent Data

The image exposes the `/var/www/baikal/Specific` and `/var/www/baikal/config` folders, which contain the persistent data. These folders should be part of a regular backup.

If you want to use local folders instead of Docker volumes, see [examples/docker-compose.localvolumes.yaml](https://github.com/anmutech/baikal-docker/blob/master/examples/docker-compose.localvolumes.yaml) to avoid file permission issues.

When the container starts, the startup script `/docker-entrypoint.d/40-fix-baikal-file-permissions.sh` ([Apache httpd](https://github.com/anmutech/baikal-docker/blob/master/files/docker-entrypoint.d/httpd/40-fix-baikal-file-permissions.sh), [nginx](https://github.com/anmutech/baikal-docker/blob/master/files/docker-entrypoint.d/nginx/40-fix-baikal-file-permissions.sh)) ensures that the file permissions are correct. You can disable this behaviour by setting the environment variable `BAIKAL_SKIP_CHOWN` to any value, e.g. `FALSE`.

### Further Guides

You can find more installation and configuration guides here:

- [Email Guide](https://github.com/anmutech/baikal-docker/blob/master/docs/email-guide.md)
- [Home Assistant Fix](https://github.com/anmutech/baikal-docker/blob/master/docs/home-assistant-fix.md)
- [SSL Certificate Guide](https://github.com/anmutech/baikal-docker/blob/master/docs/ssl-certificates-guide.md)
- [systemd Guide](https://github.com/anmutech/baikal-docker/blob/master/docs/systemd-guide.md)
- [Unraid Installation Guide](https://github.com/anmutech/baikal-docker/blob/master/docs/unraid-installation-guide.md)

## Image Variants

The `anmutech/baikal` images come in several flavors, each designed for a specific use case.

### `anmutech/baikal:<version>`

This is the defacto image and follows the official guidelines the closest using Apache httpd.

With that being said, it's worth checking out the `nginx` variant as it requires fewer resources and produces no warning messages out-of-the-box.

If you are unsure about what your needs are, you probably want to use this one though.

### `anmutech/baikal:apache`

This image relies on Apache httpd and uses the [official PHP image](https://hub.docker.com/_/php/) that's packaged with the Apache web server.

It also ships with HTTPS support and self-signed certificates, which can be replaced by user-provided certificates - for more details, see the [SSL Certificate Guide](https://github.com/anmutech/baikal-docker/blob/master/docs/ssl-certificates-guide.md).

This image uses environment variables to set Apache's `ServerName` and `ServerAlias` directives to avoid Apache httpd's warnings in the logs.

The `BAIKAL_SERVERNAME` environment variable is used to set the global `ServerName` directive, e.g. `dav.example.io`. For more details, see [Apache Core Features: ServerName Directive](https://httpd.apache.org/docs/2.4/mod/core.html#servername).

The `BAIKAL_SERVERALIAS` environment variable is used to set the `ServerAlias` directive of the `VirtualHost`s, e.g. `dav.example.org dav.example.com`. For more details, see [Apache Core Features: ServerAlias Directive](https://httpd.apache.org/docs/2.4/mod/core.html#serveralias).

### `anmutech/baikal:experimental`

This image has the latest code from the source repository [anmutech/baikal-docker](https://github.com/anmutech/baikal-docker), mainly used for testing before a version is released. Use this at your own risk.

### `anmutech/baikal:nginx`

This image relies on [nginx](https://www.nginx.com/) and uses the [official nginx image](https://hub.docker.com/_/nginx/).

Compared to the Apache variant, it is significantly smaller (less than half the size) and produces no warning messages out-of-the-box.
