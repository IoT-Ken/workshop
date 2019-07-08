#!/bin/bash
# ____    ____  __    ______   .___________.        _______. _______ .__   __.      _______.  ______   .______
# \   \  /   / |  |  /  __  \  |           |       /       ||   ____||  \ |  |     /       | /  __  \  |   _  \
#  \   \/   /  |  | |  |  |  | `---|  |----`      |   (----`|  |__   |   \|  |    |   (----`|  |  |  | |  |_)  |
#   \      /   |  | |  |  |  |     |  |            \   \    |   __|  |  . `  |     \   \    |  |  |  | |      /
#    \    /    |  | |  `--'  |     |  |        .----)   |   |  |____ |  |\   | .----)   |   |  `--'  | |  |\  \----.
#     \__/     |__|  \______/      |__|        |_______/    |_______||__| \__| |_______/     \______/  | _| `._____|
#
# Author: Ken Osborn (kosborn@vmware.com)
# Version: 1.0
# Last Update: 07-Jul-19

################################################################################
## Set Weather Variables
################################################################################
CITY=Melbourne

################################################################################
## Set Pulse Agent Variables
################################################################################
AGENTBINPATH="/opt/vmware/iotc-agent/bin/"
AGENTDATAPATH="/opt/vmware/iotc-agent/data/data/"
AGENTCONFPATH="/opt/vmware/iotc-agent/conf/"
# Retrieve Gateway and SenseHat Device ID'sfrom /opt/vmware/iotc-agent/data/data/deviceIDs.data 
VGATEWAYID=$(cat ${AGENTDATAPATH}deviceIds.data | awk -F '^' '{print $1}')
VIOTSENSORID=$(cat -v /opt/vmware/iotc-acgent/data/data/deviceIds.data | awk -F '^' '{print $2}' | awk -F '@' '{print $2}')

while true; do
# Set and Get Python Return variables for Temperature, Humidity and Barometric Pressure
TEMP=$(curl wttr.in/$CITY?format=3 | awk -F '+' '{print $2}' | awk -F '°' '{print $1}')
HUMIDITY=$(curl wttr.in/Sydney?format="%h" | awk -F '%' '{print $1}') 
PRESSURE=$(curl wttr.in/Sydney?format="%P" | awk -F 'h' '{print $1}')

# Utilize iotc-agent-cli to send metrics and properties to Pulse
sudo /opt/vmware/iotc-agent/bin/iotc-agent-cli send-metric --device-id=$VIOTSENSORID --name=Temperature --type=double --value=$TEMP
sudo /opt/vmware/iotc-agent/bin/iotc-agent-cli send-metric --device-id=$VIOTSENSORID --name=Humidity --type=double --value=$HUMIDITY
sudo /opt/vmware/iotc-agent/bin/iotc-agent-cli send-metric --device-id=$VIOTSENSORID --name=BarometricPressure --type=double --value=$PRESSURE

# Retrieve Virtaul Sensor Uptime
UP=$(uptime -p | sed -e 's/ /-/g' | sed -e 's/,-/,/g')
# Send Virtual Sensor Uptime System Property
sudo /opt/vmware/iotc-agent/bin/iotc-agent-cli send-properties --device-id=$VIOTSENSORID --key=uptime --value=$UP

# Configure While Loop Interval
sleep 30
done
