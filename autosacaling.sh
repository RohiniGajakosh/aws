#!/bin/bash
set -euo pipefail  ## If the script fails, it will exit immediately

export AWS_PAGER=""   ## disable CLI pager so script runs non-interactively
##==============Variable for Launch Template==================

read -rp "Enter the name of Launch Template (default: ASGLaunchTemplate): " LAUNCH_TEMPLATE
LAUNCH_TEMPLATE=${LAUNCH_TEMPLATE:-ASGLaunchTemplate}

read -rp "Enter AWS region (default: us-east-1): " REGION
REGION=${REGION:-us-east-1}

KEY_PAIR=$( aws ec2 describe-instances --instance-ids <instance-id> --region $REGION --query 'Reservations[*].Instances[*].KeyName' --output text)
EC2_NAME="neweraInstance"
ASG_NAME=$LAUNCH_TEMPLATE
EC2_SECURITY_GROUP_ID=$1 

#================== Update with your VPC subnet IDs ================
SUBNET_IDS="subnet-080f0c73cf1d3656d,subnet-0662782d4c057c8f3"

ensure_sg_id() {
  local sg_name=$1
  local sg_id=$(aws ec2 describe-security-groups --filters Name=group-name,Values="$EC2_SECURITY_GROUP_ID" --query 'SecurityGroups[0].GroupId' --output text --region "$REGION")
  if [ -z "$sg_id" ]; then;
    echo "Security group $sg_name not found. Please create it first."
    exit 1
  else
    echo The security group existing id is: $sg_id
  fi
}

# Scaling configuration
MIN_SIZE=1
MAX_SIZE=3
DESIRED_CAPACITY=2


# Encode user data file
USERDATA=$(base64 -w0 user_data.sh)

#============Creating Launch Template==============


echo "Creating Launch Template: $LAUNCH_TEMPLATE"


aws ec2 create-launch-template \
  --launch-template-name "$LAUNCH_TEMPLATE" \
  --region "$REGION" \
  --version-description "Initial-version" \
  --launch-template-data "{
    \"ImageId\": \"ami-08982f1c5bf93d976\",
    \"InstanceType\": \"t3.micro\",
    \"KeyName\": \"$KEY_PAIR\",
    \"SecurityGroupIds\": [\"$EC2_SECURITY_GROUP_ID\"],
    \"UserData\": \"$USERDATA\",
    \"TagSpecifications\": [{
        \"ResourceType\": \"instance\",
        \"Tags\": [
          {\"Key\": \"Name\", \"Value\": \"$EC2_NAME\"},
          {\"Key\": \"Region\", \"Value\": \"$REGION\"}
        ]
    }],
    \"Monitoring\": {
      \"Enabled\": true
    }
  }"


echo " Launch Template $LAUNCH_TEMPLATE created."


##==============Create Auto Scaling Group==================

echo "Creating Auto Scaling Group: $ASG_NAME"

aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name "$ASG_NAME" \
  --launch-template "LaunchTemplateName=$LAUNCH_TEMPLATE,Version=1" \
  --min-size $MIN_SIZE \
  --max-size $MAX_SIZE \
  --desired-capacity $DESIRED_CAPACITY \
  --vpc-zone-identifier "$SUBNET_IDS" \
  --region "$REGION"

echo "Auto Scaling Group $ASG_NAME created with desired capacity $DESIRED_CAPACITY"
