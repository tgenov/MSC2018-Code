#!/bin/bash
wget s3://todorgenov-master-thesis-data/postgres-dump/cowrie-data.dump
DBNAME="$USERcowrielogs"
createdb $DBNAME
pg_restore --no-owner --role=$USER -d "$DBNAME" cowrie-data.dump

