#!/bin/bash

# Set a permament DNS entry, replacing the current settings
# version 0.1
# author  einKnie@gmx.at

# internal flags
DEBUG=0
OP=0

function log_debug() {
  if [ $DEBUG -eq 1 ]; then
    echo $1
  fi
}

function show_dns {
  for LINE in $(nmcli -f ip4.DNS dev show ${CONNDATA[1]}); do

    DNS_ORIG=$(echo $LINE | grep -v DNS | sed -r 's/^.*:\s*([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*)$/\1/')
    if [ "$DNS_ORIG" != "" ]; then
      echo $DNS_ORIG
    fi
  done
}

function get_op {
  while [ $OP -eq 0 ]; do
    echo
    echo "Add nameserver    ... 1"
    echo "Remove nameserver ... 2"
    if check_auto_dns; then
      echo "Disable auto DNS  ... 3"
    else
      echo "Enable auto DNS   ... 3"
    fi
    read -p "Choose operation: " INPUT

    case $INPUT in
      1)
        OP=1
        ;;
      2)
        OP=2
        ;;
      3)
        OP=3
        ;;
      *)
        echo "invalid input"
        ;;
    esac
  done
}

function get_nameserv {
  read -p "Enter nameserver address: " NAMESERV
  if [ "$NAMESERV" == "" ]; then
    echo "Error: No data got"
    return 1
  fi

  # check if DNS server pingable
  echo "Checking nameserver address..."
  ping -c 1 -I ${CONNDATA[1]} $NAMESERV &> /dev/null
  if [ $? -eq 1 ]; then
    echo "Cannot reach DNS server at $NAMESERV."
    return 1
  else
    echo "address pingable"
  fi
  return 0
}

function add_nameserv {
  nmcli con mod ${CONNDATA[0]} +ipv4.dns $NAMESERV
}

function remove_nameserv {
  nmcli con mod ${CONNDATA[0]} -ipv4.dns $NAMESERV
}

function auto_dns_off {
  nmcli con mod ${CONNDATA[0]} ipv4.ignore-auto-dns yes
}

function auto_dns_on {
  nmcli con mod ${CONNDATA[0]} ipv4.ignore-auto-dns no
}

function check_auto_dns {
  nmcli con show ${CONNDATA[0]} | grep "ipv4.ignore-auto-dns" | grep "yes" &> /dev/null
  if [ $? -eq 0 ]; then
    log_debug "auto dns disabled"
    return 0
  else
    log_debug "auto dns enabled"
    return 1
  fi
}

function con_restart {
  nmcli con down ${CONNDATA[0]}
  sleep 1
  nmcli con up ${CONNDATA[0]}
}


# get current connection
NAME=$(nmcli connection show --active | grep -v 'vir\|NAME' | sed -r 's/^.*\s([a-fA-F0-9-]+)\s.*\s([a-zA-Z0-9]+)\s+$/\1 \2/')
CONNDATA=($NAME)
echo
echo Connection UUID:  ${CONNDATA[0]}
echo Interface:        ${CONNDATA[1]}

read -p "Set DNS for this connection? [y/N] " INPUT
if [ $INPUT != "y" ] && [ $INPUT != "Y" ]; then
  echo "Aborted"
  exit 0
fi

# show current DNs entries
echo
echo "Original DNS settings:"
show_dns

read -p "Modify? [y/N] " INPUT
if [ $INPUT != "y" ] && [ $INPUT != "Y" ]; then
  exit 0
fi

get_op
# do operation
case $OP in
  1)
    echo "Adding nameserver"
    get_nameserv
    if [ $? -eq 0 ]; then
      add_nameserv
    else
      echo "error: failed to add naeserver"
    fi
    ;;
  2)
    # remove nameserver
    echo "Removing nameserver"
    get_nameserv
    if [ $? -eq 0 ]; then
      remove_nameserv
    else
      echo "error: failed to remove nameserver"
    fi
    ;;
  3)
    # disable auto dns
    if check_auto_dns; then
      echo "Disabling auto dns"
      auto_dns_off
    else
      echo "Enabling auto dns"
      auto_dns_on
    fi
    ;;
  *)
    log_debug "invalid operation"
    exit 1
    ;;
esac

# restart connection
echo
echo "Restarting connection..."
con_restart
echo "Done!"

echo
echo "New DNS settings:"
show_dns
