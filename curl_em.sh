#!/bin/bash

set -e

URL=${1:?"usage: ${0} <url> [<count=30> [<sleep=1>]]"}
COUNT=${2:-"30"}
SLEEP=${3:-"1"}

for i in $(seq 1 ${COUNT}) ; do
  echo -n "${i} "
  (curl -fs ${URL} 2>&1 > /dev/null) && echo "OK" || echo "Failed"
  sleep ${SLEEP}
done
