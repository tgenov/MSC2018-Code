#!/usr/bin/env python
# This script identifies all new/unprocessed Cowrie sessions in Postgres and generates a
# SHA256 checksum for each one to designate uniqueness. New sessions are scheduled for GraphResponder training.
import os
import time
import sys
import psycopg2
import hashlib
import numpy
import multiprocessing
import timeit
import logging as log
from concurrent import futures
from psycopg2.pool import ThreadedConnectionPool


#### CONFIGURABLES
max_threads = multiprocessing.cpu_count()
db_pool = psycopg2.pool.ThreadedConnectionPool(1, 10*max_threads, "dbname='todorcowrielogs' user='todor'")
BATCH_SIZE=5000
log.basicConfig(stream=sys.stdout, level=log.DEBUG)

# Retrieve all sessions which don't exist in the sessions_hash_map table
GET_WORK_SQL="""SELECT DISTINCT(session)
FROM   logstash l 
WHERE  event_id='cowrie.command.input'
AND NOT EXISTS (
   SELECT
   FROM   sessions_hash_map s
   WHERE  l.session = s.session)
"""

# Retrieves the list of commands for a session
GET_SESSION_COMMANDS_SQL="""SELECT session, input from logstash WHERE session
IN %s AND event_id='cowrie.command.input' ORDER BY ts ASC"""   

UPDATE_SESSION_HASH_SQL="""INSERT INTO sessions_hash_map VALUES ( %s, %s )"""

# New sessions are recorded in the 'session_trainer" table for processing.
RECORD_SESSION_SQL="""INSERT INTO session_trainer VALUES ( %s, %s )  ON CONFLICT DO NOTHING"""

def generate_hash(session_array):
    # Join the array with new lines and compute SHA256 hash.
    h = hashlib.new('sha256')
    h.update(('\n').join(session_array).encode('UTF-8'))
    return h.hexdigest()

def process_session(chunk): 
    conn = db_pool.getconn()
    cursor = conn.cursor()
    # Get all session data in one go. Processing happens in memory.
    cursor.execute(GET_SESSION_COMMANDS_SQL, (tuple(chunk),))
    rows = cursor.fetchall()
    for session_id in chunk:
        # Extract commands for a particular session from the SQL response.
        commands = [ x[1] for x in rows if x[0] == session_id ]
        hash = generate_hash(commands)
        cursor.execute(UPDATE_SESSION_HASH_SQL,(session_id, hash))
        cursor.execute(RECORD_SESSION_SQL,(hash, False))
    conn.commit()
    db_pool.putconn(conn)

def get_work():
    db_conn = db_pool.getconn()
    cursor = db_conn.cursor()
    log.info("Fetching work.")
    cursor.execute(GET_WORK_SQL, [BATCH_SIZE])
    session_ids = [ x[0] for x in cursor.fetchall() ]
    db_pool.putconn(db_conn)
    return session_ids

def schedule_work(sessions):
    for batch in numpy.array_split(sessions, BATCH_SIZE):
        with futures.ThreadPoolExecutor(max_workers=max_threads) as pool:
            threads = [ pool.submit(process_session, chunk) for chunk in numpy.array_split(batch, max_threads) ]
            # Check for exceptions from any of our threads
            for t in threads:
                t.result()

try:
    while True:     
        time.sleep(5)
        sessions = get_work()
        if len(sessions) == 0:
            log.info('Nothing to do.')
            continue
        else:
            log.info("{} sessions in {} threads. Batch size {}.".format(len(sessions), max_threads, BATCH_SIZE))
            schedule_work(sessions)
            log.info("Processing completed!")
except KeyboardInterrupt:
    print("Interrupted by user! Exiting.")
    db_pool.closeall()




