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

# Set Weather City
CITY=Melbourne

# Set Pulse Agent Variables
AGENTBINPATH="/opt/vmware/iotc-agent/bin/"
AGENTDATAPATH="/opt/vmware/iotc-agent/data/data/"

# Retrieve IoT Sensor Device ID from /opt/vmware/iotc-agent/data/data/deviceIDs.data 
VIOTSENSORID=$(cat -v ${AGENTDATAPATH}deviceIds.data | awk -F '^' '{print $2}' | awk -F '@' '{print $2}')

while true; do
# Set and Get Python Return variables for Temperature, Humidity and Barometric Pressure
TEMP=$(curl wttr.in/$CITY?format=3 | awk -F '+' '{print $2}' | awk -F '°' '{print $1}')
HUMIDITY=$(curl wttr.in/$CITY?format="%h" | awk -F '%' '{print $1}') 
PRESSURE=$(curl wttr.in/$CITY?format="%P" | awk -F 'h' '{print $1}')

# Utilize DefaultClient to send metrics and properties to Pulse
sudo ${AGENTBINPATH}DefaultClient send-metric --device-id=$VIOTSENSORID --name=Temperature --type=double --value=$TEMP
sudo ${AGENTBINPATH}DefaultClient send-metric --device-id=$VIOTSENSORID --name=Humidity --type=double --value=$HUMIDITY
sudo ${AGENTBINPATH}DefaultClient send-metric --device-id=$VIOTSENSORID --name=BarometricPressure --type=double --value=$PRESSURE

# Configure While Loop Interval
sleep 30
done
