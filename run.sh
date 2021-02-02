#!/usr/bin/env bash
echo "###########################################################################"
echo "# Ark Server - " `date`
echo "# UID $UID - GID $GID"
echo "# "
echo "# Timezone...: $TZ"
echo "# Session....: $SESSIONNAME"
echo "# Map........: $SERVERMAP"
echo "# Players....: $NBPLAYERS"
echo "# Mods.......: $SERVERMODS"
echo "# Query Port.: $QUERYPORT"
echo "# Server Port: $SERVERPORT"
echo "# RCON Port..: $RCONPORT"
echo "# BRANCH.....: $BRANCH"
echo "###########################################################################"
[ -p /tmp/FIFO ] && rm /tmp/FIFO
mkfifo /tmp/FIFO

export TERM=linux

function stop {
	if [ "$BACKUPONSTOP" -eq "1" ] && [ "$(ls -A server/ShooterGame/Saved/SavedArks)" ]; then
		echo "[Backup on stop]"
		arkmanager backup
	fi
	if [ "$WARNONSTOP" -eq "1" ];then 
	    arkmanager stop --warn
    	else
	    arkmanager stop
    	fi
	exit
}

# Change working directory to /ark to allow relative path
cd /ark

# Add a template directory to store the last version of config file
[ ! -d /ark/template ] && mkdir /ark/template
# We overwrite the template file each time
cp /home/steam/arkmanager.cfg /ark/template/arkmanager.cfg
cp /home/steam/crontab /ark/template/crontab
cp /home/steam/crontab /ark/crontab
# Creating directory tree && symbolic link
[ ! -f /ark/arkmanager.cfg ] && cp /home/steam/arkmanager.cfg /ark/arkmanager.cfg
[ ! -d /ark/log ] && mkdir /ark/log
[ ! -d /ark/backup ] && mkdir /ark/backup
[ ! -d /ark/staging ] && mkdir /ark/staging
[ ! -L /ark/Game.ini ] && ln -s server/ShooterGame/Saved/Config/LinuxServer/Game.ini Game.ini
[ ! -L /ark/GameUserSettings.ini ] && ln -s server/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini GameUserSettings.ini
[ ! -f /ark/crontab ] && cp /ark/template/crontab /ark/crontab

# See if arkmanager tools need to be upgraded
echo "Checking for arkmanager tools upgrade..."
yes |arkmanager upgrade-tools

# Build new steam environment sh for crontab to use
echo "Updating steam environment for cron..."
printenv | sed 's/^\(.*\)$/export \1/g' |grep -v "_=" |grep -v "LESS" |grep -v "HOME" |grep -v "COLORS" > /home/steam/steamenv.sh

if [ ! -d /ark/server  ] || [ ! -f /ark/server/version.txt ];then 
	echo "No game files found. Installing..."
	mkdir -p /ark/server/ShooterGame/Saved/SavedArks
	mkdir -p /ark/server/ShooterGame/Content/Mods
	mkdir -p /ark/server/ShooterGame/Binaries/Linux/
	touch /ark/server/ShooterGame/Binaries/Linux/ShooterGameServer
	arkmanager install --verbose
	# Create mod dir
else
	if [ "$BACKUPONSTART" -eq "1" ] && [ "$(ls -A server/ShooterGame/Saved/SavedArks/)" ]; then 
		echo "[Backup]"
		arkmanager backup
	fi
fi

# If there is uncommented line in the file
CRONNUMBER=`grep -v "^#" /ark/crontab | wc -l`
if [ "$CRONNUMBER" -gt "0" ]; then
	echo "Loading crontab..."
	# We load the crontab file if it exist.
	crontab /ark/crontab
	# Cron is attached to this process
	sudo cron -f &
else
	echo "No crontab set."
fi

# Launching ark server
if [ "$UPDATEONSTART" -eq 0 ]; then
	arkmanager start --noautoupdate
else
	arkmanager start
fi

# Stop server in case of signal INT or TERM
echo "Waiting..."
trap stop INT
trap stop TERM

read < /tmp/FIFO &
wait
