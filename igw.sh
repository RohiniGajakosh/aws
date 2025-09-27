#!/bin/bash
set -euo pipefail

##===============CONFIGURATION==========

REGION="us-east-1"
VPC_ID=vpc-0b3e7ba60fb94bf00
IGW_NAME="NewIGA"


#============================CREATE IGW=======================

echo "Creating Internet Gateway......"

IGW_ID=$( aws ec2 create-internet-gateway  --region "$REGION" --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value="$IGW_NAME"},{Key=Region,Value=us-east-1}]" --query 'InternetGateway.InternetGatewayId' --output text ) && echo "The created Internet Gateway Id is: $IGW_ID"

##===============Attach IGW To VPC=====================
echo "Attaching Internet_Gateway $IGW_ID to VPC $VPC_ID...."

aws ec2 attach-internet-gateway   --vpc-id "$VPC_ID" --internet-gateway-id "$IGW_ID" --region $REGION

echo "Internet Gateway $IGW_NAME with $IGW_ID is sucessfully attached to VPC $VPC_ID"

##aws ec2 attach-internet-gateway --vpc-id "vpc-02bb693fd93382c2c" --internet-gateway-id "igw-0ea8aabdfa4ad17fb" --region us-east-1