#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

DATE=${DATE:-$(date +%Y-%m-%d)}

ARCHIVE_DIR=$(dirname $(readlink -f $0))
ARCHIVES="${ARCHIVE_DIR}/ARCHIVES"

SERVO_DIR=$(readlink -f ${SERVO_DIR:-../servo})
SERVO="${SERVO_DIR}/mach run -r -z \
  --userscripts ${ARCHIVE_DIR}/user-agent-js \
  --certificate-path ${ARCHIVE_DIR}/proxy-certs/pywb-ca.pem \
  --pref dom.testperf.enabled"

OUTPUT_DIR=$(readlink -f ${OUTPUT_DIR:-output})
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

# wayback and proxychains are much happier if they're run from the directory with their config files
cd ${ARCHIVE_DIR}

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
    timeout 5m proxychains ${SERVO} ${URL} | grep WARC | sed -e "s/WARC/${ARCHIVE}/" >> ${OUTPUT}

    # Kill the wayback server
    kill ${PID}

done < ${ARCHIVES}
