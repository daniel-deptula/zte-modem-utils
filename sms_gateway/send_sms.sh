#!/bin/bash

# A quick&dirty script that allows to send SMS messages

usage() {
    echo "usage: ${0} phone_no message_text"
}

cleanup() {
    rm -f "${COOKIEJAR}"
}

[ -z "${1}" ] && { usage; exit 1; }
[ -z "${2}" ] && { usage; exit 1; }
PHONE_NO_PATTERN='^[0-9]{9}$'
[[ ${1} =~ ${PHONE_NO_PATTERN} ]] || { echo "Invalid phone number"; usage; exit 1; }

. $(dirname ${0})/send_sms.conf

NUMBER="${1}"
MSG="${2}"
ENCODED_MSG=$(echo -n "${MSG}" | iconv -f ASCII -t UTF-16BE | xxd -p -c 256 | tr '[:lower:]' '[:upper:]')
TIME=$(date '+%y;%m;%d;%H;%M;%S;%:::z' | sed 's/;/%3B/g' | sed 's/+0\?/%2B/g')
ENCODED_PWD=$(echo -n ${MODEM_PWD} | base64 | tr -d '\n' | sha256sum | cut -d' ' -f1 | tr '[:lower:]' '[:upper:]' |  tr -d '\n')
TIMESTAMP="$(date +%s)000"
COOKIEJAR=$(mktemp)

trap cleanup EXIT SIGINT

# Login
LOGIN_RES=$(curl -s --cookie-jar ${COOKIEJAR} --header "Referer: http://${MODEM_ADDR}/index.html" -d "isTest=false&goformId=LOGIN&password=${ENCODED_PWD}" "http://${MODEM_ADDR}/goform/goform_set_cmd_process"  |  python3 -c "import sys, json; r = json.load(sys.stdin); print(r['result'])")
[ "${LOGIN_RES}" = "0" ] || { echo "Login failed"; exit 1; }

# Get FW and HW info
SPECIAL_STR=$(curl -s --cookie ${COOKIEJAR} --header "Referer: http://${MODEM_ADDR}/index.html" "http://${MODEM_ADDR}/goform/goform_get_cmd_process?isTest=false&cmd=Language%2Ccr_version%2Cwa_inner_version&multi_data=1&_=${TIMESTAMP}" |  python3 -c "import sys, json; r = json.load(sys.stdin); print(r['wa_inner_version'] + r['cr_version'])")

# Get the RD
RD=$(curl -s --cookie ${COOKIEJAR} --header "Referer: http://${MODEM_ADDR}/index.html" "http://${MODEM_ADDR}/goform/goform_get_cmd_process?isTest=false&cmd=RD&_=${TIMESTAMP}" |  python3 -c "import sys, json; r = json.load(sys.stdin); print(r['RD'])")
PART1=$(echo -n "${SPECIAL_STR}" | tr -d '\n' | md5sum | cut -d' ' -f1)
AD=$(echo -n "${PART1}${RD}" | tr -d '\n' | md5sum | cut -d' ' -f1)

PAYLOAD="isTest=false&goformId=SEND_SMS&notCallback=true&Number=${NUMBER}&sms_time=${TIME}&MessageBody=${ENCODED_MSG}&ID=-1&encode_type=UNICODE&AD=${AD}"

MSGSEND_RES=$(curl -s --cookie ${COOKIEJAR} --header "Referer: http://${MODEM_ADDR}/index.html" -d "${PAYLOAD}" "http://${MODEM_ADDR}/goform/goform_set_cmd_process"  |  python3 -c "import sys, json; r = json.load(sys.stdin); print(r['result'])")
[ "${MSGSEND_RES}" = "success" ] || { echo "SMS send failed"; exit 1; }
echo "${MSGSEND_RES}"
exit 0
