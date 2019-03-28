#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
  apt-get update -y
  apt-get install -y nginx
  echo "${web_page_content}" > "/var/www/html/${web_page_name}"
  echo "Installed nginx !"
