#!/bin/bash

# This script is for PADAVAN
# Need curl
# Modify from https://gist.github.com/benkulbertis
# Thanks https://github.com/n0raml/cloudflare-ddns-v4v6

# CHANGE THESE
auth_email="user@example.com"
auth_key="" # found in cloudflare account settings
zone_name="example.com"
record_name="www.example.com"

# Wechat Notification
SCTKEY=

# MAYBE CHANGE THESE
TTL=120
ip=$(curl -s https://api.ipify.org/)
ip_file="ip.txt"
id_file="cloudflare.ids"
log_file="/tmp/cloudflare.log"

# LOGGER
log() {
    if [ "$1" ]; then
        echo -e "[$(date)] - $1" >> $log_file
    fi
}

# SCRIPT START
log "Check Initiated"

if [ -f $ip_file ]; then
    old_ip=$(cat $ip_file)
    if [ $ip == $old_ip ]; then
        echo "IP has not changed."
        exit 0
    fi
fi

if [ -f $id_file ] && [ $(wc -l $id_file | cut -d " " -f 1) == 2 ]; then
    zone_identifier=$(head -1 $id_file)
    record_identifier=$(tail -1 $id_file)
else
    zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" | cut -b 19-50)
    record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json"  | cut -b 19-50)
    echo "$zone_identifier" > $id_file
    echo "$record_identifier" >> $id_file
fi

update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" --data "{\"id\":\"$zone_identifier\",\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"$ip\",\"ttl\":$TTL}")

if [[ $update == *"\"success\":false"* ]]; then
    message="API UPDATE FAILED. DUMPING RESULTS:\n$update"
    log "$message"
    echo -e "$message"
    curl -s -X POST "https://sctapi.ftqq.com/$SCTKEY.send?title=CloudFlare%20API%20update%20failed." 2>&1 >/dev/null
    exit 1 
else
    message="IP changed to: $ip"
    echo "$ip" > $ip_file
    log "$message"
    echo "$message"
    curl -s -X POST "https://sctapi.ftqq.com/$SCTKEY.send?title=CloudFlare%20IP%20changed&desp=$ip" 2>&1 >/dev/null
fi
