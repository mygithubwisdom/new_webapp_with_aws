#!/bin/bash
set -e

# 1. System setup
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get update
sudo apt-get install -y nodejs git awscli

# 2. App directory
sudo mkdir -p /home/ubuntu/app
sudo chown -R ubuntu:ubuntu /home/ubuntu/app
cd /home/ubuntu/app

# 3. Clone your repo
git clone https://github.com/mygithubwisdom/new_webapp_with_aws.git .

# 4. Install PM2
sudo npm install -g pm2

# 5. Set environment variables
export PORT=${var.node_app_port}
export DATABASE_URL='postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.db.endpoint}/${var.db_name}'

# Save for future sessions
echo "export PORT=${var.node_app_port}" >> /home/ubuntu/.bashrc
echo "export DATABASE_URL='postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.db.endpoint}/${var.db_name}'" >> /home/ubuntu/.bashrc

# 6. Install and start
npm install --production
pm2 start index.js --name node-app
pm2 save
pm2 startup systemd -u ubuntu --hp /home/ubuntu