#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

set -o errexit
set -o nounset
set -o pipefail

DATE=${DATE:-$(date +%Y-%m-%d)}

SCRIPT_FILE=$(readlink -f "$0")

SCRIPT_DIR=$(dirname "${SCRIPT_FILE}")
ARCHIVES="${SCRIPT_DIR}/ARCHIVES"

SERVO_DIR=$(readlink -f "${SERVO_DIR:-../servo}")
SERVO_CMD=("${SERVO_DIR}/mach" "run" "-r" "-z"
  "--userscripts" "${SCRIPT_DIR}/user-agent-js"
  "--certificate-path" "${SCRIPT_DIR}/proxy-certs/pywb-ca.pem"
  "--pref" "dom.testperf.enabled")

OUTPUT_DIR=$(readlink -f "${OUTPUT_DIR:-output}")
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
cd "${SCRIPT_DIR}"

# Write the CSV column names
echo "Creating output file ${OUTPUT}"
echo "${CSV_COLUMNS}" > "${OUTPUT}"

# Read the archives from the ARCHIVE file
while IFS=: read ARCHIVE URL; do

    # Start the wayback server in tx1he background
    echo ""
    echo "Testing ${URL} from archive ${ARCHIVE}"
    wayback --proxy "${ARCHIVE}" --port "${PORT}" > /dev/null 2>&1 &

    # Wait for the server to start up
    while ! PID=$(lsof -Pi :"${PORT}" -t); do echo "Waiting for wayback server"; sleep 1; done

    # Run a proxified servo on the URL, and save any WARC lines in the output file
    echo Running "${SERVO_CMD[@]}" "${URL}"
    timeout 5m proxychains "${SERVO_CMD[@]}" "${URL}" | grep WARC | sed -e "s/WARC/${ARCHIVE}/" >> "${OUTPUT}"

    # Kill the wayback server
    kill "${PID}"

done < "${ARCHIVES}"
