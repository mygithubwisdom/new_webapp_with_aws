#!/bin/bash
set -e

echo "🚀 Starting deployment..."

# Variables
EC2_HOST=$1
SSH_KEY=$2
APP_DIR="/home/ubuntu/app"

# Validation
if [ -z "$EC2_HOST" ] || [ -z "$SSH_KEY" ]; then
  echo "❌ Usage: ./deploy.sh <EC2_HOST> <SSH_KEY_PATH>"
  exit 1
fi

echo "🔑 Testing SSH connection..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@"$EC2_HOST" "echo '✅ Connected to EC2'"

echo "📦 Installing dependencies locally..."
cd app
npm ci --production

echo "📤 Copying files to EC2..."
scp -i "$SSH_KEY" -o StrictHostKeyChecking=no -r ./* ubuntu@"$EC2_HOST":"$APP_DIR"/

echo "🔄 Restarting application on EC2..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@"$EC2_HOST" << 'EOF'
  cd /home/ubuntu/app
  npm install --production
  pm2 delete node-app || true
  pm2 start index.js --name node-app
  pm2 save
  pm2 startup
EOF

echo "✅ Deployment complete!"
echo "🌐 Application URL: http://$EC2_HOST:3000"
echo "🔍 Check health: curl http://$EC2_HOST:3000/health"