
#!/bin/bash
set -euo pipefail
REGION="us-east-1"
export AWS_PAGER=""  # disable CLI pager so script runs non-interactively

my_vpc=$( aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=NewVPC},{Key=Region,Value=us-east-1}]' \
  --region "$REGION" \
  --query 'Vpc.VpcId' \
  --output text )


aws ec2 create-subnet --vpc-id $my_vpc --cidr-block 10.0.0.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=AppSubnet},{Key=Region,Value=us-east-1}]' --region "$REGION"

aws ec2 create-subnet --vpc-id $my_vpc --cidr-block 10.0.1.0/24 --availability-zone us-east-1b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=AppSubnet},{Key=Region,Value=us-east-1}]' --region "$REGION"

aws ec2 create-subnet --vpc-id $my_vpc --cidr-block 10.0.2.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Datasubnet},{Key=Region,Value=us-east-1}]' --region "$REGION"

aws ec2 create-subnet --vpc-id $my_vpc --cidr-block 10.0.3.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=PublicSubnet},{Key=Region,Value=us-east-1}]' --region "$REGION"

aws ec2 create-subnet --vpc-id $my_vpc --cidr-block 10.0.4.0/24 --availability-zone us-east-1b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Datasubnet},{Key=Region,Value=us-east-1}]' --region "$REGION"
