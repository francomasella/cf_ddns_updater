#!/usr/bin/env bash

set -x

#version=1.0

readonly workpath="$HOME/.local/bin/cf_ddns_updater"
readonly scripts='IP_check.sh cloud_ddns_update.sh config.json'
readonly cycle_timespan=10

mkdir -p $workpath
chmod 744 $scripts
cp $scripts $workpath

cron_script="*/$cycle_timespan * * * * sh $workpath/IP_check.sh"
cron_clear_logs="* * 1 * * rm $workpath/logs/update.log $workpath/logs/ip.log"
current_cron=$(crontab -l)
echo "$current_cron
$cron_script #cf_ddns_updater" | crontab -

#current_cron=$(crontab -l)
#echo "$current_cron
#$cron_clear_logs" | crontab -

exit 0
