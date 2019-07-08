#!/bin/bash
# Author: Ken Osborn (kosborn@vmware.com)
# Version: 1.0
# Last Update: 27-Jun-19

################################################################################
## Set Variables
################################################################################
AGENTBINPATH="/opt/vmware/iotc-agent/bin/"
AGENTDATAPATH="/opt/vmware/iotc-agent/data/data/"
DEVICEID=$(cat ${AGENTDATAPATH}deviceIds.data | awk -F '^' '{print $1}')
TEMPLATENAME=$(cat ${AGENTDATAPATH}vGatewayTemplate.name)
PULSEINSTANCE=iotc011-pulse.vmware.com

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
BearerToken=$(curl --user iotken:VMware1! --request GET \
--url https://$PULSEINSTANCE:443/api/tokens \
--header ': ' \
--header "Accept: application/json;api-version=$APIVersion" \
--header 'Cache-Control: no-cache' \
--header 'Connection: keep-alive' \
--header 'Content-Type: application/json' \
--header "'Host: $PULSEINSTANCE:443'" \
--header 'accept-encoding: gzip, deflate' \
--header 'cache-control: no-cache' \
| grep accessToken | awk -F ':' '{print $2}' | awk -F ',' '{print $1}' | sed -e 's/"//g' | tr -d '\n')

# Modify commandFetchIntervals value to 3 seconds
echo '{
    "name": "'$TEMPLATENAME'",
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
            "id": "161bd2dd-ee27-47d2-958d-d0937960dbe1",
            "imageUrl": "/api/devices/images/161bd2dd-ee27-47d2-958d-d0937960dbe1",
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
    "orgId": "b0495a2e-92a3-4ab3-bdbf-2af2fbeeb893",
    "createdTime": 1561927998922,
    "lastUpdatedTime": 1561927998922,
    "updateVersion": 1,
    "id": "bd9a92ea-b9d9-4ca8-bb40-03b3f78f62f7"
}' |  \
  http --verify=no PUT https://$PULSEINSTANCE:443/api/device-templates/$(cat ${AGENTDATAPATH}vGatewayTemplate.id | awk -F ':' '{print $2}' | sed -e 's/"//g' | sed -e 's/}//g') \
  Accept:"application/json;api-version=$APIVersion" \
  Authorization:"Bearer $BearerToken" \
  Cache-Control:no-cache \
  Connection:keep-alive \
  Content-Type:application/json \
  Host:$PULSEINSTANCE:443 \
  accept-encoding:'gzip, deflate' \
  content-length:2611
