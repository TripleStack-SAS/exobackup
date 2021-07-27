exobackup
=========

[Exoscale](https://portal.exoscale.com/register?r=TkuGp4tr54Jd) VM offsite backup

Install
-------

You must use [jq](https://stedolan.github.io/jq/), [rclone](https://rclone.org/) and [exo](https://github.com/exoscale/cli).

On Debian-based systems: `apt-get install rclone jq`


Setup
-----

- Setup [exo](https://github.com/exoscale/cli) with API keys
- Setup [rclone remote config](https://rclone.org/commands/rclone_config/)

Checks:

```
$ exo vm list
┼──────────────────────────────────────┼─────────────────────────────────────────┼───────┼─────────┼─────────┼─────────────────┼
│                  ID                  │                  NAME                   │ SIZE  │  ZONE   │  STATE  │   IP ADDRESS    │
┼──────────────────────────────────────┼─────────────────────────────────────────┼───────┼─────────┼─────────┼─────────────────┼
│ xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx │ VM-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx │ Micro │ ch-dk-2 │ Stopped │ XXX.XXX.XXX.XXX │
┼──────────────────────────────────────┼─────────────────────────────────────────┼───────┼─────────┼─────────┼─────────────────┼
```

```
$ rclone lsd my_rclone_remote:
          -1 2021-07-22 12:43:49        -1 my-bucket-or-folder

```



Features
--------

- Create snapshot from VM
- Auto purge old snapshots
- Transform snapshots to runnable VM image
- Exporting (thanks rclone) to another places (S3, Google Drive...)
- Purge old backups


Exemple
-------

Backup VM to one target:

```
./exobackup.sh myvmid rclone_remote:my/target/directory
```


Backup VM to many targets:

```
./exobackup.sh myvmid rclone_remote:my/target/directory rclone_remote_alt:my/another/directory
```

Environment variables
---------------------

- `SNAPSHOTS_RETENTION_DAYS`
- `RCLONE_DELETE_MIN_AGE` (see [rclone documentation](https://rclone.org/filtering/#min-age-don-t-transfer-any-file-younger-than-this))

License
-------

MIT

Author Information
------------------

- Emilien Mantel for [TripleStack](https://triplestack.fr)
