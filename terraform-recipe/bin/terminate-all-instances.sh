# Find and terminate all running instances across all regions
REGIONS=$(aws ec2 describe-regions | awk '{print $3}')
AWS_PROFILE="subnet"
for region in $REGIONS; do
 for instance in $(aws --profile $AWS_PROFILE ec2 describe-instances --region $region --output json | jq -r '.Reservations[].Instances[].InstanceId');do
   aws --profile subnet ec2 terminate-instances --instance-ids  $instance --region $region;
 done;
done
