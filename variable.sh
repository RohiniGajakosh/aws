# variable.sh
EC2_NAME="fighing4it"
InstanceId="i-02869250b96a9576e"
EC2_SECURITY_GROUP_ID="sg-0b88ee672bdba3cf8"
REGION=us-east-1

SUBNET_IDS="subnet-04dbcd61235b7f94b,subnet-0b15e9f0cb64bdf7b"
AMI=ami-08982f1c5bf93d976
# Scaling configuration
ASG_NAME=MaASG
MIN_SIZE=1
MAX_SIZE=5
DESIRED_CAPACITY=2
SSMROLE=ssmagentRole


#================CONFIGURATION==========for LOAD BALANCER =============

REGION="us-east-1"
VPC_ID=vpc-069165982f53d4db2
SUBNETS="subnet-04dbcd61235b7f94b,subnet-0b15e9f0cb64bdf7b"
SG_ID="sg-0b88ee672bdba3cf8"
LB_NAME="MyLoadBalancer"

##================CONFIGURATION==========For TARGET GROUP =============

TARGET_GROUP_NAME="MyTargetGroup"
LAUNCH_TEMPLATE="ASGLaunchTemplate"


