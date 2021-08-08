#!/bin/bash

. config.sh

JVM_OPTS="-Xmx${SERVER_MEM_SIZE}"

screen -dmS mcs -- java $JVM_OPTS -jar "forge-${MC_VERSION}-${FORGE_VERSION}.jar" nogui
screen -dmS mcsd -- ./daemon.sh