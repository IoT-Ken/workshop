#!/bin/bash
# ____    ____  _______      ___   .___________. ___________    __    ____  ___   ____    ____    .______   .______       _______ .______
# \   \  /   / /  _____|    /   \  |           ||   ____\   \  /  \  /   / /   \  \   \  /   /    |   _  \  |   _  \     |   ____||   _  \
#  \   \/   / |  |  __     /  ^  \ `---|  |----`|  |__   \   \/    \/   / /  ^  \  \   \/   /     |  |_)  | |  |_)  |    |  |__   |  |_)  |
#   \      /  |  | |_ |   /  /_\  \    |  |     |   __|   \            / /  /_\  \  \_    _/      |   ___/  |      /     |   __|  |   ___/
#    \    /   |  |__| |  /  _____  \   |  |     |  |____   \    /\    / /  _____  \   |  |        |  |      |  |\  \----.|  |____ |  |
#     \__/     \______| /__/     \__\  |__|     |_______|   \__/  \__/ /__/     \__\  |__|        | _|      | _| `._____||_______|| _|

# Author: Ken Osborn (kosborn@vmware.com)
# Version: 1.1
# Last Update: 31-Jul-19
# Modification Note(s): Shortened commands necessary to create directory

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
    sudo mkdir -p $AGENTDATAPATH
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

# Write Docker Template Name to file so we can use during DockerMonitor Campaign Lesson later
echo "DockerTemplate-$firstname-$number" > ${AGENTDATAPATH}//DockerTemplate.name

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
                    "factor": 1.0
                },
                {
                    "valueType": "DOUBLE",
                    "timeInterval": 300,
                    "batchSize": 1000,
                    "displayUnit": "%",
                    "displayName": "Memory-Usage",
                    "name": "Memory-Usage(DOUBLE)",
                    "factor": 1.0
                },
                {
                    "valueType": "DOUBLE",
                    "timeInterval": 300,
                    "batchSize": 1000,
                    "displayUnit": "%",
                    "displayName": "Disk-Usage",
                    "name": "Disk-Usage(DOUBLE)",
                    "factor": 1.0
                }
            ],
    "allowedCommands": [
                {
                    "command": "SSH",
                    "name": "SSH Enable",
                    "arguments": [
                        {
                            "name": "args",
                            "type": "STRING",
                            "value": [
                                "enable"
                            ]
                        }
                    ],
                    "asRoot": true
                },
                {
                    "command": "SSH",
                    "name": "SSH Disable",
                    "arguments": [
                        {
                            "name": "args",
                            "type": "STRING",
                            "value": [
                                "disable"
                            ]
                        }
                    ],
                    "asRoot": true
                },
                {
                    "command": "REBOOT",
                    "name": "REBOOT",
                    "asRoot": true
                }        
            ],
    "enrollmentProvider": {
                "type": "BASIC",
                "providerConfig": "{}"
            },
	"imageDetails": [
                {
                    "id": "5f2566d3-dcd4-42dc-bde7-d637d6030a22",
                    "imageUrl": "/api/devices/images/b5f36ba0-e09d-4d22-ab38-329650403620",
                    "sourceType": "base64"
                }
            ],
    "settings": [
                {
                    "category": "iotc-agent",
                    "settings": {
                        "commandFetchIntervalSeconds": 30,
                        "maxNumberOfClients": 5,
                        "agentLogLevel": 3,
                        "metricsIntervalSeconds": 300
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
echo Type the following commands to onboard your vGateway using BASIC Auth >> onboardSyntax.txt
echo 1')' "./DefaultClient enroll --auth-type=BASIC --template=vGatewayTemplate-$firstname-$number --name=vGateway-$firstname-$number --username=<your username@pulse.local>" >> onboardSyntax.txt

#####################################################################################
## Enroll Gateway (Not used during the 'Getting Started' Lesson)
#####################################################################################
#sudo echo -n "VMware1!" > /tmp/passwd
#sudo ${AGENTBINPATH}DefaultClient enroll --auth-type=BASIC --template=$TEMPLATE --name=${HOSTNAME} --username=ken@iotken.com --password=file:/tmp/passwd

#####################################################################################
## Notify Student that Script is complete
#####################################################################################
echo Script is complete, please refer back to your Lab Guide for next Steps

