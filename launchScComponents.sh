#!/bin/sh

#############################################################################################
## this script starts the agent from the user's space if the app is installed as visible    #
## and the daemon with administrative privileges (askes for password			    #
## asumes the client is correcly installed 						    #
#############################################################################################


plist_path=/Library//Preferences/com.forescout.secureconnector.plist
app_type=`/usr/libexec/PlistBuddy -c "Print :app_type" "${plist_path}"`

#### some toy debug toy prints with a banner notification - easier to see than logs.. #######
# d=$(printf "display notification \"%s,%s\" with title \"app_type\"" $app_type $visible)   #
# /usr/bin/osascript -e "$d"								    #
#############################################################################################

daemon_plist=/Library/LaunchDaemons/com.forescout.secureconnector.daemon.plist
agent_plist=/Library/LaunchAgents/com.forescout.secureconnector.agent.plist

user=`id -un`
if [ $app_type == "daemon" ]; then
	
	# 1. start the daemon
	if [ $user == "root" ]; then
		/Library/Application\ Support/ForeScout/startScDaemon.sh
	else
		osascript -e "do shell script \"/Library/Application\\\\ Support/ForeScout/startScDaemon.sh\" with administrator privileges"
	fi 
	
	# 2. Start the gui agent only if the daemon is up (without the daemon the GUI will crash)
	is_up=`ps aux | grep SecureConnector | grep daemon | wc -l`
	if [ $is_up -eq 0 ]; then
		echo "SecureConnector daemon is not running. not starting the user agent" | logger
		exit
	else
		launchctl unload $agent_plist
		launchctl load $agent_plist
	fi
fi


