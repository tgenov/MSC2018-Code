#!/bin/bash
set -eu
set -o pipefail 

process_region() {
   local region=$1
    for instance in $(aws --profile $AWS_PROFILE ec2 describe-instances --region $region --output json | jq -r '.Reservations[].Instances[].InstanceId');do
     echo "Terminating Instance $instance in $region"
     aws --profile subnet ec2 terminate-instances --instance-ids  $instance --region $region;
    done
}


# Find and terminate all running instances across all regions
REGIONS=$( aws ec2 describe-regions --output json |jq -r '.[][].RegionName' )
AWS_PROFILE="subnet"
for region in $REGIONS; do
 echo "Enumerating instanecs in $region"
 process_region "$region" &
done
