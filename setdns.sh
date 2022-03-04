#!/bin/bash

# Set a permament DNS entry, replacing the current settings
# version 0.1
# author  einKnie@gmx.at

# TODO: check if nmcli is available
# TODO: add ipv6 support
# TODO: general error checking

# internal flags
DEBUG=0
OP=0

# common variables
declare -A CONN

function check_dependencies {
    which nmcli &>/dev/null
    if [ $? -eq 1 ]; then
        log_error "nmcli is not installed."
        exit 1
    fi
}

function log_debug() {
    if [ $DEBUG -eq 1 ]; then
        echo $1
    fi
}

function log_error() {
    echo "error: $1"
}

function show_dns {
    for LINE in $(nmcli -f ip4.DNS dev show ${CONN[dev]}); do
        DNS_ORIG=$(echo $LINE | grep -v DNS | sed -r 's/^.*:\s*([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*)$/\1/')
        if [ "$DNS_ORIG" != "" ]; then
            echo $DNS_ORIG
        fi
    done
}

function get_op {
    OP=0
    while [ $OP -eq 0 ]; do
        echo
        echo " - - - - - - - - - - - - - - - - "
        echo "|  Add nameserver    ... 1     |"
        echo "|  Remove nameserver ... 2     |"
        if check_auto_dns; then
            echo "|  Disable auto DNS  ... 3     |"
        else
            echo "|  Enable auto DNS   ... 3     |"
        fi
        echo "|  Finished          ... ENTER |"
        echo " - - - - - - - - - - - - - - - - "
        echo
        read -p "Choose operation: " INPUT

        case "$INPUT" in
            "1")
                OP=1
                ;;
            "2")
                OP=2
                ;;
            "3")
                OP=3
                ;;
            "")
                OP=8
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
        log_error "No data got"
        return 1
    fi

    # check if DNS server pingable
    echo "Checking nameserver address..."
    ping -c 1 -I ${CONN[dev]} $NAMESERV &>/dev/null
    if [ $? -eq 1 ]; then
        log_error "Cannot reach DNS server at $NAMESERV."
        return 1
    else
        log_debug "address pingable"
    fi
    return 0
}

function add_nameserv {
    nmcli con mod ${CONN[uuid]} +ipv4.dns $NAMESERV
}

function remove_nameserv {
    nmcli con mod ${CONN[uuid]} -ipv4.dns $NAMESERV
}

function auto_dns_off {
    nmcli con mod ${CONN[uuid]} ipv4.ignore-auto-dns yes
}

function auto_dns_on {
    nmcli con mod ${CONN[uuid]} ipv4.ignore-auto-dns no
}

function check_auto_dns {
    nmcli con show ${CONN[uuid]} | grep "ipv4.ignore-auto-dns" | grep "yes" &>/dev/null
    if [ $? -eq 0 ]; then
        log_debug "auto dns disabled"
        return 0
    else
        log_debug "auto dns enabled"
        return 1
    fi
}

function con_restart {
    nmcli con down ${CONN[uuid]}
    sleep 1
    nmcli con up ${CONN[uuid]}
}

# TODO: finish
function get_uuid_from_dev() {
    TMP=$(nmcli -f CONNECTIONS dev show $1)
    echo $TMP
}

# list active connections and let user choose one
function choose_conn {
    I=0
    LIST=""
    declare -A MAP
    declare -A KEYMAP

    # get all active connections and assemble maps
    while read LINE; do
        DAT=($(echo $LINE | sed -r 's/^.*\s([a-fA-F0-9-]+)\s.*\s([a-zA-Z0-9]+)$/\1 \2/'))
        MAP[${DAT[0]}]=${DAT[1]}
        KEYMAP[$I]=${DAT[0]}

        LIST+="$I\t${DAT[1]}\t(${DAT[0]})\n"
        I=$((I + 1))
    done <<<$(nmcli con show --active | grep -v NAME)

    # user menu
    ISVALID=0
    while [ $ISVALID -eq 0 ]; do
        echo -e $LIST
        read -p "Choose an interface: " INPUT
        if ! [[ $INPUT =~ ^[0-9]+$ ]] || [ $((INPUT)) -ge $I ]; then
            echo
            echo "Invalid input!"
            echo "Enter the index of your chosen connection (or cancel with CTRL-C)"
        else
            echo "You chose" ${MAP[${KEYMAP[$INPUT]}]}
            CONN[dev]=${MAP[${KEYMAP[$INPUT]}]}
            CONN[uuid]=${KEYMAP[$INPUT]}
            ISVALID=1
        fi
    done
}

# SCRIPT START
# ------------

# check if nmcli is available
check_dependencies

# (FOR THE FUTURE)
# check arguments
if [ $# -lt 1 ]; then
    :
else
    echo "Got argument: " $1

fi

# let user choose a connection to modify
choose_conn

log_debug "Connection UUID:  ${CONN[uuid]}"
log_debug "Interface:        ${CONN[dev]}"

echo "- - - - - - - - - - "
echo "Current DNS settings:"
show_dns
echo "- - - - - - - - - - "

read -p "Modify these settings? [Y/n] " INPUT
if [ "$INPUT" == "n" ] || [ "$INPUT" == "N" ]; then
    echo "Aborted"
    exit 0
fi

while [ $OP -ne 8 ]; do
    get_op
    log_debug $OP
    # do operation
    case $OP in
        1)
            get_nameserv
            if [ $? -eq 0 ]; then
                add_nameserv
                echo "Done"
            else
                log_error "Failed to add nameserver"
            fi
            ;;
        2)
            # remove nameserver
            get_nameserv
            if [ $? -eq 0 ]; then
                remove_nameserv
                echo "Done"
            else
                log_error "Failed to remove nameserver"
            fi
            ;;
        3)
            # disable auto dns
            if check_auto_dns; then
                auto_dns_off
            else
                auto_dns_on
            fi
            echo "Done"
            ;;
        8)
            echo "Completing settings..."
            ;;
        *)
            echo "Invalid input"
            exit 1 # ok to exit here since if that actully happens we have bigger problems
            ;;
    esac
done

# restart connection
echo
echo "Restarting connection..."
con_restart
echo "Done!"

echo
echo "New DNS settings:"
show_dns
