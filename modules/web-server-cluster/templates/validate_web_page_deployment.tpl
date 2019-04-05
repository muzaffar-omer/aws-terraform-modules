#!/bin/bash

# Script to check that the web page was deployed properly
# it will try to wget the web page every 5 (default) seconds 
# until it 300 (default) seconds elapse. After that it will 
# conclude that the web page was deployed successfully

WEB_PAGE_NAME="${web_page_name}"
DOMAIN_NAME="${domain_name}"

# WEB_PAGE_NAME="index.html"
# DOMAIN_NAME="wwww.habitat-sd.com"

# Timeout in seconds
TIME_OUT="60"

TIME_COUNTER=0

# Check every 5 seconds
SLEEP_DURATION=5

while true
do
    echo "Trying wget $DOMAIN_NAME/$WEB_PAGE_NAME ..."
    if wget -O/dev/null -q $DOMAIN_NAME/$WEB_PAGE_NAME 
    then
        echo "Web page is deployed successfully !"
        break
    else
        if [ "$TIME_COUNTER" -lt "$TIME_OUT" ]
        then
            echo "Have been trying for $TIME_COUNTER seconds ... will try again after $SLEEP_DURATION seconds"
            TIME_COUNTER=$((TIME_COUNTER+SLEEP_DURATION))
            sleep $SLEEP_DURATION
        else
            echo "Failed to deploy the web page ! :("
            break
        fi
    fi
done