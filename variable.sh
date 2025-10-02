# variable.sh
EC2_NAME="fighing4it"
InstanceId="i-02869250b96a9576e"
EC2_SECURITY_GROUP_ID="sg-0b88ee672bdba3cf8"
REGION=us-east-1
ASG_NAME=MaASG
SUBNET_IDS="subnet-04dbcd61235b7f94b,subnet-0b15e9f0cb64bdf7b"
AMI=ami-08982f1c5bf93d976
# Scaling configuration
MIN_SIZE=1
MAX_SIZE=3
DESIRED_CAPACITY=2
SSMROLE=ssmagentRole
