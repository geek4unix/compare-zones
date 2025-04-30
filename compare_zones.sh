#!/bin/bash

# Set up colours
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RESET=$(tput setaf 7 && tput setab 0)

# Set inputs
while [[ $# -gt 0 ]]; do
  case $1 in
    -1|--nameserver1)
      T1="$2"
      shift
      shift
      ;;
    -2|--nameserver2)
      T2="$2"
      shift
      shift
      ;;
    -d|--domain)
      DOMAIN="$2"
      shift
      shift
      ;;
    -s|--subdomain)
      SUBDOMAIN="$2"
      shift
      shift
      ;;
    -f|--file)
      FILE="$2"
      shift
      shift
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}"

if [ ! -z "$FILE" ]; then
  while read line; do
    ZONE=$DOMAIN 
    TEMP="$line"
    TEMP+=".$ZONE"
    ZONE=$TEMP
    
    echo "-------------------------------------------"
    echo "Checking $ZONE"
    echo "-------------------------------------------"

    

    # Quick and dirty input check
    if [[ -z $T1 ]] || [[ -z $T2 ]] || [[ -z $ZONE ]]; then
      echo "Usage: $0 ZONE Target_Server_1 Target_Server_2 .e.g. $0 my.com 1.2.3.4 5.6.7.8"
      exit 1
    fi

    # Set counters
    ERROR_COUNT=0
    WARN_COUNT=0

    # Start looping through record types
    for RECORD_TYPE in A AAAA CNAME MX TXT SOA NS ANY; do
      # Get the result for this record type from each server
      RESULT_T1=$(dig $RECORD_TYPE @$T1 $ZONE +short | sort)
      RESULT_T2=$(dig $RECORD_TYPE @$T2 $ZONE +short | sort)

      # Make a common report
      REPORT="(srv: $T1):\n$RESULT_T1\n\n(srv: $T2):\n$RESULT_T2"

      # If the results are not equal, display a warning, or not depending on type
      if [[ $RESULT_T1 != $RESULT_T2 ]]; then
        case "${RECORD_TYPE}" in
          SOA|NS|ANY)
            ERROR_LEVEL="${YELLOW}WARN${RESET}"
            WARN_COUNT=$((WARN_COUNT + 1))
            echo "${ERROR_LEVEL}: $RECORD_TYPE record differs - examine results"
            echo -e "${YELLOW}${REPORT}${RESET}"
            ;;
          A|AAAA|CNAME|MX|TXT)
            ERROR_LEVEL="${RED}ERROR${RESET}"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            echo "${ERROR_LEVEL}: ${RECORD_TYPE} record differs"
            echo -e "${RED}${REPORT}${RESET}"
            ;;
        esac
      else
        ERROR_LEVEL="${GREEN}OK${RESET}"
        echo "${ERROR_LEVEL}: ${RECORD_TYPE}"
      fi
    done

    # Output counts
    echo -e "\n${RED}ERRORS:${RESET} $ERROR_COUNT\n${YELLOW}WARNINGS:${RESET} $WARN_COUNT"
    echo "--------------------------------------------"
    echo ""
    echo ""
  done < "$FILE"
else
  if [ ! -z "$SUBDOMAIN" ]; then
    ZONE=$DOMAIN
    TEMP="$SUBDOMAIN"
    TEMP+=".$ZONE"
    ZONE=$TEMP
  else
    ZONE=$DOMAIN
  fi

  # Quick and dirty input check
  if [[ -z $T1 ]] || [[ -z $T2 ]] || [[ -z $ZONE ]]; then
    echo "Usage: $0 ZONE Target_Server_1 Target_Server_2 .e.g. $0 my.com 1.2.3.4 5.6.7.8"
    exit 1
  fi

  # Set counters
  ERROR_COUNT=0
  WARN_COUNT=0

  # Start looping through record types
  for RECORD_TYPE in A AAAA CNAME MX TXT SOA NS ANY; do
    # Get the result for this record type from each server
    RESULT_T1=$(dig $RECORD_TYPE @$T1 $ZONE +short | sort)
    RESULT_T2=$(dig $RECORD_TYPE @$T2 $ZONE +short | sort)

    # Make a common report
    REPORT="(srv: $T1):\n$RESULT_T1\n\n(srv: $T2):\n$RESULT_T2"

    # If the results are not equal, display a warning, or not depending on type
    if [[ $RESULT_T1 != $RESULT_T2 ]]; then
      case "${RECORD_TYPE}" in
        SOA|NS|ANY)
          ERROR_LEVEL="${YELLOW}WARN${RESET}"
          WARN_COUNT=$((WARN_COUNT + 1))
          echo "${ERROR_LEVEL}: $RECORD_TYPE record differs - examine results"
          echo -e "${YELLOW}${REPORT}${RESET}"
          ;;
        A|AAAA|CNAME|MX|TXT)
          ERROR_LEVEL="${RED}ERROR${RESET}"
          ERROR_COUNT=$((ERROR_COUNT + 1))
          echo "${ERROR_LEVEL}: ${RECORD_TYPE} record differs"
          echo -e "${RED}${REPORT}${RESET}"
          ;;
      esac
    else
      ERROR_LEVEL="${GREEN}OK${RESET}"
      echo "${ERROR_LEVEL}: ${RECORD_TYPE}"
    fi
  done

  # Output counts
  echo -e "\n${RED}ERRORS:${RESET} $ERROR_COUNT\n${YELLOW}WARNINGS:${RESET} $WARN_COUNT"
fi

if [[ $ERROR_COUNT -gt 0 ]]; then
  exit 1
else
  exit 0
fi
