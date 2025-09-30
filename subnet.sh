
#!/bin/bash
set -euo pipefail
read -rp "Enter AWS region (default: us-east-1): " REGION
REGION=${REGION:-us-east-1}

read -rp "Enter VPC CIDR (default: 10.0.0.0/16): " VPC_CIDR
VPC_CIDR=${VPC_CIDR:-10.0.0.0/16}


export AWS_PAGER=""  # disable CLI pager so script runs non-interactively

my_vpc=$( aws ec2 create-vpc \
  --cidr-block $VPC_CIDR \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=NewVPC},{Key=Region,Value="$REGION"}]" \
  --region "$REGION" \
  --query 'Vpc.VpcId' \
  --output text )

echo "Created VPC $my_vpc with CIDR $VPC_CIDR"

###Let's createa the freakin subnets

BASE_PREFIX=$(echo "$VPC_CIDR" | cut -d. -f1-2)

aws ec2 create-subnet --vpc-id $my_vpc --cidr-block "$BASE_PREFIX.0.0/24" --availability-zone ${REGION}a --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=AppSubnet},{Key=Region,Value="$REGION"a}]" --region "$REGION"

aws ec2 create-subnet --vpc-id $my_vpc --cidr-block "$BASE_PREFIX.1.0/24" --availability-zone ${REGION}b --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=AppSubnet},{Key=Region,Value="$REGION"b}]" --region "$REGION"

aws ec2 create-subnet --vpc-id $my_vpc --cidr-block "$BASE_PREFIX.2.0/24" --availability-zone ${REGION}a --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Datasubnet},{Key=Region,Value="$REGION"a}]" --region "$REGION"

aws ec2 create-subnet --vpc-id $my_vpc --cidr-block "$BASE_PREFIX.3.0/24" --availability-zone ${REGION}b --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Datasubnet},{Key=Region,Value="$REGION"b}]" --region "$REGION"

aws ec2 create-subnet --vpc-id $my_vpc --cidr-block "$BASE_PREFIX.4.0/24" --availability-zone ${REGION}a --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=PublicSubnet},{Key=Region,Value="$REGION"a}]" --region "$REGION"


echo "please run igw.sh script next" 