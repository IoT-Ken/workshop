#!/bin/bash
# ____    ____  _______      ___   .___________. ___________    __    ____  ___   ____    ____    .______   .______       _______ .______
# \   \  /   / /  _____|    /   \  |           ||   ____\   \  /  \  /   / /   \  \   \  /   /    |   _  \  |   _  \     |   ____||   _  \
#  \   \/   / |  |  __     /  ^  \ `---|  |----`|  |__   \   \/    \/   / /  ^  \  \   \/   /     |  |_)  | |  |_)  |    |  |__   |  |_)  |
#   \      /  |  | |_ |   /  /_\  \    |  |     |   __|   \            / /  /_\  \  \_    _/      |   ___/  |      /     |   __|  |   ___/
#    \    /   |  |__| |  /  _____  \   |  |     |  |____   \    /\    / /  _____  \   |  |        |  |      |  |\  \----.|  |____ |  |
#     \__/     \______| /__/     \__\  |__|     |_______|   \__/  \__/ /__/     \__\  |__|        | _|      | _| `._____||_______|| _|

# Author: Ken Osborn (kosborn@vmware.com)
# Version: 1.0
# Last Update: 27-Jun-19

################################################################################
## Set Variables
################################################################################
AGENTBINPATH="/opt/vmware/iotc-agent/bin/"
AGENTDATAPATH="/opt/vmware/iotc-agent/data/data/"
AGENTCONFPATH="/opt/vmware/iotc-agent/conf/"
TEMPLATE=vGatewayTemplate
PULSEINSTANCE=iotc003.vmware.com

################################################################################
## User Interaction
################################################################################
# Ask User for their first name
clear
echo Hello, who do I have the pleasure of interacting with today?
read -p 'Please enter your First Name: ' firstname
echo It\'s nice to meet you, $firstname!
echo Please enter your favorite single digit number
read -p 'Number: ' number
echo Thank you, we are now going to programatically create a few things in the Pulse Console using Rest API calls.
read -n 1 -s -r -p "Press any key to continue"

################################################################################
## Created AGENTDATAPATH directories if they don't exist already
################################################################################
if ls $AGENTDATAPATH; then
    echo "$AGENTDATAPATH directory already present"
else 
    sudo mkdir /opt/vmware
    sudo mkdir /opt/vmware/iotc-agent
    sudo mkdir /opt/vmware/iotc-agent/data
    sudo mkdir /opt/vmware/iotc-agent/data/data
fi

################################################################################
## Rest API Calls to Create Pulse Templates
################################################################################

# Identify current Pulse API version
APIVersion=$(curl --request GET \
  --url https://$PULSEINSTANCE:443/api/versions \
  --header 'Accept: application/json;api-version=1.0' \
  --header 'Cache-Control: no-cache' \
  --header 'Connection: keep-alive' \
  --header 'Content-Type: application/json' \
  --header "'Host: $PULSEINSTANCE:443'" \
  --header 'accept-encoding: gzip, deflate' \
| awk -F ':' '{print $2'} | awk -F ',' '{print $1}' | sed -e 's/"//g')

# Use Basic Auth to retrieve Bearer Token
BearerToken=$(curl --user ausworkshop@iotken.com:VMware1! --request GET \
--url https://$PULSEINSTANCE:443/api/tokens \
--header "Accept: application/json;api-version=$APIVersion" \
--header 'Cache-Control: no-cache' \
--header 'Connection: keep-alive' \
--header 'Content-Type: application/json' \
--header "'Host: $PULSEINSTANCE:443'" \
--header 'accept-encoding: gzip, deflate' \
--header 'cache-control: no-cache' \
| grep accessToken | awk -F ':' '{print $2}' | awk -F ',' '{print $1}' | sed -e 's/"//g' | tr -d '\n')

# Create Docker Template (Httpie must be installed: sudo apt-get install httpie)
echo '{
    "name": "DockerTemplate-'$firstname'-'$number'",
    "deviceType": "THING",
    "systemProperties": [
                {
                    "name": "ip-address"
                },
                {
                    "name": "container-pid"
                },
                {
                    "name": "container-status"
                },
                {
                    "name": "image-id"
                },
                {
                    "name": "image-name"
                },
                {
                    "name": "container-name"
                }
            ],
            "allowedMetrics": [
                {
                    "valueType": "DOUBLE",
                    "timeInterval": 60,
                    "batchSize": 1000,
                    "displayName": "CPU-Utilization",
                    "name": "CPU-Utilization(DOUBLE)",
                    "factor": 1
                },
                {
                    "valueType": "BOOLEAN",
                    "timeInterval": 60,
                    "batchSize": 1000,
                    "displayName": "Container-Runstate",
                    "name": "Container-Runstate(BOOLEAN)"
                }
            ],
            "imageDetails": [
                {
                    "id": "e713892f-ed87-42af-b5ac-0d85f8a27191",
                    "imageUrl": "/api/devices/images/e713892f-ed87-42af-b5ac-0d85f8a27191",
                    "sourceType": "base64"
                }
    ]
}' |  \
  http --verify=no POST https://$PULSEINSTANCE:443/api/device-templates \
  Accept:"application/json;api-version=$APIVersion" \
  Authorization:"Bearer $BearerToken" \
  Cache-Control:no-cache \
  Connection:keep-alive \
  Content-Type:application/json \
  Host:$PULSEINSTANCE:443 \
  accept-encoding:'gzip, deflate' \
  content-length:2739 \
> ${AGENTDATAPATH}/DockerTemplate.id

