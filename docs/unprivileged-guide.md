# Unprivileged Image Guide

This guide covers the `anmutech/baikal:nginx-unprivileged` and `…-phpX` images.
They run all their processes as the **non-root user nginx** instead of starting out as root. It is functionally the same `nginx` image as the privileged variants, reworked so it works in environments where running containers as root is not desired. It also supports setting the user UID/GID.

- **No root processes inside the container** — a compromised container does not directly hand the attacker root.
- **Follows any uid/gid** — one `user:` line aligns FPM, nginx, and the data volumes, which is ideal for matching an existing host user.

> [!NOTE]
> If there is no requirement to use root inside the container, this image is the better choice over the `nginx` image. The privileged images (`apache`, `nginx`) run the container's entrypoint as root. This image never needs to.

See [examples/docker-compose.unprivileged.yaml](../examples/docker-compose.unprivileged.yaml) for a starter template.

## What changes compared to the privileged image

Everything used day-to-day (web interface, CalDAV/CardDAV, email, database) behaves the same. The differences are in **how the container runs**.

|                             | Privileged `nginx`                          | `nginx-unprivileged`                                                    |
| --------------------------- | ------------------------------------------- | ----------------------------------------------------------------------- |
| Runtime user                | root (drops to `nginx` for workers)         | non-root, default `nginx` (uid 101)                                     |
| Change runtime user         | **not possible**                            | possible ([Run as specific user](#running-as-a-specific-user))          |
| Listens on                  | `80`                                        | `8080`                                                                  |
| Correcting volume ownership | possible (opt-in via `BAIKAL_ENABLE_CHOWN`) | **not possible** (a non-root user cannot `chown` files it does not own) |

### Ports

The unprivileged image listens on **`8080`** inside the container. Map the preferred host port onto `8080`:

```yaml
# Shortened example docker-compose.yaml
services:
  baikal:
    image: anmutech/baikal:nginx-unprivileged
    ports:
      - "80:8080" # host:container — the host side can be anything
# For a production ready file see:
# https://github.com/anmutech/baikal-docker/examples/docker-compose.unprivileged.yaml
```

> [!NOTE]
> The compose healthcheck, if used, must connect to port `8080`.
> The healthcheck on other images requires connecting to port `80`.

### Volume ownership

> [!IMPORTANT]
> This is only relevant for the persistant data case, where volumes are bind mounted to directories. Users of normal volumes like in the [examples/docker-compose.unprivileged.yaml](../examples/docker-compose.unprivileged.yaml) can skip this section.

Because the container runs non-root, it **cannot `chown`** bind mounted `config` and `Specific` volumes the way the privileged image does when `BAIKAL_ENABLE_CHOWN` is set.
The directory ownership on the host must match the user the container runs as, **before** it is started.

On startup, `40-verify-volume-writability.sh` probes both data volumes, and if they are not writable it **fails** with an error message what needs to be fixed, and how.

Two ways to make it work:

1. **Match ownership to the default user.** The default runtime user is `nginx` (uid `101`). On the host:

   ```sh
   chown -R 101:101 ./config ./data
   ```

2. **Run as the host user that already owns the dirs.** Pick any uid/gid and tell the runtime to use it:

   ```yaml
   # docker-compose.yaml
   services:
     baikal:
       image: anmutech/baikal:nginx-unprivileged
       user: "1000:1000" # run as this host user; make sure the volumes are already owned by 1000
   ```

   The container's PHP-FPM and the Baïkal data all follow whichever user is passed, so a single `user:` line keeps everything consistent.

### Email, Backups, Upgrades, Home Assistant fix, Databases

The following work **identically** to the privileged images, the same guides apply:

- **Auto Backup & Upgrade:** See the [Auto Backup and Upgrade Guide](auto-backup-and-upgrade-guide.md)
- **Email:** See the [Email Guide](email-guide.md)
- **Home Assistant fix:** See the [Home Assistant Fix Guide](home-assistant-fix.md)
- **Databases:** See the [Database Guide](database-guide.md)

## Running as a specific user

The image is built to follow **whatever** uid/gid it is launched with.

```sh
docker run --rm -it -p 80:8080 \
  --user 1000:1000 \
  anmutech/baikal:nginx-unprivileged
```

> [!DANGER]
> The image allows setting user to `0:0`, resulting in the FPM workers running as `root` inside the container.
> Other sensitive UID/GID combos depend on the system the container is deployed on.
> This option is included to let users of **rootless docker, or podman** have the `config` and `Specific` volume map to their user.
> **Do not set user to `0:0` unless running rootless! Do not expose to the internet!**

## Known Issues
