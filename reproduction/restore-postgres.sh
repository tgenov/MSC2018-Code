#!/bin/bash
# From https://osf.io/vkcrn/
wget https://osf.io/8wbfr/download
DBNAME="$USERcowrielogs"
createdb $DBNAME
pg_restore --no-owner --role=$USER -d "$DBNAME" cowrie-data.dump

