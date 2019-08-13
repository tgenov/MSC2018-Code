#!/bin/bash
set -eu
set -o pipefail
pg_dump -Fc -Z 4 todor > cowrie-postgres.dump
aws s3 cp cowrie-data.dump s3://todorgenov-master-thesis-data/postgres-dump/