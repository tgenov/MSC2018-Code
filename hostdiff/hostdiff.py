#!/usr/bin/env python

import os
import io
import sys
from pexpect import pxssh, exceptions
import re
import time
import json

ssh_options={"StrictHostKeyChecking": "no",
             "UserKnownHostsFile": "/dev/null"}

username = "root"
hostname = "localhost"
password = "admin"

host_A = pxssh.pxssh(echo=False, options=ssh_options)
host_A.PROMPT='root@LEDE:.*#\s($)'
host_B = pxssh.pxssh(echo=False, options=ssh_options)


def lazy_connect():
    if host_A.closed and host_B.closed:
        host_A.login(hostname, username, password, port=2222, auto_prompt_reset=False)
        host_B.login(hostname, username, password, port=2122)
        while host_A.closed or host_B.closed:
            timer.sleep(0.1)

def row_exists(command):
    return command.rstrip() in dict.keys(lookup_table)

def add_row(entry, host='host_B'):
    command=entry['command'].rstrip()
    response=entry['response'][host]
    if response != "":
      lookup_table[command] = response

def host_execute(command):
    command = command.rstrip()
    host_A.sendline(command)
    host_B.sendline(command)
    try:
      host_A.prompt(timeout=5)
      response_A = '\r\n'.join(host_A.before.splitlines()[1:])+'\r\n'
    except exceptions.EOF:
        response_A = ''
    try:
        host_B.prompt(timeout=5)
        response_B = host_B.before
    except exceptions.EOF:
        response_B = ''
    # Cowrie doesn't support disabling local echo on the TTY so we discard the first line (which the command being echoed back to us).
    return {
        'command': command, 'response': { 'host_A': response_A, 'host_B': response_B  }
    }

def diff(entry):
    if entry['response']['host_A'] != entry['response']['host_B']:
        print("Command: %s") % (entry['command'])
        print("Host A response:")
        print(entry['response']['host_A'])
        print()
        print("Host B response:")
        print(entry['response']['host_B'])
        if not row_exists(entry['command'].rstrip()):
            add_row(entry)

#Load the command -> response lookup table
try:
    with open('responder.json') as f:
        lookup_table = json.load(f)
except IOError:
    lookup_table = {}

# Replay the session file against both hosts and record any difference in responses
print('Processing session ID: {}'.format(sys.argv[1]))
with io.open(sys.argv[1], encoding='utf8') as f:
    content = f.readlines()
    for line in content:
        # Cowrie handles this
        if re.search(re.compile('(^|\s)cat (/bin/.*|\.s)'), line):
            print('Command contains cat. Skipping: {}'.format(line))
            continue
        # Ampersands trigger background jobs which requires a stateful approach (session graph?)
        if re.search(re.compile('[^&]&[^&]'), line):
            print('Command contains ampersand. Skipping: {}'.format(line))
            continue
        # Don't download any URLs
        if re.search(re.compile('http://'), line):
            print('Command contains URL. Skipping: {}'.format(line))
            continue
        # We already have a response for this command
        if not row_exists(line):
            lazy_connect()
            diff(host_execute(line))

with open('responder.json.new' , 'w') as json_output:
    json.dump(lookup_table, json_output)
    os.rename('responder.json.new', 'responder.json')

if not host_A.closed:
  host_A.close()
if not host_B.closed:
  host_B.close()
