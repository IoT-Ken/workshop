#!/bin/sh
#############################################################################
# Filename: dockermonitor-configure.sh
# Date Created: 06/30/19
# Date Modified: 06/30/19
# Author: Ken Osborn
#
# Version 1.0
#
# Description: Used during Campaign Execute Phase to configure DockerMonitor.
#
# Usage: Bundled as part of package file via package-cli utility
#
# 1.0 - Ken Osborn: First version of the script.
#############################################################################

# Set current Package dir variable and change into
dirname=$(echo `echo $(dirname "$0")`)
cd $dirname

echo "This is the script: execute" >> /tmp/campaign.log

################################################################################
## Install Docker if it is not present
################################################################################
which docker

if [ $? -eq 0 ]; then
    echo "Docker is already installed, no need to install Docker" >> /tmp/campaign.log
else
    echo "Docker is not installed, installing Docker" >> /tmp/campaign.log 
    yes | sudo apt-get update
    yes | sudo apt install docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
fi

################################################################################
## Create DockerMonitor Service
################################################################################

# Configure DockerMonitor service
if ls /opt/dockermonitor; then
    echo "/opt/dockermonitor directory present, continuing to next step (extract)" >> /tmp/campaign.log
else 
    sudo mkdir /opt/dockermonitor
fi

# Copy DockerMonitor Script to run location
sudo cp dockermonitor.sh /opt/dockermonitor
sudo chmod +x /opt/dockermonitor/dockermonitor.sh

# Configure DockerMonitor Linux Service 
sudo cp dockermonitor.service /etc/systemd/system
sudo chmod 644 /etc/systemd/system/dockermonitor.service
sudo systemctl daemon-reload
sudo systemctl enable dockermonitor.service
sudo service dockermonitor restart
RESULT=$?
if [ $RESULT -eq 0 ]; then
    echo "service started successfully" >> /tmp/campaign.log
    sleep 2
else
    echo "service start failed" >> /tmp/campaign.log
    exit 1
fi
