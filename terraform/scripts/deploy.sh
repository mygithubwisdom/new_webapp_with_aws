#!/bin/bash
set -e

# 1. System setup
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

sudo apt-get update

sudo apt-get install -y \
  nodejs \
  git \
  awscli

# 2. App directory
sudo mkdir -p /home/ubuntu/app

sudo chown -R ubuntu:ubuntu /home/ubuntu/app

cd /home/ubuntu/app

# 3. Clone repo
git clone -b production https://github.com/mynommy/n_webapp_with_aws.git .

# Fix ownership
sudo chown -R ubuntu:ubuntu /home/ubuntu/app

# 4. Move into actual Node app folder
cd terraform/app

# 5. Install PM2
sudo npm install -g pm2

# 6. Environment variables
export PORT=${node_app_port}

export DATABASE_URL='postgresql://${db_username}:${db_password}@${db_endpoint}/${db_name}'

# Persist variables
echo "export PORT=${node_app_port}" >> /home/ubuntu/.bashrc

echo "export DATABASE_URL='postgresql://${db_username}:${db_password}@${db_endpoint}/${db_name}'" >> /home/ubuntu/.bashrc

# 7. Install dependencies
npm install

# 8. Start app
pm2 start index.js --name node-app

pm2 save