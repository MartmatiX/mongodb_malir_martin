#!/bin/bash

# Variables
SLEEP=10
SLEEP_CLEAR=30

# Initial Greetings
echo "Hello, You Just Started A MongoDB Initialization Script"
echo "All Existing Containers Will Be Deleted And Created From Scratch"
echo "The Thread Will Now Sleep For $SLEEP_CLEAR Seconds"
echo "If You Changed Your Mind, Please Press ctrl+c On Your Keyboard, To Interrupt The Process"
sleep $SLEEP_CLEAR

# Check If Docker Is Running
if systemctl is-active --quiet "docker" ; then
	echo "Docker Is Running, Proceeding With The Script..."
else
	echo "Docker Is Not Running, Stopping The Script..."
	exit 1
fi

# Removal Of Old Containers
echo "Removing Old Containers..."
docker compose down -v
echo "Old Containers Removed, The Thread Will Sleep For $SLEEP Seconds Before The Next Operation..."
sleep $SLEEP

# Startup Of The Containers
echo "Starting The Containers..."
docker compose up -d
echo "Containers Started, The Thread Will Now Sleep For $SLEEP_CLEAR Seconds So Everything Can Start Properly..."
sleep $SLEEP_CLEAR

# Initialize Config Server Replica Set
echo "Initializing Config Server..."
docker exec -it config-server mongosh --eval '
rs.initiate({
  _id: "config-server",
  configsvr: true,
  members: [
    { _id: 0, host: "config-server:27017" }
  ]
});
'
echo "Config Server Initialized..."
echo "-------------------------------------------------"

# Wait for the Config Server to initialize
echo "Thread Sleeping For $SLEEP Seconds..."
sleep $SLEEP

# Initialize Shard Replica Set
echo "Initializing Shard Replica Set..."
docker exec -it shard-primary mongosh --eval '
rs.initiate({
  _id: "shard-primary",
  members: [
    { _id: 0, host: "shard-primary:27017" },
    { _id: 1, host: "shard-secondary:27017" },
    { _id: 2, host: "shard-tertiary:27017" }
  ]
});
'
echo "Shard Replica Set Initialized..."
echo "-------------------------------------------------"

# Wait for the Shard Replica Set to initialize
echo "Thread Sleeping For $SLEEP Seconds..."
sleep $SLEEP

# Add Shard to Router
echo "Adding Shard to Router..."
docker exec -it router mongosh --eval '
sh.addShard("shard-primary/shard-primary:27017,shard-secondary:27017,shard-tertiary:27017");
'
echo "Shard Added to Router..."
echo "-------------------------------------------------"

# Wait for the Shard to be added
echo "Thread Sleeping For $SLEEP Seconds..."
sleep $SLEEP

# Create Admin User
echo "Creating Admin User..."
docker exec -it router mongosh --eval 'db.getSiblingDB("admin").createUser({user: "admin", pwd: "password", roles: [{ role: "root", db: "admin" }]});'
echo "Admin User Created..."

echo "-------------------------------------------------"

echo "MongoDB Sharding Setup Completed!"

echo "To Connect To The Database Please Use:"
echo "docker exec -it router mongosh --authenticationDatabase 'admin' -u 'admin' -p 'password'"
echo "-------------------------------------------------"
echo "To Stop All Containers, Please Use:"
echo "docker compose down"
echo "If You Wish To Also Remove The Containers, Please Use:"
echo "docker compose down -v"
echo "If You Want To Start The Containers, Please Use: (Please Note, That After This Script Is Executed, The Containers Should Be Up And Running)"
echo "docker compose up -d"

