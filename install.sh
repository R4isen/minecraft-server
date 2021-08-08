#!/bin/bash

chmod u+x install.sh config.sh command.sh daemon.sh start.sh stop.sh startup-script.sh shutdown-script.sh

CURRENT_PATH=`pwd`
CURRENT_USER=$SUDO_USER
. config.sh

apt-get update
apt-get install -y software-properties-common

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CC86BB64
add-apt-repository -y ppa:rmescandon/yq

apt-get update
apt-get install -y default-jre-headless screen unzip net-tools yq

#RCON_FILE="rcon-cli_${RCON_CLI_VERSION}_linux_amd64.tar.gz"
#wget "https://github.com/itzg/rcon-cli/releases/download/${RCON_CLI_VERSION}/${RCON_FILE}"
#tar xvzf $RCON_FILE
#rm $RCON_FILE

FORGE_FILE="forge-${MC_VERSION}-${FORGE_VERSION}.jar"
if [[ ! -f $FORGE_FILE ]]
then
  FORGE_INSTALLER="forge-${MC_VERSION}-${FORGE_VERSION}-installer.jar"
  wget "https://maven.minecraftforge.net/net/minecraftforge/forge/${MC_VERSION}-${FORGE_VERSION}/${FORGE_INSTALLER}"
  java -jar $FORGE_INSTALLER --installServer
  rm $FORGE_INSTALLER
fi

if [[ ! -f server.properties ]]
then
  perl -p -e 's/\$\{([^}]+)\}/defined $ENV{$1} ? $ENV{$1} : $&/eg' < server.properties.tpl > server.properties
fi

if [[ -n $MODS_ZIP_URL ]]
then
  wget $MODS_ZIP_URL -O mods.zip
  unzip mods.zip
  rm mods.zip
fi

if [[ -n $MODS_ZIP_URL ]]
then
  wget $WORLD_ZIP_URL -O world.zip
  unzip world.zip
  rm world.zip
fi

if [[ -n $CONFIG_ZIP_URL ]]
then
  wget $CONFIG_ZIP_URL -O config.zip
  unzip config.zip
  rm config.zip
fi

chown -R $CURRENT_USER:$CURRENT_USER .
chmod -R u=rwX,g=rX,o= .

STARTUP_SCRIPT="su $CURRENT_USER -c $CURRENT_PATH/startup-script.sh > $CURRENT_PATH/startup.log 2>&1"
SHUTDOWN_SCRIPT="su $CURRENT_USER -c $CURRENT_PATH/shutdown-script.sh > $CURRENT_PATH/shutdown.log 2>&1"

gcloud compute instances add-metadata $COMPUTE_VM_NAME --zone=$COMPUTE_ZONE --metadata=startup-script="$STARTUP_SCRIPT"
gcloud compute instances add-metadata $COMPUTE_VM_NAME --zone=$COMPUTE_ZONE --metadata=shutdown-script="$SHUTDOWN_SCRIPT"

$STARTUP_SCRIPT