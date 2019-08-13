# Summary
This directory contains various scripts which can help with reproduction of the results

# Scripts

## restore-postgres.sh
This script assumes that ```PostgreSQL``` and ```wget``` are alread installed on the system. By executing it the following steps are performed:
1. Download Postgres dump from S3 (About 3.2G of data)
2. Create local Postgres database
3. Restore dump into database

The default database name is ```<yourlogin>cowrielogs```

## snapshot-postgres.sh
Produces a backup of the Postgres database and uploads to S3
