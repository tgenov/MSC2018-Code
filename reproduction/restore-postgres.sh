#!/bin/bash
wget s3://todorgenov-master-thesis-data/thesis.sql
DBNAME="$USERcowrielogs"
createdb $DBNAME
pg_restore --no-owner --role=$USER -d "$DBNAME" thesis.sql
