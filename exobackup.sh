#!/bin/bash

if [ $# -ne 2 ]
then
	echo "Usage: $0 INSTANCE_ID RCLONE_TARGET_CONFIG"	
	exit 1
fi

# -----------------------------
# Config
# -----------------------------
INSTANCE_ID=$1
RCLONE_TARGET_CONFIG=$2
SNAPSHOTS_RETENTION_DAYS="${SNAPSHOTS_RETENTION_DAYS:-7}"
RCLONE_DELETE_MIN_AGE="${RCLONE_DELETE_MIN_AGE:-30d}"

# Vars
timestamp_snapshot_max=$(date --date="$SNAPSHOTS_RETENTION_DAYS day ago" "+%s")
rclone_computed_target="${RCLONE_TARGET_CONFIG}/${INSTANCE_ID}/backup__$(date +%s)__${INSTANCE_ID}.qcow2"
exo_date_pattern="%Y-%m-%dT%H:%M:%S+0000"

# Check VM info
exo vm show "$INSTANCE_ID" > /dev/null
if [ $? -ne 0 ]
then
	echo "Error: instance ${INSTANCE_ID} not found."
	exit 1
fi


echo "Purging snapshots..."
snapshot_list=$(exo vm snapshot list -O json | jq -r ".[] | select ((.instance == \"${INSTANCE_ID}\") and (.date | strptime(\"${exo_date_pattern}\") > ${timestamp_snapshot_max})).id")
if [ -n "$snapshot_list" ]
then
	for snapshot_id in "$snapshot_list"
	do
		echo "Purging $snapshot_id"
		exo vm snapshot delete -f $snapshot_id
	done
fi

echo "Purge done."

echo "Snapshoting..."
snapshot_info=$(exo vm snapshot create $INSTANCE_ID -O json)
snapshot_id=$(echo "$snapshot_info" | jq -r '.id')
echo "Snapshot OK: ${snapshot_id}"

echo "Exporting snapshot..."
snapshot_export_info=$(exo vm snapshot export ${snapshot_id} -O json)
snapshot_export_url=$(echo ${snapshot_export_info} | jq -r '.url')
echo "Snapshot export OK"

echo "Migrating snapshot with rclone"
rclone copyurl "${snapshot_export_url}" "${rclone_computed_target}"

echo "Purging backups..."
rclone delete $RCLONE_TARGET_CONFIG --min-age "$RCLONE_DELETE_MIN_AGE"

echo "All done."
