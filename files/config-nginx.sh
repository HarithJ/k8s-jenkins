#!/bin/bash

setupNginxServer () {
  printf '=================================== Setting up Nginx server ============================================ \n'

  createNginxSettingFile
  sudo mv /home/ubuntu/nginx-jenkins /etc/nginx/sites-available/
  sudo ln -s /etc/nginx/sites-available/nginx-jenkins /etc/nginx/sites-enabled
  sudo rm /etc/nginx/sites-available/default
  sudo rm /etc/nginx/sites-enabled/default
  sudo nginx -t
  sudo systemctl restart nginx

  sudo ufw allow 'Nginx Full'
}

# Create Nginx settings file that will connect to the app
createNginxSettingFile () {
  ipaddress=$(curl "http://169.254.169.254/latest/meta-data/public-ipv4")
  cat > /home/ubuntu/nginx-jenkins <<EOF
server {
    listen 80;
    server_name ${ipaddress};

    location / {
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$http_host;
        proxy_pass  http://127.0.0.1:8080;
    }
}
EOF
}

setupNginxServer
