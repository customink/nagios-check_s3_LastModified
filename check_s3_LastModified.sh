#!/bin/bash
# set -e
#set -o pipefail

# Author: Doug Wilson

### CHANGELOG
# Date: 11/10/2016
#   Initial release

# takes 3 inputs
#  1: bucket name
#  2: object/key name
#  3: age in seconds to use as critical threshold

# parse command line
PROGNAME=$(basename -- $0)
DEBUG=false

usage () {
    echo ""
    echo "USAGE: "
    echo "  $PROGNAME -b BUCKET -k OBJECT -w warning_age -c critical_age [-d ]"
    echo "     -b BUCKET: name of the S3 bucket"
    echo "     -k OBJECT: full path to the S3 key/object/file"
    echo "     -w and -c values in seconds"
    echo "     [-d] : show debug output"
    exit $STATE_UNKNOWN
}

while getopts "b:k:w:c:d" opt; do
    case $opt in
    b) BUCKET=${OPTARG} ;;
    k) OBJECT=${OPTARG} ;;
    w) WARN=${OPTARG} ;;
    c) CRIT=${OPTARG} ;;
    d) DEBUG=true;;
    *) usage ;;
    esac
done

if [ -z "${BUCKET}" -o -z "${OBJECT}" -o -z "${CRIT}" -o -z "${WARN}" ]; then
    usage
fi

Exit () {
    echo "$1: ${2:0}"
    status=STATE_$1
    exit ${!status}
}

# check for commands
for cmd in basename aws jq; do
    if ! type -p "$cmd" >/dev/null; then
        Exit UNKNOWN "Command \"$cmd\" not found. Please install this dependency."
    fi
done

if [ "${DEBUG}" = true ]; then
  echo "BUCKET = ${BUCKET}"
  echo "OBJECT = ${OBJECT}"
  echo "WARN = ${WARN}"
  echo "CRIT = ${CRIT}"
fi

now=$(date +%s)
obj="$(aws s3api head-object --bucket ${BUCKET} --key ${OBJECT}  2>/dev/null)"
obj_char_count=${#obj}
if [ ${obj_char_count} -lt 10 ]; then
  Exit CRITICAL "Unable to get head-object from \"s3://${BUCKET}/${OBJECT}\".
    Does the bucket/object exist? Do we have access?"
fi
obj_lastmodified="$(echo ${obj} | jq '.LastModified' | tr -d '"')"
obj_lastmodified_epoch="$(date --date=${obj_last_modified} +%s )"
##obj_lastmodified_epoch="$(date --date="$(aws s3api head-object --bucket ${BUCKET} --key ${OBJECT} | jq '.LastModified' | tr -d '"')" +%s)"

if [ "${DEBUG}" = true ]; then
  echo ""
  echo "obj = ${obj}"
  echo "objchar_count = ${obj_char_count}"
  echo "obj_lastmodified =  ${obj_lastmodified}"
  echo "obj_lastmodified_epoch =  ${obj_lastmodified_epoch}"
  echo "now = ${now}"
fi

#let diff_seconds=$((${now} - ${obj_lastmodified_epoch}))
let diff_seconds=( now - obj_lastmodified_epoch )
let diff_minutes=( diff_seconds / 60 )
let diff_hours=( diff_minutes / 60 )
let diff_days=( diff_hours / 24 )
if [ "${DEBUG}" = true ]; then
  echo "diff_seconds = ${diff_seconds}"
  echo "diff_minutes = ${diff_minutes}"
  echo "diff_hours = ${diff_hours}"
  echo "diff_days = ${diff_days}"
fi


message="Object LastModified ${diff_seconds} seconds ago. 
  ${diff_seconds} seconds = ~${diff_minutes} mins, OR ~${diff_hours} hours, OR ~${diff_days} days ago."

if [ ${diff_seconds} -gt ${CRIT} ]; then
  Exit CRITICAL "${message} Crit threshold = ${CRIT} seconds."
elif [ ${diff_seconds} -gt ${WARN} ]; then
  Exit WARNING "${message} Warn threshold = ${WARN} seconds."
else
  Exit OK "${message} Crit threshold = ${CRIT}, and Warn threshold = ${WARN}"
fi

