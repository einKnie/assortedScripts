#!/usr/bin/env bash

# script shall take three args: binary1 binary2 commands
# the binaries are both called with the given commands and their output
# is compared for differences.
# script returns 0 if output is the same, else 1
# usage example:
#   $0 -x1 ./lbimaker_old -x2 ./lbimaker_new -c [ testcmds]

print_help() {
  log "refactorTester v0.1"
  log
  log "usage:"
  log " $scriptname -x1 <executable1> -x2 <executable2> -c [commands \"...\" [-q -h ]"
  log
  log " -x1\t... left-side executable"
  log " -x2\t... right-side executable"
  log "  -c\t... commands (must be quoted)"
  log "  -q\t... quiet mode, disables all output to stdout"
  log "  -h\t... show this help screen"
}

log() {
  if [ "$quiet" -eq 0 ] ; then
    echo -e "$1"
  fi
}

scriptname="$(basename "$0")"
path="$(cd "$(dirname "$0")"; pwd -P)/"
bin_left=""
bin_right=""
res_left="$path/res_left"
res_right="$path/res_right"
quiet=0

# find '-q' first to turn off logging from the start
case "$@" in
  *-q*)
    quiet=1
    ;;
esac

log "running in \"$path\""

while [ "$#" -ne 0 ]; do
  case $1 in
    -x1)
      shift
      bin_left="$1"
      log "left:      $bin_left"
      ;;
    -x2)
      shift
      bin_right="$1"
      log "right:     $bin_right"
      ;;
    -c)
      shift
      command="$1"
      log "commands:  $command"
      ;;
    -q)
      ;;
    -h | --help)
      quiet=0
      print_help
      exit 0
      ;;
    *)
      print_help
      exit -1
  esac
  shift
done

log

err=0
[[ -d "$bin_left"  || ! -x "$bin_left"  ]] && { log "executable 1 is not actually an executable!" ; err=1 ; }
[[ -d "$bin_right" || ! -x "$bin_right" ]] && { log "executable 2 is not actually an executable!" ; err=1 ; }

[ "$err" -eq 1 ] && exit -1

eval "$bin_left" ${command} > "$res_left"
eval "$bin_right" ${command} > "$res_right"

res="$(diff "$res_left" "$res_right")"
if [ "$?" -eq 0 ]; then
  log "it's the same!"
  exit 0
else
  log "there are differencs!"
  log
  log "$res"
  exit 1
fi
