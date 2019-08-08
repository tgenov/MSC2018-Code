#!/bin/bash
set -eu
set -o pipefail

function restart_cowrie()
{
  echo "Restarting Cowrie"
  cd ~cowrie/cowrie && bin/cowrie restart
  exit 0
}

COWRIE_PID_FILE="/home/cowrie/cowrie/var/run/cowrie.pid"
COWRIE_PID=$(cat $COWRIE_PID_FILE) || restart_cowrie
if [ "$(ps -o ucmd -p $COWRIE_PID --no-headers)" != "twistd" ];
then
  restart_cowrie
fi