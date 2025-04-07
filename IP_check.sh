#!/usr/bin/env bash

#version=1.0

readonly workpath="$HOME/.local/bin/cf_ddns_updater"
readonly get_public_ip_URL=https://cloudflare.com/cdn-cgi/trace	#Whatsmyip page
readonly saved_public_ip_file="$workpath/logs/current_ip.log"
readonly ip_log="$workpath/logs/ip.log"
readonly NOT_IPV4_ERROR=1	#curl error, IP didn't download correctly

declare saved_public_ip=0
declare real_public_ip

get_current_ip() {
	real_public_ip=$(curl $get_public_ip_URL | awk -F '=' '/ip/ {print $2}')

	#check if the data in file is in fact an IPv4
	real_public_ip=$(echo $real_public_ip | grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}$")
	if [ -z $real_public_ip ]; then
		echo "the downloaded IP is not correctly formatted, not IPV4" 1>&2
		exit $NOT_IPV4_ERROR
	fi
}

#Get last known public IP and check if it's equal to the web one
check_saved_ip_uptodate() {
	if [ -f "$saved_public_ip_file" ]; then
		saved_public_ip=$(cat $saved_public_ip_file)
	fi

	if [ ! $saved_public_ip = $real_public_ip ]; then
		if [ ! -d "$workpath/logs" ]; then
			mkdir "$workpath/logs"
		fi
		echo $real_public_ip > $saved_public_ip_file
		echo "$(date): $real_public_ip" >> $ip_log
		source "$workpath/cloud_ddns_update.sh" $real_public_ip
	fi
}

	get_current_ip
	check_saved_ip_uptodate
	exit 0
