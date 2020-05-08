#!/bin/bash

# Backup existing web-wallet
DATE=$(date  '+%Y-%m-%d-%H-%M')
BACKUP_FOLDER="web-wallet-$DATE"
cp -r web-wallet "$BACKUP_FOLDER"

# Remove existing installation
rm -rf web-wallet

# Clone
git clone https://github.com/privatesky/web-wallet.git
cd web-wallet

# Install dependencies
npm install

if [ $? -ne 0 ]; then
    exit 1
fi

# Start the server
npm run server 2>&1 > server.log &
sleep 1

netcat -w 5 -z localhost 8080
SOCKET_STATUS=$?
WAITING_TIME=0

echo "Waiting for server to start $WAITING_TIME"

function get_server_pid() {
    SERVER_PID=$(ps aux | grep 'node ./bin/scripts/psknode.js' | grep -v sh | head -n 1 | awk '{print $2}')
    echo "$SERVER_PID"
}


while [ $SOCKET_STATUS -eq 1 ]; do
    netcat -w 5 -z localhost 8080
    SOCKET_STATUS=$?
    ((WAITING_TIME=WAITING_TIME+1))
    sleep 1

    echo "Waiting for server to start $WAITING_TIME"
    if [ $WAITING_TIME -ge 60 ]; then
        echo "$WAITING_TIME"
        echo "Waited too long for server to start. Something's wrong. Exiting..."
        exit 1
    fi
done

# Build applications and solutions
echo 'Server is initialized. Building apps...'
npm run build-all

# Kill server
kill $(get_server_pid)
echo 'Finished installing & building the web-wallet'
