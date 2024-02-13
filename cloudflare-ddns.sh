#!/bin/bash

IP=""
NAME=""
CDN=""
ZONE_ID=""
DNS_RECORD_ID=""
TOKEN=""

DNS_IP=""
DNS_SERVER=""

DNS_RECORD=""


function setEnv(){
  EnvFile=${0/%.sh/.env}
  if ! [ -e $EnvFile ];then
    echo EnvFile $EnvFile not exist. please check.
    exit 1
  fi

  source $EnvFile
}

function preCheck(){
  if [ $USE_DNS_SERVER = 'true' ];then
    ping -w 5 $DNS_SERVER
    if [ $? != 0 ];then
      echo "PreCheck failed that DNS Server $DNS_SERVER is not reachable."
      exit 1
    fi
  fi
}

function getIp(){
  IP=`curl -s ipinfo.io | grep -w ip | awk '{print $2}' | awk -F\" '{print $2}'`
}

function getDnsIp(){
  if [ $USE_DNS_SERVER = 'true' ];then
    DNS_IP=`dig @${DNS_SERVER} ${NAME}.${CDN} +short`
  else
    DNS_IP=`curl -s --request GET \
    --url https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${DNS_RECORD_ID} \
    --header "Authorization: Bearer $TOKEN" | jq | grep -w content | awk '{print $2}' | awk -F\" '{print $2}'`
  fi
}

function updateIp(){
  if [ $IP = $DNS_IP ];then
    echo "DNS IP $DNS_IP is updated that no need to update."
    return
  fi

  echo "Updating DNS IP from $DNS_IP to $IP."
  curl --request PUT \
    --url https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${DNS_RECORD_ID} \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $TOKEN" \
    --data "$(jq -c -n --arg IP "$IP" --arg NAME "$NAME" "$DNS_RECORD")"
}

function main(){
  setEnv
  preCheck
  getIp
  getDnsIp
  updateIp
}

main
#<<<END
