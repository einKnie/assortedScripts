#!/usr/bin/env bash

# validate all .avi files in a given directory (recursively)
# this will take some time

# dependencies
depends="mplayer"
logdir="/tmp"
verbose=0

print_help() {
    echo "$0 - validate avi files"
    echo "this will take some time, depending on video length"
    echo
    echo " * usage"
    echo "  $ $0 [ -h -v ] file|dir"
    echo "   -v    .. verbose logging"
    echo "   -h    .. shot help"
    echo
    echo " provide either a single .avi file or"
    echo " a directory containing .avi files (may be in subdirs)"
    echo
    echo " * dependencies"
    echo "  [ $depends ]"
    echo
}

check_depends() {
    local err=0
    for dep in $depends ; do
        which "$dep" &>/dev/null || { echo "dependency not met: $dep"; ((err++)); }
    done
    return $err
}

err() {
    echo -e "\e[31m$1\e[0m" 1>&2
}

log() {
   [ $verbose -eq 0 ] && return 0
   echo "$@"
}

# run validation on all .avi files found in dir
validate_dir() {
    pushd "$1" &>/dev/null

    for dir in $(find . -maxdepth 1 -type d); do
        for file in "$(basename "$dir")"/*.avi ; do
            [ -f "$file" ] || continue
            validate_avi "$file"
        done
    done

    popd &>/dev/null
}

# write mplayer log to file, grep the file for errors simulataneously
# and kill mplayer on the first error found to speed thing up a bit
validate_avi() {
    tmp="$(mktemp $logdir/validate_avi.XXXXXX)"
    log "analyzing $1 (log stored in $tmp)"

    $(mplayer -benchmark -vo null -ao null "$1" &>"$tmp")&
    local mplay=$!
    log "mplayer pid: $mplay"

    monitor_mplayer "$tmp" $mplay &
    local monitor=$!
    log "monitor pid: $monitor"

    # wait for mplayer to stop
    wait_for_pid $mplay
    log "analysis complete"

    # if no errors were found in the file, we need to reap the monitor
    if [ -d "/proc/$monitor" ]; then
        log "killing the mplayer monitor ($monitor)"
        kill $monitor
    fi

    # recheck the logfile to pass status to caller
    if grep -iE '(marker does not)|error|incomplete' "$tmp" &>/dev/null ; then
        err "errors found in file $1"
        return 1
    fi
    return 0
}

# wait for the program with given pid to finish
# and show a spinner
wait_for_pid() {
    local -a lin=('/' '-' '\' '|')
    while [ -d "/proc/$1" ] ;do
        echo -ne "${lin[i++ % ${#lin[@]}]}"
        sleep 1
        echo -ne "\b"
    done
    # space is necessary to overwrite last loop's \b
    echo " "
}

# monitor mplayer output $1 and kill mplayer (pid: $2) on first error found
monitor_mplayer() {
    tail -f "$1" | grep --line-buffered -m 1 -i -E '(marker does not)|error|incomplete' &>/dev/null
    kill_mplayer $2
}

# find the current running child of the mplayer process to kill
# and kill it
kill_mplayer() {
    local mplay="$(get_real_pid $1)"
    log "killing mplayer with pid $mplay"
    kill $mplay
}

# get current pid of a forking process by
# recursively checking for child pids
# $1 is the original pid
get_real_pid() {
    res="$(ps -o pid= --ppid $1)"
    if [ -z "$res" ]; then
        echo $1
    else
        get_real_pid $res
    fi
}

###############################################################################
#                              SCRIPT MAIN                                    #
###############################################################################

check_depends || { print_help; exit 1; }

# parse args and then shift over them
# to handle the path as $1
while getopts "vh" opt ;do
    case $opt in
        h)
            print_help
            exit 0
            ;;
        v)
            verbose=1
            ;;
    esac
done
shift $((OPTIND-1))

# check arg and switch between dir and file mode
if [ -d "$1" ]; then
    log "directory mode"
    validate_dir "$1"
elif [ -f "$1" ]; then
    log "single file mode"
    validate_avi "$1"
else
    print_help
    exit 1
fi
