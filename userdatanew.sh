#!/bin/bash
set -euxo pipefail
exec > >(tee /var/log/user-data.log | logger -t user-data -s) 2>&1

echo "[user-data] Starting bootstrap at $(date --iso-8601=seconds)"

# --- Configuration (replace placeholders before launch) ---
DB_HOST="newdrdsbase.c49gci4ay5yo.us-east-1.rds.amazonaws.com"
DB_NAME="databse"
DB_USER="rohini"
DB_PASS="redhat"

# --- Package installation ---
if ! command -v dnf >/dev/null 2>&1; then
  echo "[user-data] dnf not found; this script expects Amazon Linux 2023" >&2
  exit 1
fi

dnf -y update

dnf -y install httpd php php-cli php-mysqlnd

systemctl enable --now httpd

# --- Deploy application ---
cat <<'PHPINFO' >/var/www/html/info.php
<?php
phpinfo();
PHPINFO

cat <<PHPAPP >/var/www/html/index.php
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
        $servername = getenv('DB_HOST') ?: '%s';
        $username   = getenv('DB_USER') ?: '%s';
        $password   = getenv('DB_PASS') ?: '%s';
        $dbname     = getenv('DB_NAME') ?: '%s';

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

# replace placeholders with actual configuration values
printf -v DB_ESCAPED '%s' "$DB_HOST"
DB_ESCAPED=${DB_ESCAPED//"/\"}
perl -pi -e "s/%s/$DB_ESCAPED/" /var/www/html/index.php

for VAR in DB_USER DB_PASS DB_NAME; do
  VALUE=${!VAR}
  VALUE=${VALUE//"/\"}
  perl -pi -e "s/%s/$VALUE/" /var/www/html/index.php
done

cat <<'ENVFILE' >/etc/profile.d/app-env.sh
export DB_HOST="$DB_HOST"
export DB_USER="$DB_USER"
export DB_PASS="$DB_PASS"
export DB_NAME="$DB_NAME"
ENVFILE

chown apache:apache /var/www/html/index.php /var/www/html/info.php

systemctl restart httpd

# --- Health checks ---
curl -fsS http://127.0.0.1/ | head -n 20
curl -fsS http://127.0.0.1/info.php | head -n 20

systemctl status httpd --no-pager

echo "[user-data] Completed at $(date --iso-8601=seconds)"
