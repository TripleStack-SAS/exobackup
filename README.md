exobackup
=========

[Exoscale](https://portal.exoscale.com/register?r=TkuGp4tr54Jd) VM offsite backup

Install
-------

You must use [jq](https://stedolan.github.io/jq/) and [rclone](https://rclone.org/).

On Debian-based systems: `apt-get install rclone jq`


Features
--------

- Create snapshot from VM
- Auto purge old snapshots
- Transform snapshots to runnable VM image
- Exporting (Thanks rclone) to another places (S3, Google Drive...)
- Purge old backups


Exemple
-------

```
./exobackup.sh myvmid rclone_remote:my/target/directory
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
