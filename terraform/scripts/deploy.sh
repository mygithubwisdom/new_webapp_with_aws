#!/bin/bash
set -e
    
#1. System setup
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt-get update
apt-get install -y nodejs git awscli
    
# 2. App directory setup
mkdir -p /home/ubuntu/app
chown -R ubuntu:ubuntu /home/ubuntu/app

# Fix ownership
chmod 755 /home/ubuntu/app
cd /home/ubuntu/app
    
# 3. Clone repo and setup app
sudo -u ubuntu git clone -b production https://github.com/mygithubwisdom/new_webapp_with_aws.git  .
 
# 4. Move into actual Node app folder 
cd terraform/app
    
# 5. Install PM2 and start the app
sudo -u ubuntu npm install --production
npm install -g pm2
    
# 6. Environment variables
export NODE_ENV=production
export PORT=${node_app_port}
export DATABASE_URL='postgresql://${db_username}:${db_password}@${db_endpoint}/${db_name}'
    
# Persist variables
echo "export PORT=${node_app_port}" | sudo -u ubuntu tee -a /home/ubuntu/.bashrc > /dev/null
echo "export DATABASE_URL='postgresql://${db_username}:${db_password}@${db_endpoint}/${db_name}'" | sudo -u ubuntu tee -a /home/ubuntu/.bashrc > /dev/null
    
# 8. Start app with PM2
sudo -u ubuntu pm2 start index.js --name node-app
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu
sudo -u ubuntu pm2 save
    
echo "Deployment complete"
