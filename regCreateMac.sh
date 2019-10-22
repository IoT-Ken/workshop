#!/bin/bash
# .______       _______   _______      ______ .______       _______     ___   .___________. _______ 
# |   _  \     |   ____| /  _____|    /      ||   _  \     |   ____|   /   \  |           ||   ____|
# |  |_)  |    |  |__   |  |  __     |  ,----'|  |_)  |    |  |__     /  ^  \ `---|  |----`|  |__
# |      /     |   __|  |  | |_ |    |  |     |      /     |   __|   /  /_\  \    |  |     |   __|
# |  |\  \----.|  |____ |  |__| |    |  `----.|  |\  \----.|  |____ /  _____  \   |  |     |  |____
# | _| `._____||_______| \______|     \______|| _| `._____||_______/__/     \__\  |__|     |_______|

# Author: Ken Osborn (kosborn@vmware.com)
# Version: 1.0
# Last Update: 19-Jul-19
# Purpose: Registers Gateway and Creates Gateway Credentials. Has optional (commented out)
#          section at bottom to Enroll Gateway if desired
# Requires: httpie (sudo apt-get install httpie)
#       ...(httpie is used for ease of script reading)

# Set Variables
AGENTBINPATH="/opt/vmware/iotc-agent/bin/"
TEMPLATE=G-RPi-KO
GATEWAY=TestGateway-KO-001
PULSEINSTANCE=iotc002.vmware.com
MAC_ADDR=0050563d60a0

# Retrieve User Input
read -p "User: "$'\n' USER
read -s -p "Password: "$'\n' PASSWORD

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
BearerToken=$(curl --user $USER:$PASSWORD --request GET \
--url https://$PULSEINSTANCE:443/api/tokens \
--header "Accept: application/json;api-version=$APIVersion" \
--header 'Cache-Control: no-cache' \
--header 'Connection: keep-alive' \
--header 'Content-Type: application/json' \
--header "'Host: $PULSEINSTANCE:443'" \
--header 'accept-encoding: gzip, deflate' \
--header 'cache-control: no-cache' \
| grep accessToken | awk -F ':' '{print $2}' | awk -F ',' '{print $1}' | sed -e 's/"//g' | tr -d '\n')

# Register Device
DeviceID=$(echo '{
	"name" : "'$GATEWAY'" ,
	"templateName" : "'$TEMPLATE'"
}' |  \
  http POST https://$PULSEINSTANCE:443/api/devices \
  Accept:"application/json;api-version=$APIVersion" \
  Accept-Encoding:'gzip, deflate' \
  Authorization:"Bearer $BearerToken" \
  Cache-Control:no-cache \
  Connection:keep-alive \
  Content-Length:87 \
  Content-Type:application/json \
  Host:$PULSEINSTANCE:443 \
| awk -F ':' '{print $2}' | sed -e 's/"//g' | sed -e 's/}//g')

# Create Gateway Credentials (Mac Address)
echo '{"requestParams":"{\"MAC-Address\":\"'$MAC_ADDR'\"}"}' |  \
  http POST https://$PULSEINSTANCE:443/api/device-credentials/$DeviceID \
  Accept:"application/json;api-version=$APIVersion" \
  Accept-Encoding:'gzip, deflate' \
  Authorization:"Bearer $BearerToken" \
  Cache-Control:no-cache \
  Connection:keep-alive \
  Content-Length:87 \
  Content-Type:application/json \
  Host:$PULSEINSTANCE:443

################################################################################
## Enroll (if running on actual Gateway)
################################################################################

# Enroll Gateway using Property Based (MAC Address) - Uncomment to use.
# NOTE: Pulse Agent needs to be installed before you can enroll

# sudo ${AGENTBINPATH}DefaultClient enroll --auth-type=PROPERTY --key=MAC-Address --value=$MAC_ADDR
