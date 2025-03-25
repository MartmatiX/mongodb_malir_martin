#!/bin/bash

# Variables
SLEEP=5
SLEEP_CLEAR=10

pokemon_csv="../data/pokemon.csv"
games_csv="../data/vgsales_cleaned.csv"

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

# Create Validation Schema And Import Pokemon Data From CSV File
echo "The Thread Will Now Sleep For $SLEEP Seconds Before The Data Are Imported"
sleep $SLEEP
echo "Creating Validation Schema For The Pokemon Dataset..."
docker exec -it router mongosh --authenticationDatabase admin -u admin -p password --eval 'use nosql_project;'
docker exec -it router mongosh --authenticationDatabase admin -u admin -p password --eval 'db.getSiblingDB("nosql_project").pokemon.insertOne({ test: "data" });'
docker exec -it router mongosh --authenticationDatabase admin -u admin -p password --eval '
db.getSiblingDB("nosql_project").runCommand({
  collMod: "pokemon",
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["#", "Name", "Type 1", "Total", "HP", "Attack", "Defense", "Sp", "Speed", "Generation", "Legendary"],
      properties: {
        "#": { bsonType: "int", description: "Pokédex number, must be an integer and required." },
        Name: { bsonType: "string", description: "Pokémon name, required." },
        "Type 1": { bsonType: "string", description: "Primary type of the Pokémon, required." },
        "Type 2": { bsonType: ["string", "null"], description: "Secondary type of the Pokémon, optional." },
        Total: { bsonType: "int", description: "Total base stats, must be an integer." },
        HP: { bsonType: "int", minimum: 1, description: "HP stat, must be an integer and at least 1." },
        Attack: { bsonType: "int", minimum: 1, description: "Attack stat, must be an integer and at least 1." },
        Defense: { bsonType: "int", minimum: 1, description: "Defense stat, must be an integer and at least 1." },
        Sp: {
          bsonType: "object",
          required: [" Atk", " Def"],
          properties: {
            " Atk": { bsonType: "int", minimum: 1, description: "Special Attack stat, must be an integer and at least 1." },
            " Def": { bsonType: "int", minimum: 1, description: "Special Defense stat, must be an integer and at least 1." }
          },
          description: "Special Attack and Special Defense, stored as a nested object."
        },
        Speed: { bsonType: "int", minimum: 1, description: "Speed stat, must be an integer and at least 1." },
        Generation: { bsonType: "int", minimum: 1, description: "Game generation, must be an integer." },
        Legendary: { bsonType: "string", description: "Indicates if the Pokémon is legendary (true/false)." }
      }
    }
  },
  validationLevel: "strict",
  validationAction: "error"
});
'
echo "Validation Schema Created"
echo "The Thread Will Now Sleep For $SLEEP Seconds"
echo "-------------------------------------------------"
sleep $SLEEP

echo "Importing Data From The pokemon.csv File Into MongoDB..."
docker exec -i router mongoimport --host router --db nosql_project --collection pokemon --type csv --headerline --authenticationDatabase admin -u admin -p password < "$pokemon_csv"
docker exec -it router mongosh --authenticationDatabase admin -u admin -p password --eval 'db.getSiblingDB("nosql_project").pokemon.deleteOne({ test: "data" });'

echo "Pokemon Data Imported Into The Database"
echo "The Thread Will Now Sleep For $SLEEP Seconds"

echo "Creating Validation Schema For The Video Games Sales Dataset..."
docker exec -it router mongosh --authenticationDatabase admin -u admin -p password --eval 'db.getSiblingDB("nosql_project").games.insertOne({ test: "data" });'
docker exec -it router mongosh --authenticationDatabase admin -u admin -p password --eval '
db.getSiblingDB("nosql_project").runCommand({
  collMod: "games",
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["Rank", "Name", "Platform", "Year", "Genre", "Publisher", "NA_Sales", "EU_Sales", "JP_Sales", "Other_Sales", "Global_Sales"],
      properties: {
        Rank: { bsonType: "int", description: "Rank of the game, must be an integer and required." },
        Name: { bsonType: "string", description: "Name of the game, required." },
        Platform: { bsonType: "string", description: "Platform on which the game was released, required." },
        Year: { bsonType: [ "int", "null" ], description: "Year of release, must be an integer and required." },
        Genre: { bsonType: "string", description: "Genre of the game, required." },
        Publisher: { bsonType: [ "string", "null" ], description: "Publisher of the game, required." },
        NA_Sales: { bsonType: "double", description: "Sales in North America, must be a non-negative number." },
        EU_Sales: { bsonType: "double", description: "Sales in Europe, must be a non-negative number." },
        JP_Sales: { bsonType: "double", description: "Sales in Japan, must be a non-negative number." },
        Other_Sales: { bsonType: "double", description: "Sales in other regions, must be a non-negative number." },
        Global_Sales: { bsonType: "double", description: "Total global sales, must be a non-negative number." }
      }
    }
  },
  validationLevel: "strict",
  validationAction: "error"
});
'
echo "Validation Schema Created"
echo "The Thread Will Now Sleep For $SLEEP Seconds"
echo "-------------------------------------------------"
sleep $SLEEP

echo "Cleaning The Dataset For Video Games Sales"
(cd ../data && python3 ../data/vgSalesCleaner.py)
echo "Output Saved To 'vgsales_cleaned.csv' File"
cd ../funkcni_reseni

echo "Importing Data From The vgsales.csv File Into MongoDB..."
docker exec -i router mongoimport --host router --db nosql_project --collection games --type csv --headerline --authenticationDatabase admin -u admin -p password < "$games_csv"
docker exec -it router mongosh --authenticationDatabase admin -u admin -p password --eval 'db.getSiblingDB("nosql_project").games.deleteOne({ test: "data" });'

echo "Video Games Data Imported Into The Database"
echo "The Thread Will Now Sleep For $SLEEP Seconds"

echo "-------------------------------------------------"

echo "FULL INITIALIZATION FINISHED"

echo "-------------------------------------------------"

echo "To Connect To The Database, Please Use:"
echo "docker exec -it router mongosh --authenticationDatabase 'admin' -u 'admin' -p 'password'"
echo "To Show All Databases, Please Use:"
echo "db.adminCommand( { listDatabases: 1 } )"
echo "To Switch To One Of The Databases, Please Use:"
echo "use <database_name> | Database 'nosql_project' Is The Main One"
echo "To Show Database Collections, Please Use:"
echo "show collections"
echo "To List A Few Lines Of Data, Please Use:"
echo "db.<schema_name>.find().limit(<number_of_records>)"
echo "To View Validation Schemas, Please Use:"
echo "db.getCollectionInfos( { name: '<schema_name>' } )[0].options.validator"

echo "-------------------------------------------------"

echo "To Stop All Containers, Please Use:"
echo "docker compose down"
echo "If You Wish To Also Remove The Containers, Please Use:"
echo "docker compose down -v"
echo "If You Want To Start The Containers, Please Use: (Please Note, That After This Script Is Executed, The Containers Should Be Up And Running)"
echo "docker compose up -d"

