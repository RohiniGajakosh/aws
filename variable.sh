# variable.sh
EC2_NAME="fighing4it"
InstanceId="i-0916354098e014ba0"
EC2_SECURITY_GROUP_ID="sg-08d1b0fd173c87eeb"
REGION=us-east-1
VPC_ID=vpc-077d3175cbd28d419
DB_SUBNET_GROUP_NAME="rohurdssubs"
##=====================INFRACOMPONENTS=====================
AMI_ID="ami-08982f1c5bf93d976"
INSTANCE_TYPE="t3.micro"
KEY_PAIR="newkey"
SUBNET_IDS="subnet-00ffa08a49c86afb9,subnet-0b0dd6863b3939526"
AMI=ami-08982f1c5bf93d976
SSMROLE=ssmagentRole
CIDR=$(aws ec2 describe-vpcs --vpc-ids $VPC_ID --query 'Vpcs[0].CidrBlock' --output text)
# Scaling configuration
ASG_NAME=MaASG
MIN_SIZE=1
MAX_SIZE=5
DESIRED_CAPACITY=2
SSMROLE=ssmagentRole


#================CONFIGURATION==========for LOAD BALANCER =============

REGION="us-east-1"
# VPC_ID=vpc-077d3175cbd28d419
SUBNETS="subnet-00ffa08av49c86afb9,subnet-0b0dd6863b3939526"
EC2_SECURITY_GROUP_ID="sg-08d1b0fd173c87eeb"
LB_NAME="MyLoadBalancer"

##================CONFIGURATION==========For TARGET GROUP =============

TARGET_GROUP_NAME="MyTargetGroup"
LAUNCH_TEMPLATE="asglaunchtemp"  #"ASGLaunchTemplate"


