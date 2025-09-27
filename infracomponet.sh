#!/bin/bash
set -euo pipefail  ##If the script fails , stopt the exectution

##===============CONFIGURATION==========

REGION="us-east-1"
export AWS_PAGER=""  # prevent AWS CLI from opening a pager mid-script
VPC_ID="vpc-0d0c517c28437f881"
IGW_NAME="NewIGA"
APP_TIER_A=subnet-0d0d678ced33022a5
APP_TIER_B=subnet-0c1ebff0c313477b0
DATA_TIER_A=subnet-020f3d4b1ea150dd8
DATA_TIER_B=subnet-0406c2e3ce8655f6e
PUB_TIER_A=subnet-0bd815874359ae949


###--------EC2 CONFIG--------------------

AMI_ID="ami-08982f1c5bf93d976"
INSTANCE_TYPE="t3.micro"
KEY_PAIR="newkey"
EC2_SECURITY_GROUP_NAME="rohisg"
EC2_SECURITY_GROUP_ID=<Id-here_sg>
SUBNET_ID="$APP_TIER_A"
EC2_NAME="neweraInstance"


## RDS Config=====================
RDS_NAME="rohurds"
DB_ENGINE=mysql
DB_VERSION="8.0.42"
DB_CLASS="db.t3.micro"
DB_NAME="databse"
DB_USERNAME="rohini"
DB_PASSWORD="RedhatRohini"
DB_SECURITY_GROUP_NAME="default"
DB_SUBNET_GROUP_NAME="rohurdssubs"
SUBNET_IDS=( $DATA_TIER_A $DATA_TIER_B)





if aws rds describe-db-subnet-groups  --region "$REGION" >/dev/null 2>&1; then
echo "Creating DB subnet group: $DB_SUBNET_GROUP_NAME"
DB_SUBNET_GROUP_NAME=$(aws rds create-db-subnet-group \
    --db-subnet-group-name "$DB_SUBNET_GROUP_NAME" \
    --db-subnet-group-description "Rohisubs" \
    --subnet-ids "${SUBNET_IDS[@]}" \
    --region "$REGION" \
    --query "DBSubnetGroup.DBSubnetGroupName" \
    --output text )
echo "Createed DB subnetgroup: $DB_SUBNET_GROUP_NAME"
else 
echo "Db subnet group $DB_SUBNET_GROUP_NAME already exists"
fi
echo "Createed DB subnetgroup: $DB_SUBNET_GROUP_NAME"


#########################Creating_RDS#######################################################

aws rds create-db-instance \
  --db-instance-identifier "$RDS_NAME" \
  --db-instance-class "$DB_CLASS" \
  --engine "$DB_ENGINE" \
  --engine-version "$DB_VERSION" \
  --allocated-storage 20 \
  --master-username "$DB_USERNAME" \
  --master-user-password "$DB_PASSWORD" \
  --db-name "$DB_NAME" \
  --db-subnet-group-name "$DB_SUBNET_GROUP_NAME" \
  --backup-retention-period 1 \
  --no-publicly-accessible \
  --region "$REGION" \
  --tags "Key=name,Value=${RDS_NAME}"

################Waiting for the rds to come up#############################33

echo "Waiting for Db to become avilable"
aws rds wait db-instance-available --db-instance-identifier "$RDS_NAME" --region "$REGION"

###=================Get the RDs endpoint########################33

DB_ENDPOINT=$( aws rds describe-db-instances --db-instance-identifier "$RDS_NAME" --region "$REGION"  --query "DBInstances[0].Endpoint.Address"  --output text )

echo "RDS Instance ready at endpoint: $DB_ENDPOINT"


##===Creating the USer_Data===========

##=== Creating the User Data (with DB injected) ===========
USER_DATA=$(cat <<EOF
#!/bin/bash
yum update -y
amazon-linux-extras enable php7.4
yum install -y httpd php php-mysqlnd
systemctl start httpd
systemctl enable httpd

cat <<'PHPAPP' > /var/www/html/index.php
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>🌟 Welcome to My Dynamic AWS Site 🌟</title>
  <style>
    body { margin:0; font-family:'Segoe UI',sans-serif; background:linear-gradient(135deg,#74ABE2,#5563DE); color:white; text-align:center; }
    header { padding:40px; background:rgba(0,0,0,0.5); }
    h1 { font-size:3em; margin:0; }
    p { font-size:1.2em; }
    .card { background:white; color:#333; margin:40px auto; padding:20px; border-radius:12px; max-width:600px; box-shadow:0px 4px 20px rgba(0,0,0,0.3);}
    img { max-width:100%; border-radius:12px;}
    footer { padding:20px; background:rgba(0,0,0,0.4); margin-top:40px;}
  </style>
</head>
<body>
  <header>
    <h1>🌐 My AWS Dynamic Website</h1>
    <p>Running on EC2 + RDS</p>
  </header>

  <div class="card">
    <img src="https://source.unsplash.com/800x400/?nature,technology" alt="Banner Image">
    <h2>Hello from EC2!</h2>
    <p>
      <?php
        \$servername = "$DB_ENDPOINT";
        \$username = "$DB_USERNAME";
        \$password = "$DB_PASSWORD";
        \$dbname = "$DB_NAME";

        \$conn = new mysqli(\$servername, \$username, \$password, \$dbname);
        if (\$conn->connect_error) {
          echo "❌ Database connection failed: " . \$conn->connect_error;
        } else {
          echo "✅ Connected to database: " . \$dbname . "<br>";
          \$result = \$conn->query("SELECT NOW() as nowtime");
          \$row = \$result->fetch_assoc();
          echo "⏰ Current DB time: " . \$row['nowtime'];
          \$conn->close();
        }
      ?>
    </p>
  </div>

  <footer>
    <p>🚀 Powered by AWS | EC2 + RDS + Apache + PHP</p>
  </footer>
</body>
</html>
PHPAPP

chown apache:apache /var/www/html/index.php
systemctl restart httpd
EOF
)



#===============CREATION-EC2-Instance============

EC2_ID=$( aws ec2 run-instances --image-id "$AMI_ID"  --subnet-id "$SUBNET_ID" --region "$REGION" --instance-type "$INSTANCE_TYPE" --key-name "$KEY_PAIR" --user-data "$USER_DATA" --security-group-id "$EC2_SECURITY_GROUP_ID" --associate-public-ip-address --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${EC2_NAME}},{Key=Region,Value=us-east-1}]" --query "Instances[0].InstanceId" --output text )


##GET Public IP####

EC2_PUBLIC_IP=$( aws ec2 describe-instances  --instance-ids "$EC2_ID" --region "$REGION" --query "Reservations[0].Instances[0].PublicIpAddress"   --output text )


# ========= SUMMARY =========
echo "----------------------------------------"
echo " EC2 Instance ID : $EC2_ID"
echo " EC2 Public IP   : $EC2_PUBLIC_IP"
echo " RDS Endpoint    : $DB_ENDPOINT"
echo " Visit Website   : http://$EC2_PUBLIC_IP/"
echo "----------------------------------------"
