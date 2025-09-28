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
