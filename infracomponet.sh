#!/bin/bash
set -euo pipefail  ##If the script fails , stopt the exectution

##===============CONFIGURATION==========

REGION="us-east-1"
export AWS_PAGER=""  # prevent AWS CLI from opening a pager mid-script
VPC_ID="vpc-063e91cb522d62f76"
IGW_NAME="MyIGA"
APP_TIER_A=subnet-02cc76edd5d62a81b
APP_TIER_B=subnet-05fa0a1e90f37acfe
DATA_TIER_A=subnet-0307de9e020c8d3cd
DATA_TIER_B=subnet-060622f94c02545ad
PUB_TIER_A=subnet-0baa2e0dfd37ca274


###===========================Security-Group-creation====================================

EC2_SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name AllowAllSG \
    --description "Allow all inbound and outbound traffic" \
    --vpc-id $VPC_ID \
    --region $REGION \
    --query 'GroupId'  --output text )


echo "The created security-group-ID is:  "$EC2_SECURITY_GROUP_ID" "




aws ec2 authorize-security-group-ingress \
    --group-id $EC2_SECURITY_GROUP_ID \
    --protocol -1 \
    --port -1 \
    --cidr 0.0.0.0/0 \
    --region $REGION

#aws ec2 authorize-security-group-ingress \
#    --group-id $EC2_SECURITY_GROUP_ID \
#    --protocol -1 \
#    --port -1 \
#    --cidr ::/0 \
#    --region $REGION

echo "All the ports are open now for sg: $EC2_SECURITY_GROUP_ID "

#aws ec2 authorize-security-group-egress \
#    --group-id $EC2_SECURITY_GROUP_ID \
#    --protocol -1 \
#    --port -1 \
#    --cidr 0.0.0.0/0 \
#    --region $REGION

#aws ec2 authorize-security-group-egress \
#    --group-id $EC2_SECURITY_GROUP_ID \
#    --protocol -1 \
#    --port -1 \
#    --cidr ::/0 \
#    --region $REGION



###--------EC2 CONFIG--------------------

AMI_ID="ami-08982f1c5bf93d976"
INSTANCE_TYPE="t3.micro"
KEY_PAIR="newkey"
EC2_SECURITY_GROUP_ID="$EC2_SECURITY_GROUP_ID"
SUBNET_ID="$APP_TIER_A"
EC2_NAME="neweraInstance"
SSMROLE=ssmagentRole


## RDS Config=====================
RDS_NAME="rohurds"
DB_ENGINE=mysql
DB_VERSION="8.0.42"
DB_CLASS="db.t3.micro"
DB_NAME="databse"
DB_USERNAME="rohini"
DB_PASSWORD="redhatrohini"
DB_SECURITY_GROUP_NAME="default"
DB_SUBNET_GROUP_NAME="rohurdssubs"
SUBNET_IDS=( $DATA_TIER_A $DATA_TIER_B)

# Enable DNS support
aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --enable-dns-support

# Enable DNS hostnames
aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --enable-dns-hostnames



if ! aws rds describe-db-subnet-groups --db-subnet-group-name "$DB_SUBNET_GROUP_NAME"  --region "$REGION" >/dev/null 2>&1; then
echo "Creating DB subnet group: $DB_SUBNET_GROUP_NAME"
aws rds create-db-subnet-group \
    --db-subnet-group-name "$DB_SUBNET_GROUP_NAME" \
    --db-subnet-group-description "Rohisubs" \
    --subnet-ids "${SUBNET_IDS[@]}" \
    --region "$REGION" \
    --query "DBSubnetGroup.DBSubnetGroupName" \
    --output text
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
  --publicly-accessible \
  --region "$REGION" \
  --tags "Key=name,Value=${RDS_NAME}"

################Waiting for the rds to come up#############################33

echo "Waiting for Db to become avilable"
aws rds wait db-instance-available --db-instance-identifier "$RDS_NAME" --region "$REGION"

###=================Get the RDs endpoint########################

DB_ENDPOINT=$( aws rds describe-db-instances --db-instance-identifier "$RDS_NAME" --region "$REGION"  --query "DBInstances[0].Endpoint.Address"  --output text )

echo "RDS Instance ready at endpoint: $DB_ENDPOINT"


##===Creating the USer_Data===========

##=== Creating the User Data (with DB injected) ===========

cat > user_data.sh <<'EOF'
#!/bin/bash
set -euxo pipefail
exec > >(tee /var/log/user-data.log | logger -t user-data -s) 2>&1

echo "[user-data] Starting bootstrap at $(date --iso-8601=seconds)"

