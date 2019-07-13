#!/bin/sh
#############################################################################
# Filename: get-commands.sh
# Date Created: 07/13/19
# Date Modified: 07/13/19
# Author: Ken Osborn
#
# Version 1.0
#
# Description: Used during Workshop to force Pulse Agent to phone home every
#              10 seconds during Campaign Lesson.
#
# Usage: ./get-commands.sh
#
# 1.0 - Ken Osborn: First version of the script.
#############################################################################

################################################################################
## Set Variables
################################################################################
AGENTBINPATH="/opt/vmware/iotc-agent/bin/"

#Start While Loop
while true; do

#Issue get-commands using DefaultClient
echo "Initiating ./DefaultClient get-commands"
${AGENTBINPATH}DefaultClient get-commands

# Configure Interval
sleep 15
done
