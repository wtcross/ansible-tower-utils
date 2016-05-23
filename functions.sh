#!/bin/bash
#
# Copyright (c) 2016 Tyler Cross
#
# Helper functions for interacting with the Tower REST API.
# The Tower CLI is used when possible and CURL usage as a
# fallback.
#
# Tower CLI is required to be installed and configured on
# the system running these functions. The Tower CLI is used
# as a lookup source for credentials.
set -o nounset
set -o errexit

check-dependencies() {
  local DEPS=( curl jq shyaml tower-cli )
  for i in "${DEPS[@]}"
  do
    if ! which ${i} >/dev/null; then
      echo ${i} must be installed
      exit 1
    fi
  done
}

# Look up the Tower username from the configured Tower CLI.
tower-username() {
  local TOWER_USERNAME=$(tower-cli config username | shyaml get-value username)
  echo ${TOWER_USERNAME}
}

# Look up the Tower host from the configured Tower CLI.
tower-host() {
  local TOWER_HOST=$(tower-cli config host | shyaml get-value host)
  echo ${TOWER_HOST}
}

# Look up the Tower password from the configured Tower CLI.
tower-password() {
  local TOWER_PASSWORD=$(tower-cli config password | shyaml get-value password)
  echo ${TOWER_PASSWORD}
}

# Run a job and wait for it to finish.
#
# Arguments:
#   ${1}: ID of the job template to use for creating the job
#   ${@:2}: Arguments to pass to the `tower-cli job launch` invocation
# Returns: ID of the created job
run-job() {
  local JOB_TEMPLATE_ID=${1}
  local ARGS=${@:2}
  local OUTPUT=$(tower-cli job launch --format=json --job-template=${JOB_TEMPLATE_ID} ${ARGS})
  local JOB_ID=$(echo ${OUTPUT} | jq .id)
  tower-cli job monitor ${JOB_ID} >/dev/null
  echo ${JOB_ID}
}

# Get the value of a debug message. Useful for grabbing output like IP
# addresses and other provisioned resources.
#
# Arguments:
#   ${1}: ID of the job to query
#   ${2}: Hostname of the originating job event
#           - must be url encoded
#   ${3}: Name of the debug task being looked up
#           - must be url encoded
# Returns: Contents of the message being queried
job-event-debug-msg() {
  local JOB_ID=${1}
  local HOST_NAME=${2}
  local DEBUG_TASK_NAME=${3}
  local JOB_DATA=$(curl -s -k -H "Accept: application/json" \
    --user ${TOWER_USERNAME}:${TOWER_PASSWORD} \
    https://${TOWER_HOST}/api/v1/jobs/${JOB_ID}/job_events/?task__exact=${DEBUG_TASK_NAME}\&event__exact=runner_on_ok\&host_name__exact=${HOST_NAME})
  local MESSAGE=$(echo ${JOB_DATA} | jq .results[0].event_data.res.msg)
  echo ${MESSAGE}
}

check-dependencies
export TOWER_HOST=$(tower-host)
export TOWER_USERNAME=$(tower-username)
export TOWER_PASSWORD=$(tower-password)
