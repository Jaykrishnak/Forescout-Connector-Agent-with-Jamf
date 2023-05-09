#!/bin/sh

# return values
# 1 - failed to install
# 2 - failed to remove previous installation 

OSX_VER=`sw_vers -productVersion`
Base_Path=`dirname $0`
App_Name="ForeScout SecureConnector"
Config_Name="com.forescout.secureconnector.plist"
Daemon_App_Path="/Applications"
Dissolvable_App_Path="$TMPDIR/Applications"
App_Src="${Base_Path}/${App_Name}.app/"
Config_Src="${Base_Path}/${Config_Name}"

# avoid tee errors in case this is not run from a terminal (and /dev/tty is not configured)
[ -w /dev/tty ] && TERMINAL="/dev/tty" || TERMINAL="/dev/null"
echo "${App_Name} Update.sh: Start Update Script" | tee $TERMINAL | logger

# Process command line arguments
PID=
app_type=
visible=

while [ "$#" != "0" ]; do
    case $1 in
        -pid )
            shift
			sleep 5
            PID=$1
            ;;
        -v )
            shift
            visible=$1
            ;;
        -t )
            shift
            app_type=$1
            ;;
    esac
    shift
done


echo "${App_Name} Update.sh: app_type[${app_type}] visible[${visible}] pid[${PID}]" | tee $TERMINAL | logger

if [ $app_type == "daemon" ]; then
	base=""
	App_Path=$Daemon_App_Path
elif [ $app_type == "dissolvable" ]; then
	base=$HOME
	App_Path=$Dissolvable_App_Path
fi

Config_Dst_Path="$base/Library/Preferences"
Config_Dst="${Config_Dst_Path}/${Config_Name}"
Certificate_Path="$base/Library/Application Support/ForeScout"
App_Dst="${App_Path}/${App_Name}.app"

echo "${App_Name} Update.sh: App_Dst[${App_Dst}] Config_Dst[${Config_Dst}]" | tee $TERMINAL | logger

# Check if we have write permissions for the app destination directory
if [ ! -w ${Config_Dst_Path} ]; then 
    echo "${App_Name} Update.sh: Insufficient permissions, abort installation" | tee $TERMINAL | logger
    exit 1
fi

# Uninstall existing:

# Try to uninstall anything in your own destination
if [ -f "${App_Dst}/Uninstall.sh" ]; then
    echo "${App_Name} Update.sh: Found an existing installation in the destination path, going to uninstall" | tee $TERMINAL | logger
    "${App_Dst}/Uninstall.sh" -path "${App_Dst}" -t "$app_type" -PID "${PID}"
fi

# Check if there's still a daemon installation around
# This is either if this installation is dissolvable and there's an existing daemon 
# or if this is a daemon and the we failed to uninstall the existing daemon
if [ -f "${Daemon_App_Path}/${App_Name}.app/Uninstall.sh" ]; then
    # There's still a daemon installation around, exit
    echo "${App_Name} Update.sh: There's still a daemon installation around, abort installation" | tee $TERMINAL | logger
    exit 2
fi

# Kill remaining dissolvable processes if there are any
SCPID=$(ps auxww | egrep "ForeScout SecureConnector -local|ForeScout SecureConnector -agent" | grep -v grep | awk 'BEGIN { ORS=" " }; { print $2 }')
echo "${App_Name} Update.sh: remaining dissolvable process - pid[${SCPID}]" | tee $TERMINAL | logger
echo $SCPID | xargs kill -9 > /dev/null 2>&1

#copy application bundle
mkdir -p "${Config_Dst_Path}"
mkdir -p "${App_Dst}"
ditto "${App_Src}" "${App_Dst}"

#copy to home
if [ -f ${Config_Src} ]; then

	if [[ $OSX_VER =~ ^10.8 ]]; then
		  cp  ${Config_Src} "${Config_Dst}"
	else 
		echo "defaults import  ${Config_Dst}  ${Config_Src}"  |  logger
		defaults import ${Config_Dst}  ${Config_Src} | logger
	fi
	
    if [ $? -ne 0 ]; then
        echo "${App_Name} Update.sh: Failed to copy ${Config_Src} to ${Config_Dst}, abort installation" | tee $TERMINAL | logger
        exit 1
    else
		chmod a+r "${Config_Dst}"
		echo "${App_Name} Update.sh: Copying ${Config_Src} to ${Config_Dst} successful" | tee $TERMINAL | logger
    fi 
