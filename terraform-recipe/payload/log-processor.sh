#!/bin/bash
set -eu
set -o pipefail

# Poor man's logstash that doesn't require Java or 1GB RAM.
# This allows us to run on dirt-cheap t3.nano instances.
#
# 1. For any new events in LOGFILE
# 1.1 Inject custom fields into JSON event (aws-region, public-ip, instance-id etc).
# 1.2 Copy event into SHADOW file
# 2. When SHADOW reaches a pre-determined size or age upload it to S3

# CONFIGURABLES
LOGFILE='/home/cowrie/cowrie/log/cowrie.json'
MAX_SHADOW_AGE=900
MAX_SHADOW_SIZE=1048576
S3_BUCKET="cowrie-json-logs"
POINTER="$LOGFILE.pointer"
SHADOW="$LOGFILE.shadow"
SHADOW_CTIME_FILE="$SHADOW.ctime"
ENV_FILE="/home/ubuntu/scripts/log-processor.env"

source $ENV_FILE

# Logic
function logger()
{ 
    TSTAMP="[$(date +'%Y-%m-%d %H:%M:%S')"
    echo "$TSTAMP $*" >> /home/cowrie/cowrie/log/log-pusher.log
}

function main() {
  END_LINE=$(cat $LOGFILE | wc -l | tr -d '[:space:]' )

  # Read or initialize the pointer.
  if [ -e "$POINTER" ];
  then
    START_LINE=$(cat "$POINTER")
  else
    START_LINE=0
    echo 0 > "$POINTER"
  fi

  if [ ! -e "$SHADOW_CTIME_FILE" ];
  then
    touch $SHADOW_CTIME_FILE $SHADOW
  fi

  # Reset pointer on LOGFILE rotation.
  if [ $START_LINE -gt $END_LINE ];
  then
      logger "$LOGFILE has been rotated"
      START_LINE=0
      echo 0 > "$POINTER"
  fi

  # Append new events from LOGFILE to SHADOW
  if [ $START_LINE -ne $END_LINE ];
  then
    logger "START: line $START_LINE of $LOGFILE"
    logger "END: line $END_LINE of $LOGFILE"
    # Add custom key-value pairs to the event.
    awk "NR > $START_LINE && NR <= $END_LINE" $LOGFILE | jq -Mca \
      --arg region $AWS_REGION \
      --arg ip $PUBLIC_IP \
      --arg id $INSTANCE_ID \
      --arg ckv $KERNEL_VERSION \
      --arg cconf $COWRIE_CONFIG \
      --arg ckb $KERNEL_BUILD \
      --arg hw $HARDWARE_PLATFORM \
      --arg arch $ELF_ARCH \
      '. + {aws_region: $region, public_ip: $ip, instance_id: $id, cowrie_kernel_version: $ckv,
      cowrie_kernel_build: $ckb, cowrie_hardware_platform: $hw, cowrie_elf_arch : $arch, cowrie_config: $cconf }' >> $SHADOW
    echo $END_LINE > "$POINTER"
  else
    logger "No new lines in $LOGFILE"
  fi

  # Upload shadow to S3 if necessary
  if [ -f $SHADOW ];
  then
    SHADOW_SIZE=$(stat -c %s $SHADOW)
    SHADOW_CTIME=$(stat -c %X $SHADOW_CTIME_FILE)
    # expr exits with status 1 when the expression evaluates to 0
    SHADOW_AGE=$(expr $(date +%s) - $SHADOW_CTIME) || true
    logger "Shadow size: $SHADOW_SIZE bytes"
    logger "Shadow age: $SHADOW_AGE seconds"
    if [ $SHADOW_SIZE -gt 0 ];
    then
      if [ $SHADOW_SIZE -gt $MAX_SHADOW_SIZE ] || [ $SHADOW_AGE -ge $MAX_SHADOW_AGE ]
      then
        S3_PATH="s3://$S3_BUCKET/incoming/$(date +%Y/%m/%d/%H/$(uuidgen)).json"
        logger "Uploading shadow to S3"
        aws s3 mv $SHADOW $S3_PATH && rm $SHADOW_CTIME_FILE
      fi
    fi
  fi
}

while true
do
   main
   sleep 60
done
