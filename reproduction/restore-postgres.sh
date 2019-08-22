#!/bin/bash
set -eux
set -o pipefail
# From https://osf.io/vkcrn/
wget -c -O cowrie-data.dump https://osf.io/8wbfr/download
DBNAME="${USER}cowrielogs"
createdb "$DBNAME"
pg_restore --no-owner --role=$USER -d "$DBNAME" cowrie-data.dump

