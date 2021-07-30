#!/bin/bash

# Copyright 2021 TripleStack SAS
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.



if [ $# -lt 2 ]
then
	echo "Usage: $0 INSTANCE_ID RCLONE_TARGET_CONFIG1 [RCLONE_TARGET_CONFIG2...]"
	exit 1
fi

# -----------------------------
# Config
# -----------------------------
INSTANCE_ID=$1
RCLONE_TARGET_CONFIGS="${@:2}"

EXO_PATH=${EXO_PATH:-exo}
RCLONE_PATH="${RCLONE_PATH:-rclone}"

EXOSCALE_SNAPSHOTS_RETENTION_DAYS="${EXOSCALE_SNAPSHOTS_RETENTION_DAYS:-7}"

RCLONE_DELETE_MIN_AGE="${RCLONE_DELETE_MIN_AGE:-30d}"
RCLONE_PUSH_METADATA_S3="${RCLONE_PUSH_METADATA_S3:-1}"
RCLONE_EXTRA_FLAGS="${RCLONE_EXTRA_FLAGS}"
# -----------------------------


# -----------------------------
# Vars
# -----------------------------
timestamp_snapshot_max=$(date --date="$EXOSCALE_SNAPSHOTS_RETENTION_DAYS day ago" "+%s")
exo_date_pattern="%Y-%m-%dT%H:%M:%S+0000"
# -----------------------------


# -----------------------------
# Functions
# -----------------------------
get_computed_target() {
	echo $1/${INSTANCE_ID}/backup__$(date +%s)__${INSTANCE_ID}.qcow2
	return 0
}
get_rclone_remote_name() {
	echo "$1" | cut -d ':' -f 1
}
# -----------------------------


# -----------------------------
# Pre checks
# -----------------------------
for config in ${RCLONE_TARGET_CONFIGS}
do
	remote_name=$(get_rclone_remote_name $config)
	$RCLONE_PATH config show $remote_name &> /dev/null
	if [ $? -gt 0 ]
	then
		echo "Error: rclone config ${remote_name} (${config}) not found."
		exit 1
	fi
done

# Check VM info
vm_info=$($EXO_PATH vm show "$INSTANCE_ID" -O json)
if [ $? -gt 0 ]
then
	echo "Error: instance ${INSTANCE_ID} not found."
	exit 1
fi

# Check remote rclone config is valid



# -----------------------------
# Main
# -----------------------------
echo "Purging snapshots..."
snapshot_list=$($EXO_PATH vm snapshot list -O json | jq -r ".[] | select ((.instance == \"${INSTANCE_ID}\") and (.date | strptime(\"${exo_date_pattern}\") > ${timestamp_snapshot_max})).id")
if [ -n "$snapshot_list" ]
then
	for snapshot_id in "$snapshot_list"
	do
		echo "Purging $snapshot_id"
		$EXO_PATH vm snapshot delete -f $snapshot_id
	done
fi

echo "Purge done."

echo "Snapshoting..."
snapshot_info=$($EXO_PATH vm snapshot create $INSTANCE_ID -O json)
snapshot_id=$(echo "$snapshot_info" | jq -r '.id')
echo "Snapshot OK: ${snapshot_id}"

echo "Exporting snapshot..."
snapshot_export_info=$($EXO_PATH vm snapshot export ${snapshot_id} -O json)
snapshot_export_url=$(echo ${snapshot_export_info} | jq -r '.url')
snapshot_export_md5=$(echo ${snapshot_export_info} | jq -r '.checksum')
echo "Snapshot export OK"
echo "Snapshot md5 checksum: $snapshot_export_md5"

echo "Migrating snapshot with rclone"
for config in ${RCLONE_TARGET_CONFIGS}
do
	rclone_add_flag=()
	rclone_computed_target=$(get_computed_target "$config")
	echo "> Migrating to $rclone_computed_target"

	remote_name=$(get_rclone_remote_name $config)
	rclone config show $remote_name | grep -E -q '^type.*=.*s3'
	if [ $? -eq 0 ]
	then
		echo "> Adding extra flags (S3 rclone remote)"
		rclone_add_flag=(--header-upload "X-Amz-Meta-Md5sum: ${snapshot_export_md5}" --header-upload "X-Amz-Meta-Orig-Vm-Info: ${vm_info}")
	fi

	$RCLONE_PATH copyurl "${snapshot_export_url}" "${rclone_computed_target}" "${rclone_add_flag[@]}" $RCLONE_EXTRA_FLAGS
done

echo "Purging backups..."
for config in ${RCLONE_TARGET_CONFIGS}
do
	echo "> Purging $config"
	$RCLONE_PATH delete $config --min-age "$RCLONE_DELETE_MIN_AGE"
done

echo "All done."
