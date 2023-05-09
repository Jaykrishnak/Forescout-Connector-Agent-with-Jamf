#!/bin/sh
daemon_plist=/Library/LaunchDaemons/com.forescout.secureconnector.daemon.plist

sudo launchctl unload $daemon_plist
sudo launchctl load $daemon_plist

