#!/usr/bin/env bash

# script shall take message from user, then set somehing (e.g. cron, but let's see what's out there first)
# to autorun script at boot to open some window with the user's message or something
# but: obvs, the script should only run once, so either find a way to set a fire-once boot script
# or let the script clean itself up after showing the message

# [DONE] todo: this script should add its own path to command -> quasi @reboot $cmd ; $0 0
# [DONE] todo: add parameter for specific timeout, e.g. 20 minutes!!
#               --> you could use it as an oven timer or something!
#               --> btw: it's really stupid to use cron for this
# [DONE] todo: add option for intercactive input, i.e. scripts opens an input window a la timekeeper
# [DONE] todo: alwys use exact zenity command -> b/c otherwise it woudn't be possible to set multiple timers
#               -> is easy b/c I'll just use $cmd instead of $remind_cmd in self-call

ownpath="$(cd "$(dirname "$0")"; pwd -P)/"$(basename "$0")""
remind_cmd="zenity --info --text="

origfile="./original"
testfile="./tmp"

minutes=""
hours=""
days=""

message=""
op=-1
timer=0
timer_time=""

# set a reboot cron job
set_cron() {

  own_cmd="$ownpath 0 \"$1\""
  cmd="@reboot DISPLAY=:0 $remind_cmd\"$1\" && $own_cmd"
  
  crontab -l > "$origfile"
  crontab -l > "$testfile"
  echo "$cmd" >> "$testfile"
  cat "$testfile" | crontab -
  rm "$testfile"

}

# unset a reboot cron job
unset_cron() {

  cmd="$remind_cmd\"$1\""

  crontab -l > "$origfile"
  crontab -l > "$testfile"
  cat "$testfile" | grep -v "$cmd" | crontab -
  rm "$testfile"
}

# set a timer
set_timer() {

  cmd="DISPLAY=:0 $remind_cmd\"$1\""

  at -t "$timer_time" <<EOF
  $cmd
EOF

}

# parse time from caller (format: [xm yh zd])
parse_time() {

  m="$(echo "$1" | sed 's/^.*\([0-9]\+\)\s*[mM].*$/\1/g')"
  h="$(echo "$1" | sed 's/^.*\([0-9]\+\)\s*[hH].*$/\1/g')"
  d="$(echo "$1" | sed 's/^.*\([0-9]\+\)\s*[dD].*$/\1/g')"

  [ "$m" == "$1" ] && m=0
  [ "$h" == "$1" ] && h=0
  [ "$d" == "$1" ] && d=0

  if [ "$(($m + $h + $d))" -eq 0 ]; then
    echo "invalid time set"
    return 1
  fi
  
  timer_time="$(date -d "$(date +'%D %T') $m minutes $h hours $d days" +'%Y%m%d%H%M.%S')"
  return 0

}

print_help() {
  echo
  echo "reminder v0.3"
  echo 
  echo "$0 --on | --off [ --message <message> -t <time> ]"
  echo
  echo " --on       ... set a timer"
  echo " --off      ... unset a timer [only if reboot timer]"
  echo " --message  ... set the reminder message string"
  echo " -t         ... set time for timer"
  echo "                time must be quoted and in format \"5m 3h 1d\""
  echo "                -> 5 minutes, 3 hours, one day (only non-zero values must be specified)"
  echo 
  echo " note:"
  echo "  if no time is set, a reminder is set for next reboot."
  echo "  if no message is provided, the user in queried interactively."
}

### SCRIPT START

# parse arguments
while [ "$#" -ne 0 ]; do
  case "$1" in
    --on)
      op=1
      shift
      ;;
    --off)
      op=0
      shift
      ;;
    -m | --message)
      message="$2"
      shift 2
      ;;
    -t | --time)
      if ! parse_time "$2" ; then
        echo "invalid time set"
        print_help
        exit 1
      fi
      
      timer=1
      shift 2
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      echo "invalid command"
      print_help
      exit 1
      ;;
  esac
done

#execute arguments
if [ "$op" -eq 1 ]; then
  if [ "$message" == "" ]; then
    # query message from user
    message=$(zenity --entry --text="Remind you of what, exactly?")
    [ "$message" == "" ] && exit 0
  fi

  if [ "$timer" -eq 1 ] ; then
    set_timer "$message"
  else
    own_cmd="$ownpath 0 \"$message\""
    set_cron "$message"
  fi
elif [ "$op" -eq 0 ]; then
    own_cmd="$ownpath 0 \"$message\""
    unset_cron "$message"
else
  echo "no (valid) operation set!"
  print_help
  exit 1
fi

exit 0
