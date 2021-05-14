#!/bin/bash

# Set up colours
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RESET=$(tput setaf 7 && tput setab 0)

# Set inputs
ZONE=$1
T1=$2
T2=$3

# Quick and dirty input check
if [[ -z $T1 ]] || [[ -z $T2 ]] || [[ -z $ZONE ]]; then
echo "Usage: $0 ZONE Target_Server_1 Target_Server_2 .e.g. $0 my.com 1.2.3.4 5.6.7.8"
exit 1
fi

# Set counters
ERROR_COUNT=0
WARN_COUNT=0

#Start looping through record types
for RECORD_TYPE in A MX TXT SOA NS ANY
do

# Get the result for this record type from each server
RESULT_T1=$(dig $RECORD_TYPE @$T1 $ZONE +short|sort)
RESULT_T2=$(dig $RECORD_TYPE @$T2 $ZONE +short|sort)

# Make a common report
REPORT="$T1 - $RESULT_T1\n$T2 - $RESULT_T2\n"

# If the results are not equal, disaply a warning, or not depending on type
# With domain transfers you can expect SOA,NS to be different, ANY also
# Print out interesting differences

if [[ $RESULT_T1 != $RESULT_T2 ]];then

case "${RECORD_TYPE}" in 
  SOA) 
  echo "$RECORD_TYPE is different - examine results"
  WARN_COUNT=$((WARN_COUNT+1))
  echo -e ${YELLOW}${REPORT}${RESET};;
  NS) 
  echo "$RECORD_TYPE is different - examine results"
  WARN_COUNT=$((WARN_COUNT+1))
  echo -e ${YELLOW}${REPORT}${RESET};;
  ANY)
  echo "${RECORD_TYPE} - some records are different - expected"
  WARN_COUNT=$((WARN_COUNT+1))
  echo -e ${GREEN}${REPORT}${RESET};;
  A)
  echo "${RECORD_TYPE} - differs"
  ERROR_COUNT=$((ERROR_COUNT+1))
  echo -e ${RED}${REPORT}${RESET};;
  MX)
  echo "${RECORD_TYPE} - differs"
  ERROR_COUNT=$((ERROR_COUNT+1))
  echo -e ${RED}${REPORT}${RESET};;
  TXT)
  echo "${RECORD_TYPE} - differs"
  ERROR_COUNT=$((ERROR_COUNT+1))
  echo -e ${RED}${REPORT}${RESET};;
esac
else
  echo "${RECORD_TYPE}"
  echo -e ${GREEN}${REPORT}${RESET}
fi
done

# Output counts
echo "ERRORS: $ERROR_COUNT, WARNINGS: $WARN_COUNT"
if [[ $ERROR_COUNT -gt 0 ]]; then
exit 1
else
exit 0
fi
