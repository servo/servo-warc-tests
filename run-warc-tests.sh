#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

DATE=$(date +%Y-%m-%d)

SERVO_DIR="../servo"
SERVO="${SERVO_DIR}/mach run -r -z \
  --userscripts user-agent-js \
  --certificate-path proxy-certs/pywb-ca.pem \
  --pref dom.testperf.enabled"

OUTPUT_DIR="output"
OUTPUT="${OUTPUT_DIR}/warc-tests-${DATE}.csv"

# The port number, which should match what's in proxychains.conf
PORT="8321"

# The CSV column names, which should match what's in user-agent-js
CSV_COLUMNS="archive,date,url,\
navigationStart,domLoading,domInteractive,\
topLevelDomComplete,domComplete,\
loadEventStart,loadEventEnd,\
isTopLevel"

# Stop the wayback server if we interrupt the script
trap 'kill $(jobs -pr)' SIGINT SIGTERM

# Write the CSV column names
echo "Creating output file ${OUTPUT}"
echo ${CSV_COLUMNS} > ${OUTPUT}

# Read the archives from the ARCHIVE file
while IFS=: read ARCHIVE URL; do

    # Start the wayback server in tx1he background
    echo ""
    echo "Testing ${URL} from archive ${ARCHIVE}"
    wayback --proxy ${ARCHIVE} --port ${PORT} > /dev/null 2>&1 &

    # Wait for the server to start up
    while ! PID=$(lsof -Pi :${PORT} -t); do sleep 1; done

    # Run a proxified servo on the URL, and save any WARC lines in the output file
    timeout 2m proxychains ${SERVO} ${URL} | grep WARC | sed -e "s/WARC/${ARCHIVE}/" >> ${OUTPUT}

    # Kill the wayback server
    kill ${PID}

done < "ARCHIVES"

