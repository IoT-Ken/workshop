#!/bin/bash
# Author: Ken Osborn (kosborn@vmware.com)
# Version: 1.0
# Last Update: 27-Jun-19

################################################################################
## Set Variables
################################################################################
AGENTBINPATH="/opt/vmware/iotc-agent/bin/"
AGENTDATAPATH="/opt/vmware/iotc-agent/data/data/"
TEMPLATENAME=$(cat /opt/vmware/iotc-agent/data/data/vGatewayTemplate.name)
PULSEINSTANCE=iotc003.vmware.com

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
--header ': ' \
--header "Accept: application/json;api-version=$APIVersion" \
--header 'Cache-Control: no-cache' \
--header 'Connection: keep-alive' \
--header 'Content-Type: application/json' \
--header "'Host: $PULSEINSTANCE:443'" \
--header 'accept-encoding: gzip, deflate' \
| grep accessToken | awk -F ':' '{print $2}' | awk -F ',' '{print $1}' | sed -e 's/"//g' | tr -d '\n')

# Modify commandFetchIntervals value to 3 seconds
echo '{
            "name": "'$TEMPLATENAME'",
            "deviceType": "GATEWAY",
            "enrollmentProvider": {
                "type": "JWT_NATIVE",
                "providerConfig": "{\"expiryTime\":57600}"
            },
            "settings": [
                {
                    "category": "iotc-agent",
                    "settings": {
                        "commandFetchIntervalSeconds": 300,
                        "maxNumberOfClients": 5,
                        "metricsDiskStoreKB": 262144,
                        "grpcEnabled": 1,
                        "agentLogLevel": 6
                    },
                    "finalSettings": {}
                }
            ]
}' |  \
  http --verify=no PUT https://$PULSEINSTANCE:443/api/device-templates/$(cat ${AGENTDATAPATH}vGatewayTemplate.id | awk -F ':' '{print $2}' | sed -e 's/"//g' | sed -e 's/}//g') \
  Accept:'application/json;api-version=1.0' \
  Authorization:"Bearer $BearerToken"
  
echo "Modified commandFetchInterval for $TEMPLATENAME"
echo "If $TEMPLATENAME is not the Template that you are currently using for your Gateway, this change will not have any effect."
