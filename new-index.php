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
        mysqli_report(MYSQLI_REPORT_OFF);
        $servername = 'newdrdsbase.c49gci4ay5yo.us-east-1.rds.amazonaws.com';
        $username = 'rohini';
        $password = 'redhat';
        $dbname = 'databse';

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
