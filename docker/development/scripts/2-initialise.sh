#!/bin/sh

#----#
# placeholder for testing
# while true; do sleep 1; done
#----#

# set file permissions if required
if [ $(id -u) -ne $(stat -c %u /data) ]
then
    if [ $(id -u) -eq 1000 ]
    then
        echo "---- Detected File Permission Mismatch ----"
        echo "---- Forcing File Permissions to the node user ----"
        sudo /bin/chown -R 1000:1000 /data
    else
        echo "---- You are not running as the node user AND your file permissions don't match your user ---\n"
        echo "---- You may need to manually fix your file permissions ----"
    fi
fi

# create the home directory if it doesn't exist
cd /data
if ! [ -d /data/home ]
then
    mkdir /data/home
    # set tmux to use mouse scroll
    echo "set -g mouse on" > /data/home/.tmux.conf
fi

#attempt to initialize and run a repository
if [[ "$AUTOINITIALIZE" == "true" ]]
then
    # check if there is a copy of ${PROJECT_NAME}, if not assume this is a fresh install
    if ! [ -d /data/${PROJECT_NAME} ]
    then
        echo "-- Fresh Install detected, setting up your dev environment --"
        echo "-- Installing Source --"
        # clone the latest version of ${PROJECT_NAME}
        cd /data
        git clone ${PROJECT_URL}
        cd ${PROJECT_NAME}
        npm install
    else
        cd /data/${PROJECT_NAME}
    fi

    if [[ "$AUTOSTART" == "true" ]]
    then
        # run the sub process
        tmux new-session -d "${DEV_COMMAND}; sh"
    fi
fi

# run the main process.
if [[ "$USE_CONNECTION_TOKEN" == "false" ]]
then
    /opt/openvscode-server/bin/openvscode-server --host 0.0.0.0 --without-connection-token
else
    if [[ "$CONNECTION_TOKEN" == "" ]]
    then
        CONNECTION_TOKEN=$(echo $RANDOM | md5sum | head -c 20)
        echo "connection token is not set, randomising to $CONNECTION_TOKEN"
    fi
    /opt/openvscode-server/bin/openvscode-server --host 0.0.0.0 --connection-token=${CONNECTION_TOKEN}
fi