fi

mkdir -p "${Certificate_Path}"

/usr/libexec/PlistBuddy -c "Add :certs_path string" "${Config_Dst}"
/usr/libexec/PlistBuddy -c "Set :certs_path '${Certificate_Path}'" "${Config_Dst}"
if [ "${app_type}" != "" ]; then
    /usr/libexec/PlistBuddy -c "Add :app_type string" "${Config_Dst}"
    /usr/libexec/PlistBuddy -c "Set :app_type ${app_type}" "${Config_Dst}"
fi

if [ "${visible}" != "" ]; then
    /usr/libexec/PlistBuddy -c "Add :visible bool" "${Config_Dst}"
    /usr/libexec/PlistBuddy -c "Set :visible ${visible}" "${Config_Dst}"
fi

echo "${App_Name} Update.sh: OSX version [${OSX_VER}]" | tee $TERMINAL | logger
if [[ $OSX_VER =~ ^10.8 ]]; then
    echo "${App_Name} Update.sh: Killing all cfprefsd to reload defaults" | tee $TERMINAL | logger
    killall cfprefsd > /dev/null 2>&1
else 
    defaults read "${Config_Dst}" | logger
fi

#Moving Uninstall.sh out of applications directory as per Apple support suggestion.
cp "${Base_Path}/Uninstall.sh" "${Certificate_Path}"/Uninstall.sh
chmod a+rx "${Certificate_Path}"/Uninstall.sh

cp "${Base_Path}/launchScComponents.sh" "${Certificate_Path}"/launchScComponents.sh
chmod a+rx "${Certificate_Path}"/launchScComponents.sh

cp "${Base_Path}/startScDaemon.sh" "${Certificate_Path}"/startScDaemon.sh
chmod a+rx "${Certificate_Path}"/startScDaemon.sh

cp "${Base_Path}/stopSc.sh" "${Certificate_Path}"/stopSc.sh
chmod a+rx "${Certificate_Path}"/stopSc.sh

if [  "${app_type}" == "daemon" ]; then
    chmod u-s "${App_Dst}/Contents/MacOS/ForeScout SecureConnector"
	
    if ! [ -d "$base/Library/LaunchDaemons/" ]; then
        mkdir -p "$base/Library/LaunchDaemons/"
    fi
    cat > "$base/Library/LaunchDaemons/com.forescout.secureconnector.daemon.plist" <<- EOM
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.forescout.secureconnector.daemon</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
      <key>SuccessfulExit</key>
      <false />
    </dict>
    <key>SessionCreate</key>
    <true/>
    <key>ProgramArguments</key>
        <array>
		    <string>${App_Dst}/Contents/MacOS/ForeScout SecureConnector</string>
            <string>-daemon</string>
        </array>
    <key>UserName</key>
    <string>root</string>
</dict>
</plist>

EOM
	launchctl unload "$base/Library/LaunchDaemons/com.forescout.secureconnector.daemon.plist" > /dev/null 2>&1
	launchctl load "$base/Library/LaunchDaemons/com.forescout.secureconnector.daemon.plist"

	if ! [ -d "$base/Library/LaunchAgents/" ]; then
		mkdir -p "$base/Library/LaunchAgents/"
	fi
		cat > "$base/Library/LaunchAgents/com.forescout.secureconnector.agent.plist" <<- EOM
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.forescout.secureconnector.agent</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
      <key>SuccessfulExit</key>
      <false />
    </dict>
    <key>ProgramArguments</key>
        <array>
		    <string>${App_Dst}/Contents/MacOS/ForeScout SecureConnector</string>
            <string>-agent</string>
        </array>
</dict>
</plist>

EOM
	launchctl unload "$base/Library/LaunchAgents/com.forescout.secureconnector.agent.plist" > /dev/null 2>&1
	launchctl load "$base/Library/LaunchAgents/com.forescout.secureconnector.agent.plist"
	sleep 3
	chmod 600 ${Config_Dst}
else
	# dissolvable
	open -a "${App_Dst}" --args -local
fi
