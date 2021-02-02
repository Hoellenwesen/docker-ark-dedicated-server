#!/bin/sh

# Change the UID if needed
if [ ! "$(id -u steam)" -eq "$UID" ]; then 
    echo "Changing steam uid to $UID."
    usermod -o -u "$UID" steam ; 
fi
# Change gid if needed
if [ ! "$(id -g steam)" -eq "$GID" ]; then 
    echo "Changing steam gid to $GID."
    groupmod -o -g "$GID" steam ; 
fi

# Put steam owner of directories (if the uid changed, then it's needed)
chown -R steam:steam /ark /home/steam

# avoid error message when su -p (we need to read the /root/.bash_rc )
chmod -R 777 /root/

ln -fs /usr/share/zoneinfo/$TZ /etc/localtime

ulimit -n 100000

# Launch run.sh with user steam (-p allow to keep env variables)
su steam -c /home/steam/run.sh
