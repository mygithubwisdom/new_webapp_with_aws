locals {
  user_data = <<-EOT
    #!/bin/bash
    set -e
    
    # 1. System Updates & Node.js 18 Installation
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get update
    sudo apt-get install -y nodejs git awscli

    # 2. Setup App Directory
    sudo mkdir -p /home/ubuntu/app
    sudo chown -R ubuntu:ubuntu /home/ubuntu/app
    cd /home/ubuntu/app

    # 3. Initial Code Pull (Replace with your Repo URL)
    git clone https://github.com/Wizzylaface/your-new-app.git .
    
    # 4. Install Global Tools
    sudo npm install -g pm2

    # 5. Set Environment Variables for the App
    echo "export PORT=${var.node_app_port}" >> /home/ubuntu/.bashrc
    echo "export DATABASE_URL='postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.db.endpoint}/${var.db_name}'" >> /home/ubuntu/.bashrc
    
    # 6. Initial Start
    npm install --production
    pm2 start index.js --name node-app
    pm2 save
    pm2 startup
  EOT
}