if ! command -v dnf >/dev/null 2>&1; then
  echo "[user-data] dnf not found; this script expects Amazon Linux 2023" >&2
  exit 1
fi

dnf -y update
dnf -y install httpd php php-cli php-mysqlnd

systemctl enable --now httpd

cat <<'PHPINFO' >/var/www/html/info.php
<?php
phpinfo();
PHPINFO

cat <<'PHPAPP' >/var/www/html/index.php
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
    .card { background:white; color:#333; margin:40px auto; padding:20px; border-radius:12px; max-width:600px; box-shadow:0px 4px 20px rgba(0,0,0,0.3); }
    img { max-width:100%; border-radius:12px; }
    footer { padding:20px; background:rgba(0,0,0,0.4); margin-top:40px; }
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
        mysqli_report(MYSQLI_REPORT_OFF);
        $servername = PHP_DB_HOST;
        $username   = PHP_DB_USER;
        $password   = PHP_DB_PASS;
        $dbname     = PHP_DB_NAME;

        $conn = @mysqli_connect($servername, $username, $password, $dbname);
        if (!$conn) {
          echo '❌ Database connection failed: ' . htmlspecialchars(mysqli_connect_error(), ENT_QUOTES, 'UTF-8');
        } else {
          echo '✅ Connected to database: ' . htmlspecialchars($dbname, ENT_QUOTES, 'UTF-8') . '<br>';
          $result = mysqli_query($conn, 'SELECT NOW() AS nowtime');
          if ($result) {
            $row = mysqli_fetch_assoc($result);
            if ($row && isset($row['nowtime'])) {
              echo '⏰ Current DB time: ' . htmlspecialchars($row['nowtime'], ENT_QUOTES, 'UTF-8');
            }
            mysqli_free_result($result);
          }
          mysqli_close($conn);
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

cat <<'ENVFILE' >/etc/profile.d/app-env.sh
export DB_HOST=DB_HOST_ENV
export DB_USER=DB_USER_ENV
export DB_PASS=DB_PASS_ENV
export DB_NAME=DB_NAME_ENV
ENVFILE

chown apache:apache /var/www/html/index.php /var/www/html/info.php
chmod 644 /var/www/html/*.php

systemctl restart httpd

curl -fsS http://127.0.0.1/ | head -n 20 || true
curl -fsS http://127.0.0.1/info.php | head -n 20 || true
systemctl status httpd --no-pager || true

echo "[user-data] Completed at $(date --iso-8601=seconds)"
EOF

export DB_ENDPOINT DB_NAME DB_USERNAME DB_PASSWORD
python3 - <<'PY'
import json
import os
from pathlib import Path
import shlex

values = {
    'PHP_DB_HOST': json.dumps(os.environ['DB_ENDPOINT']),
    'PHP_DB_NAME': json.dumps(os.environ['DB_NAME']),
    'PHP_DB_USER': json.dumps(os.environ['DB_USERNAME']),
    'PHP_DB_PASS': json.dumps(os.environ['DB_PASSWORD']),
    'DB_HOST_ENV': shlex.quote(os.environ['DB_ENDPOINT']),
    'DB_NAME_ENV': shlex.quote(os.environ['DB_NAME']),
    'DB_USER_ENV': shlex.quote(os.environ['DB_USERNAME']),
    'DB_PASS_ENV': shlex.quote(os.environ['DB_PASSWORD']),
}

path = Path('user_data.sh')
text = path.read_text()
for placeholder, value in values.items():
    text = text.replace(placeholder, value)
path.write_text(text)
PY
#===============CREATION-EC2-Instance============

EC2_ID=$( aws ec2 run-instances --image-id "$AMI_ID"  --subnet-id "$SUBNET_ID" --iam-instance-profile Name="$SSMROLE" --region "$REGION" --instance-type "$INSTANCE_TYPE" --key-name "$KEY_PAIR" --user-data file://user_data.sh --security-group-ids "$EC2_SECURITY_GROUP_ID" --associate-public-ip-address --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${EC2_NAME}},{Key=Region,Value=us-east-1}]" --query "Instances[0].InstanceId" --output text )


##GET Public IP####

EC2_PUBLIC_IP=$( aws ec2 describe-instances  --instance-ids "$EC2_ID" --region "$REGION" --query "Reservations[0].Instances[0].PublicIpAddress"   --output text )


# ========= SUMMARY =========
echo "----------------------------------------"
echo " EC2 Instance ID : $EC2_ID"
echo " EC2 Public IP   : $EC2_PUBLIC_IP"
echo " RDS Endpoint    : $DB_ENDPOINT"
echo " Visit Website   : http://$EC2_PUBLIC_IP/"
echo "----------------------------------------"
