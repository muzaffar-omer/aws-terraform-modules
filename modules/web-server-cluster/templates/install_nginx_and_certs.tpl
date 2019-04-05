#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
apt-get update -y
apt-get install -y nginx
echo "${web_page_content}" > "/var/www/html/${web_page_file_name}"
echo "Installed nginx !"
mkdir /root/certs/
mv /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.backup
echo "${nginx_config}" > /etc/nginx/sites-enabled/default
echo "${certificate_pem}" > /root/certs/certificate
echo "${issuer_pem}" >> /root/certs/certificate
echo "${certificate_key_pem}" > /root/certs/certificate_key

service nginx restart 
echo "Installed the certificate !"