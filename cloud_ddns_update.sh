#!/usr/bin/env bash

#Static variables
readonly NO_CONFIG_ERROR=1      #no config file named config.json
readonly NO_IP_ERROR=2          #no arguments on the original call
readonly NOT_IPV4_ERROR=3       #argument provided is not an IPv4
readonly ZONE_NON_EXISTENT=4    #the zone provided in the config was not found in cloudflare
readonly DOMAIN_NOT_FOUND=5     #At least one domain provided was not found or is not of the provided type
readonly workpath="$HOME/.local/bin/cf_ddns_updater"

#variables
declare type
declare zone
declare api_key
declare -a domains
declare -a domain_ids
declare domains_length
declare ip
#$1 must be the ip you want to update to

get_configs () {
    if [ ! -f "$workpath/config.json" ]; then
        exit_on_error $NO_CONFIG_ERROR
	fi
	
	configstring=$(cat "$workpath/config.json")
	api_key=$(jq -r '.api_key' <(echo $configstring))
	type=$(jq -r '.type' <(echo $configstring))
	zone=$(jq -r '.zone' <(echo $configstring))
	domains=$(jq '.domains' <(echo $configstring))
	domains_length=$(jq '. | length' <(echo $domains))
}

ip_to_send_check () {
    if [ "$#" -eq 0 ]; then
        exit_on_error $NO_IP_ERROR
    elif [ -z $(grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}$" <<< $1) ]; then
        exit_on_error $NOT_IPV4_ERROR
    fi
    ip=$(echo $1)
}

get_zone_id () {
	available_zones=$( curl -X GET \
	--url https://api.cloudflare.com/client/v4/zones \
	--header "Authorization: Bearer $api_key" \
	--header 'Content-Type: application/json'	)

	zone_id=$(jq -r --arg zone "$zone" \
	'.result[] | if ( .name == $zone ) then .id else empty end'  <(echo $available_zones))

	if [ -z "$zone_id" ]; then
		exit_on_error $ZONE_NON_EXISTENT
	fi
}


get_domain_ids () {
    declare dns_records_length
    declare dns_record

    #get the dns records from cloudflare using the ZONE_ID_token
    available_domains=$( curl -X GET \
    --url "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
    -H "Authorization: Bearer $api_key" \
    -H 'Content-Type: application/json' )

    domain_ids=$(jq -r --argjson domains "$domains" --arg type "$type" \
    '.result[] | if ( .name == $domains.[] and .type == $type ) then .id else empty end'  <(echo $available_domains))
    domain_ids=($domain_ids)
    if [ ${#domain_ids[@]} -ne $domains_length ]; then
        exit_on_error $DOMAIN_NOT_FOUND
    fi
}

set_DNS_records () {
    for id in "${domain_ids[@]}"
    do
        update+=$( curl -X PATCH \
        --url "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/${id}" \
        -H "Authorization: Bearer $api_key" \
        -H 'Content-Type: application/json' \
        --data "{ \"content\": \"$ip\" }" )
    done

    mkdir "$workpath/logs"
    echo "$(date) ${update[@]}" >> "$workpath/logs/update.log"
}

exit_on_error () {
    case "$1" in
        $NO_CONFIG_ERROR)
            echo "no config file named config.json provided" 1>&2
            exit $NO_CONFIG_ERROR   ;;
        $NO_IP_ERROR)
            echo "no arguments on the original call" 1>&2
            exit $NO_IP_ERROR   ;;
        $NOT_IPV4_ERROR)
            echo "argument provided is not an IPv4" 1>&2
            exit $NOT_IPV4_ERROR   ;;
        $ZONE_NON_EXISTENT)
            echo "the zone provided in the config was not found in cloudflare" 1>&2
            exit $ZONE_NON_EXISTENT   ;;
        $DOMAIN_NOT_FOUND)
            echo "At least one domain provided was not found or is not of the provided type" 1>&2
            exit $DOMAIN_NOT_FOUND   ;;
    esac
}

get_configs
ip_to_send_check $1
get_zone_id
get_domain_ids
set_DNS_records

exit 0
