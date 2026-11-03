# Auto Backup and Upgrade Guide

This guide outlines how to setup the container to automatically create backups of the sqlite database, and perform baikal database upgrades.
Backups of other databases are not supported.

## Usage

See [examples/docker-compose.auto-backup-and-upgrade.yaml](../examples/docker-compose.auto-backup-and-upgrade.yaml) for a starter template.

Two environment variables activate the feature, each enabled exclusively by the value `true`:

- `AUTO_UPGRADE_DB=true` – perform the automatic database upgrade
- `BACKUP_BEFORE_UPGRADE=true` – create a timestamped backup of the `config` and `Specific` volumes before upgrading

Possible combinations:

| `AUTO_UPGRADE_DB` | `BACKUP_BEFORE_UPGRADE` | Behaviour |
|---|---|---|
| `true` | `true` | Back up `config` + `Specific`, then upgrade (the safest, recommended combination) |
| `true` | anything else | Upgrade **without** a backup – you take the risk of an unrecoverable failure |
| anything else | `true` | Back up `config` + `Specific` only; the upgrade itself is left to you (e.g. the web wizard) |
| anything else | anything else | No-op, nothing is done |

Any other value (including `I_ACCEPT_THE_RISK`, `1`, `yes`) does **not** activate a flag, and the old `AUTO_BACKUP_AND_UPGRADE` variable is no longer supported – if it is still set, the script prints a warning and ignores it.

If the script detects a mismatch of the baikal version in the baikal.yaml vs the baikal version in Core/Distrib.php, and `BACKUP_BEFORE_UPGRADE=true` is set,
it creates a backup of the contents of the `config` and `Specific` volumes and places the backup inside each respective volume.
If `AUTO_UPGRADE_DB=true` is set, it then hooks into the baikal php scripts to perform an upgrade the same way baikal would, if an upgrade is required.

Should any assumption the upgrade script makes not be met it bails out, instead of trying to continue.
In most cases, this will let the container start without any problem.
In some cases, manual interaction by the user is required when the script was unable to perform an upgrade.
In the worst case, the upgrade failed inside baikal's own scripts, which will stop the container, requiring a full recovery from backup.

Users coming from any earlier ckulka image can change to the latest anmutech/baikal image, set `AUTO_UPGRADE_DB=true` and `BACKUP_BEFORE_UPGRADE=true` as above, and enjoy interaction-less upgrades (see [Known Issues](#known-issues) below).

> [!IMPORTANT]
> Performing the auto upgrade of databases works with mariadb/mysql/postgres as well.
> Should you choose to use the auto upgrade functionality with these databases be warned!
> You are responsible to regularly perform backups!!!
> The auto-backup-and-upgrade script has no access to the database volume(s).
> Ignoring this might result in complete database loss, in the worst case!

## Known Issues

Upgrades from baikal versions below 0.7.0 require user interaction, since baikal config format changed.
See here for more info: <https://github.com/anmutech/baikal-docker/issues/10#issuecomment-6551863719>
