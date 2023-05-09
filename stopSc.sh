##########################################################################################
##  it's the FS stop SC - that is, stop and uninstall					 #
##  the agent will kill itself when it gets the stopSC message				 #
##  so we just stop the agent servic and clean up					 #
##  takes care of daemon only - the local/disolvable variants shouldn't be installed     #
##########################################################################################

echo "Stop SecureConnector - will stop SecureConnector in 5 seconds" | logger

sleep 5
#sleep to allow client to send response

daemon_plist=/Library/LaunchDaemons/com.forescout.secureconnector.daemon.plist
agent_plist=/Library/LaunchAgents/com.forescout.secureconnector.agent.plist


plist_path="${HOME}"/Library//Preferences/com.forescout.secureconnector.plist
app_type="unknown"

if [ -f $plist_path ]; then
	app_type=`/usr/libexec/PlistBuddy -c "Print :app_type" "${plist_path}"`
fi



if [ "$app_type" == "daemon" ]; then

	if [ -f $agent_plist ]; then
		echo "Stop SecureConnector - stopping agent" | logger
		for pid in `ps auxww  | grep -v grep | egrep "ForeScout SecureConnector.*-agent" | awk '{print $2}'`
		do
			launchctl bsexec $pid launchctl unload $agent_plist
		done
		rm -f $agent_plist
	fi
	if [ -f $daemon_plist ]; then
		echo "Stop SecureConnector - stopping daemon" | logger
		launchctl unload $daemon_plist
		rm $daemon_plist
	fi
	rm -rf /Applications/ForeScout\ SecureConnector.app/
fi


if [ "$app_type" != "daemon" ]; then
	echo "Stop SecureConnector - stopping non-daemon variant" | logger
	killall -KILL ForeScout\ SecureConnector
fi

if [ -f $plist_path ]; then
	rm -rf $plist_path
fi

