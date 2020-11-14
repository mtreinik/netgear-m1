#!/bin/bash
#
# Utility for querying and controlling a Netgear M1 router
# Run ./netgear-m1.sh for usage
#

IP=${NETGEAR_M1_IP:-"192.168.1.1"}

URL_BASE="http://$IP"
URL_JSON="${URL_BASE}/api/model.json"
URL_SESSION="${URL_BASE}/sess_cd_tmp"
URL_CONFIG="${URL_BASE}/Forms/config"
URL_LOGIN_OK="${URL_BASE}/index.html"
URL_JSON_OK="${URL_BASE}/success.json"

function post {
  REDIRECT_URL=$(curl --location --silent --output /dev/null --write-out "%{url_effective}" \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --cookie-jar "${COOKIE_JAR}" \
    --cookie "${COOKIE_JAR}" \
    --data-urlencode "token=${TOKEN}" \
    --data-urlencode "err_redirect=$5" \
    --data-urlencode "ok_redirect=$4" \
    --data-urlencode "$1=$2" \
    "${URL_CONFIG}")
  if [ "$3" == "$REDIRECT_URL" ]; then
    return 0
  else
    return 1
  fi
}

function print_usage {
  cat <<EOF
Usage:
  netgear-m1.sh status [--json]
  netgear-m1.sh reboot
  netgear-m1.sh connect
  netgear-m1.sh disconnect
  netgear-m1.sh reconnect
  netgear-m1.sh -h | --help

Options:
  -h --help  Show usage screen.
  --json     Output full router status in JSON format.

Commands:
  status     Output router status. Default is brief human readable output.
  reboot     Reboot router.
  connect    Turn cellular data connection on.
  disconnect Turn cellular data connection off.
  reconnect  Turn cellular data connection off and on again.

By default the utility connects router at IP address 192.168.1.1.
Another IP address can be provided environment variable NETGEAR_M1_IP.
EOF
}

function start_session {
  if [ "$1" != "--json" ]; then
    echo -ne "Starting session...\r"
  fi

  # start session and store it in cookie jar
  COOKIE_JAR=$(mktemp)
  curl --silent --output /dev/null --head --cookie-jar "${COOKIE_JAR}" "${URL_SESSION}"

  # get security token
  JSON=$(curl --silent --cookie "${COOKIE_JAR}" --get "${URL_JSON}")
  TOKEN=$(echo "$JSON" | grep -o '"secToken": "[^"]*",' | sed 's/",//;s/.*"//')
}

# prints a value specified by key $1 from JSON object
function get_from_json {
  echo "$JSON" | grep -o -e "$1\": *[^,]*," | head -1 | sed 's/.*: *//;s/^\"//;s/,$//;s/\"$//'
}

function login {
  echo -ne "Logging in...     \r"
  if post session.password "${PASSWORD}" "${URL_LOGIN_OK}" /index.html /index.html?loginfailed; then
    echo Logged in to "$(get_from_json deviceName)"
  else
    echo Failed to log in to router at IP address "$IP". Invalid password?
    exit_program
  fi
}

function reboot {
  if post general.shutdown restart "${URL_JSON_OK}" /success.json /error.json; then
    echo Rebooting router
  else
    echo Failed to reboot router
    exit_program
  fi
}

function no_ping {
  if ping -c 1 -t 1 "$IP"; then
    sleep 1
    return 1
  else
    return 0
  fi
}

function wait_for_command {
  trap "echo; exit_program" SIGINT SIGTERM
  echo -n "Waiting for $1"
  TRIES=60
  until $2 &> /dev/null ; do
    echo -n "."
    if [ $TRIES -lt 1 ]; then
      echo
      echo Timeout
      exit 1
    fi
    ((TRIES-=1))
  done
  echo
}

function wait_for_router_down {
  wait_for_command "router shutdown" "no_ping"
  echo Router is down
}

function wait_for_router_up {
  wait_for_command "router network adapter" "ping -c 1 -t 2 $IP"
  wait_for_command "router services" "curl --silent --connect-timeout 1 ${URL_SESSION}"
  echo Router is up
}

function connect {
  if post wwan.autoconnect HomeNetwork "${URL_JSON_OK}" /success.json /error.json; then
    echo Connected cellular data
  else
    echo Failed to connect cellular data
    exit_program
  fi
}

function disconnect {
  if post wwan.autoconnect Never "${URL_JSON_OK}" /success.json /error.json; then
    echo Disconnected cellular data
  else
    echo Failed to disconnect cellular data
    exit_program
  fi
}

# remove possible cookie jar
function exit_program {
  if [ -f "${COOKIE_JAR}" ]; then
    rm "${COOKIE_JAR}"
  fi
  exit
}

if [ "$#" -lt 1 ]; then
  echo "Too few command line arguments."
  print_usage
  exit 1
fi

if [ "$#" -gt 2 ]; then
  echo "Too many command line arguments."
  print_usage
  exit 1
fi

case "$1" in
  status)
    start_session "$2"
    ;;
  reboot | connect | disconnect | reconnect)
    read -r -s -p "Password: " PASSWORD
    if [ -t 0 ]; then echo; fi
    start_session
    ;;
  -h | --help)
    print_usage
    ;;
  *)
    echo "Unknown command '$1'"
    print_usage
    exit 1
    ;;
esac

case "$1" in
  status)
    if [ "$2" == "--json" ]; then
      echo "$JSON"
    else
      echo "             Device name: $(get_from_json deviceName)"
      echo "    Battery charge level: $(get_from_json battChargeLevel)"
      echo "              IP address: $(get_from_json IP)"
      echo "      Current radio band: $(get_from_json curBand)"
      echo "        Data transferred: $(get_from_json dataTransferred)"
      echo "Router connection status: $(get_from_json connection)"
    fi
    ;;
  reboot)
    login
    reboot
    wait_for_router_down
    wait_for_router_up
    ;;
  connect)
    login
    connect
    ;;
  disconnect)
    login
    disconnect
    ;;
  reconnect)
    login
    disconnect
    connect
    ;;
esac

exit_program
