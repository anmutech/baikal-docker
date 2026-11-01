# Auto Backup and Upgrade Guide

This guide outlines how to setup the container to automatically create backups of the sqlite database, and perform baikal database upgrades.

## Usage

See [examples/docker-compose.auto-backup-and-upgrade.yaml](../examples/docker-compose.auto-backup-and-upgrade.yaml) for a starter template.

If the `AUTO_BACKUP_AND_UPGRADE` variable is set to `I_ACCEPT_THE_RISK` the docker-entrypoint script 55 is activated.
If the script detects a mismatch of the baikal version in the baikal.yaml vs the baikal version in Core/Distrib.php,
it creates a backup of the contents of the `config` and `Specific` volumes and places the backup inside each respective volume.
Afterwards it hooks into the baikal php scripts to perform an upgrade the same way baikal would, if an upgrade is required.

Should any assumption the upgrade script makes not be met it bails out, instead of trying to continue.
In most cases, this will let the container start without any problem.
In some cases, manual interaction by the user is required when the script was unable to perform an upgrade.
In the worst case, the upgrade failed inside baikal's own scripts, which will stop the container, requiring a full recovery from backup.

Users coming from any earlier ckulka image can change to the latest anmutech/baikal image, set the `AUTO_BACKUP_AND_UPGRADE` variable as above, and enjoy interaction-less upgrades (see [Known Issues](#known-issues) below).

> [!IMPORTANT]
> Performing the auto upgrade of databases works with mariadb/mysql/postgres as well.
> Should you choose to use the auto upgrade functionality with these databases be warned!
> You are responsible to regularly perform backups!!!
> The auto-backup-and-upgrade script has no access to the database volume(s).
> Ignoring this might result in complete database loss, in the worst case!

## Known Issues

Upgrades from baikal versions below 0.7.0 require user interaction, since baikal config format changed.
See here for more info: <https://github.com/anmutech/baikal-docker/issues/10#issuecomment-6551863719>
