# What is cf_ddns_updater?
Just another simple **dynamic dns (DDNS)** updater made with bash.
By now it supports only IPv4/Type A records.
This is just a little hobbie project I made to learn more Bash and JQ scripting, and get my server records updated.

# How does it work
There are two bash scripts, *IP_check.sh* and *cloud_ddns_update.sh*:  
## IP_check.sh
Is the first one to get executed, it gets your public IP Address, using [this page](https://cloudflare.com/cdn-cgi/trace) and compares it with a local save of your last ip address in `$workpath/logs/current_ip.log`. If the address is updated, the script ends, otherwise it will call the *cloud_ddns_updater.sh* script.
## cloud_ddns_update.sh
Will first get some variables from *config.json*. Then, with the zone and domains will get their IDs using the cloudflare API, one call per each domain. If everything is right, then the script will PATCH the records with the current ip address registered.
This script can be executed directly with the format `cloud_ddns_updater.sh "current_ip"`, e.g. `cloud_ddns_updater.sh 142.250.31.100`, the config file must be in the same directory as the script for it to work.

# Config.json
This is what should be included inside the config file: 
```
{
    "api_key": "yourcloudflareapikey", 
	"type": "A",
	"zone": "yourdomainname.tld",
	"domains": [ "subdomain1.yourdomainname.tld", "subdomain2.yourdomain.tld" ]
}
```

1. *api_key*: CloudFlare API key, it must have **DNS Write** permissions to edit your records.
2. *type*: A
3. *zone*: your domain name, in the format *yourdomainname.tld*
4. *domains*: a list of full domains including the subdomains, must be at least one and can be the root domain, in the format *subdomain.yourdomainname.tld*

# Logs
Three logs are created with this script, *current_ip.log*, *update.log* and *ip.log*.
- *current_ip.log*, dir `$workpath/logs/current_ip.log`, is a text file containing your last registered public ip as a one line IPv4.
- *update.log*, dir `$workpath/logs/update.log`, is a text file that saves the responses from every API requests into a one new line each time the IP gets updated.
- *ip.log*, dir `$workpath/logs/ip.log`, is a text file that registers every ip change detected with the format `$timestamp:$ip`.

Logs are not automatically deleted, a cron job could be added to delete the logs dir periodically, rm commands must be executed with care.

# Install.sh
The package comes with an install script which essentially copies *IP_check.sh*, *cloud_ddns_update.sh* and *config.json*; and then sets a cronjob to check for ip changes **(CRONTAB must be installed for this to work)**. 
Before executing it, *config.json* must be created with its respective components, you can use *config.json.example* file and rename it.
The `workpath="$HOME/.local/bin/cf_ddns_updater"` var sets the installation path. If changed, it should be also updated inside each script since this variable won't get automatically updated.
The `cycle_timespan=10` var sets the time interval, in minutes, in which the cronjob will get called.

Those three lines can be uncommented to periodically delete *update.log* and *ip.log* 
```
#current_cron=$(crontab -l)
#echo "$current_cron
#$cron_clear_logs" | crontab -
```
The line `cron_clear_logs="* * 1 * * rm $workpath/logs/update.log $workpath/logs/ip.log"` sets the deletion span to once every 1st of the month.
