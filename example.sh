#!/bin/bash
set -o nounset
set -o errexit

SCRIPT_DIR="$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)"
source "${SCRIPT_DIR}/functions.sh"

JOB_ID=$(run-job 125)
INSTANCE_IP=$(job-event-debug-msg ${JOB_ID} localhost instance%20ip)
