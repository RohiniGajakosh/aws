#!/bin/bash
set -euo pipefail

##==============Variable for Launch Template==================

read -rp "Enter the name of Launch Template (default: ASGLaunchTemplate): " LAUNCH_TEMPLATE
LAUNCH_TEMPLATE=${LAUNCH_TEMPLATE:-ASGLaunchTemplate}

read -rp "Enter AWS region (default: us-east-1): " REGION
REGION=${REGION:-us-east-1}

KEY_PAIR="newkey"
EC2_NAME="neweraInstance"
ASG_NAME="MyAutoScalingGroup"
EC2_SECURITY_GROUP_ID=

#================== Update with your VPC subnet IDs ================
SUBNET_IDS="subnet-080f0c73cf1d3656d,subnet-0662782d4c057c8f3"


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
