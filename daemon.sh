#!/bin/bash

. config.sh

current_uptime() {
  echo $(awk '{print $1}' /proc/uptime | cut -d . -f 1)
}

java_process_exists() {
  [[ -n "$(ps -ax -o comm | grep 'java')" ]]
}

java_clients_connected() {
  local connections
  connections=$(netstat -tn | grep ":$SERVER_PORT" | grep ESTABLISHED)
  if [[ -z "$connections" ]] ; then
    return 1
  fi
  IFS=$'\n'
  connections=($connections)
  unset IFS
  # check that at least one external address is not localhost
  # remember, that the host network mode does not work with autopause because of the knockd utility
  for (( i=0; i<${#connections[@]}; i++ ))
  do
    if [[ ! $(echo "${connections[$i]}" | awk '{print $5}') =~ ^localhost$|^127(?:\.[0-9]+){0,2}\.[0-9]+$|^(?:0*\:)*?:?0*1$ ]] ; then
      # not localhost
      return 0
    fi
  done
  return 1
}

mc_server_listening() {
  [[ -n $(netstat -tln | grep -e "0.0.0.0:$SERVER_PORT" -e ":::$SERVER_PORT" | grep LISTEN) ]]
}

logAutoShutdown() {
  echo "[AutoShutdown] $*"
}

# wait for java process to be started
while :
do
  if java_process_exists ; then
    break
  fi
  sleep 60
done

STATE=INIT

while :
do
  case X$STATE in
  XINIT)
    # Server startup
    if mc_server_listening ; then
      TIME_THRESH=$(($(current_uptime)+$AUTOSHUTDOWN_TIMEOUT_INIT))
      logAutoShutdown "MC Server listening for connections - stopping in $AUTOSHUTDOWN_TIMEOUT_INIT seconds"
      STATE=I
    fi
    ;;
  XE)
    # Established
    if ! java_clients_connected ; then
      TIME_THRESH=$(($(current_uptime)+$AUTOSHUTDOWN_TIMEOUT_EST))
      logAutoShutdown "All clients disconnected - stopping in $AUTOSHUTDOWN_TIMEOUT_EST seconds"
      STATE=I
    fi
    ;;
  XI)
    # Idle
    if java_clients_connected ; then
      logAutoShutdown "Client connected - waiting for disconnect"
      STATE=E
    else
      if [[ $(current_uptime) -ge $TIME_THRESH ]] ; then
        logAutoShutdown "No client reconnected - stopping"
        ./stop.sh
        STATE=S
      fi
    fi
    ;;
  XS)
    # Stopped
    if ! java_process_exists ; then
      logAutoShutdown "MC Server stopped - shutting down the server"
      sudo /sbin/poweroff
    fi
    ;;
  *)
    logAutoplogAutoShutdownause "Error: invalid state: $STATE"
    ;;
  esac
  if [[ "$STATE" == "S" ]] ; then
    sleep 2
  else
    sleep $AUTOSHUTDOWN_LOOP_SLEEP
  fi
done