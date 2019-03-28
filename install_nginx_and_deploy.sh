#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
apt-get update -y
apt-get install -y nginx
echo "${web_page_content}" > "/var/www/html/${web_page_name}"
echo "Installed nginx !"
echo "Installing cerbot ..."
apt-get install -y software-properties-common
add-apt-repository universe
add-apt-repository ppa:certbot/certbot
apt-get update -y
apt-get install -y certbot python-certbot-nginx 
certbot run --nginx --non-interactive  --domain ${domain_name} --verbose \ 
--webroot-path /var/www/html/ --agree-tos
echo "Installed the certificate !"