# Set Variable for newly Created DockerTemplate, this is used to create Parent\Child
# relationship when creating vGateway Template
DOCKERTEMPLATEID=$(cat ${AGENTDATAPATH}/DockerTemplate.id | awk -F ':' '{print $2}' | sed -e 's/"//g' | sed -e 's/}//g')

# Create vGateway Template (Httpie must be installed: sudo apt-get install httpie)
echo '{
	"name": "vGatewayTemplate-'$firstname'-'$number'",
    "deviceType": "GATEWAY",
    "systemProperties": [
                {
                    "name": "os-sysname"
                },
                {
                    "name": "os-machine"
                },
                {
                    "name": "os-release"
                },
                {
                    "name": "ssh"
                },
                {
                    "name": "iotc-agent-version"
                }
            ],
    "allowedMetrics": [
                {
                    "valueType": "DOUBLE",
                    "timeInterval": 300,
                    "batchSize": 1000,
                    "displayUnit": "%",
                    "displayName": "CPU-Usage",
                    "name": "CPU-Usage(DOUBLE)",
                    "factor": 1
                },
                {
                    "valueType": "DOUBLE",
                    "timeInterval": 300,
                    "batchSize": 1000,
                    "displayUnit": "%",
                    "displayName": "Memory-Usage",
                    "name": "Memory-Usage(DOUBLE)",
                    "factor": 1
                },
                {
                    "valueType": "DOUBLE",
                    "timeInterval": 300,
                    "batchSize": 1000,
                    "displayUnit": "%",
                    "displayName": "Disk-Usage",
                    "name": "Disk-Usage(DOUBLE)",
                    "factor": 1
                }
            ],
	"allowedCommands": [
                {
                    "command": "SSH",
                    "name": "SSH Enable",
                    "arguments": [
                        "enable"
                    ],
                    "asRoot": true
                },
                {
                    "command": "SSH",
                    "name": "SSH Disable",
                    "arguments": [
                        "disable"
                    ],
                    "asRoot": true
                },
                {
                    "command": "REBOOT",
                    "name": "REBOOT",
                    "arguments": [],
                    "asRoot": true
                }
            ],
	"enrollmentProvider": {
                "type": "JWT_NATIVE",
                "providerConfig": "{\"expiryTime\":57600}"
            },
	"imageDetails": [
                {
                    "id": "b5f36ba0-e09d-4d22-ab38-329650403620",
                    "imageUrl": "/api/devices/images/b5f36ba0-e09d-4d22-ab38-329650403620",
                    "sourceType": "base64"
                }
            ],
	"settings": [
                {
                    "category": "iotc-agent",
                    "settings": {
                        "commandFetchIntervalSeconds": 3,
                        "maxNumberOfClients": 5,
                        "metricsDiskStoreKB": 262144,
                        "grpcEnabled": 1,
                        "agentLogLevel": 6
                    },
                    "finalSettings": {}
                }
            ],
            "childTemplates": [
                "'$DOCKERTEMPLATEID'"
            ]
}' |  \
  http --verify=no POST https://$PULSEINSTANCE:443/api/device-templates \
  Accept:"application/json;api-version=$APIVersion" \
  Authorization:"Bearer $BearerToken" \
  Cache-Control:no-cache \
  Connection:keep-alive \
  Content-Type:application/json \
  Host:$PULSEINSTANCE:443 \
  accept-encoding:'gzip, deflate' \
  content-length:2739 \
> ${AGENTDATAPATH}/$TEMPLATE.id

# Write Gateway Template Name to file so we can use this to modifyCommandFetchInterval later
echo "vGatewayTemplate-$firstname-$number" > ${AGENTDATAPATH}//$TEMPLATE.name

######################################################################################
## Write Onboard Syntax to Text File that Students can reference during Onboard Lesson
######################################################################################
echo Type the following commands to cd into the Pulse Agent directory, >> onboardSyntax.txt
echo and utilize the DefaultClient to onboard your vGateway using BASIC Auth >> onboardSyntax.txt
echo 1')' cd /opt/vmware/iotc-agent/bin >> onboardSyntax.txt
echo 2')' "./DefaultClient enroll --auth-type=BASIC --template=vGatewayTemplate-$firstname-$number --name=vGateway-$firstname-$number --username=<your username@pulse.local>" >> onboardSyntax.txt

#####################################################################################
## Enroll Gateway (Not used during the 'Getting Started' Lesson)
#####################################################################################
#sudo echo -n "VMware1!" > /tmp/passwd
#sudo ${AGENTBINPATH}DefaultClient enroll --auth-type=BASIC --template=$TEMPLATE --name=${HOSTNAME} --username=ken@iotken.com --password=file:/tmp/passwd

#####################################################################################
## Notify Student that Script is complete
#####################################################################################
echo Script is complete, please refer back to your Lab Guide for next Steps
read -n 1 -s -r -p "Press any key to continue"
