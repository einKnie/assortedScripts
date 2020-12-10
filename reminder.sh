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

dir="$(cd "$(dirname "$0")"; pwd -P)"
ownpath="$dir/"$(basename "$0")""
remind_cmd="zenity --info --no-wrap --text="

origfile="$dir/original"
testfile="$dir/tmp"

message=""
op=-1
timer=0
time_str=""
timer_time=""

link=0
linktext="You wanted me to remind you of this"

# set a reboot cron job
set_cron() {

  own_cmd="$ownpath --off -m \"$1\""
  timeout="10"
  cmd="@reboot sleep $timeout && DISPLAY=:0 $remind_cmd\"$1\" && $own_cmd"

  crontab -l > "$origfile"
  crontab -l > "$testfile"
  echo "$cmd" >> "$testfile"
  cat "$testfile" | crontab -
  rm "$testfile"
}

# unset a reboot cron job
unset_cron() {

  cmd="${remind_cmd}\"$1\""

  crontab -l > "$origfile"
  crontab -l > "$testfile"
  cat "$testfile" | grep -v "$cmd" | crontab -
  rm "$testfile"
}

# set a timer
set_timer() {
  interactive=0
  if [ "$time_str" == "" ] ;then
    interactive=1
    time_str="$(get_input "When?")"
    [ $? -eq 1 ] && return 1
  fi

  if ! parse_time "$time_str" ;then
    if [ $interactive -eq 1 ] ;then
      show_note "Invalid time. Aborting"
    fi
    return 1
  fi

  cmd="DISPLAY=:0 $remind_cmd\"$1\""

  at -t "$timer_time" <<EOF
  $cmd
EOF
}

get_input() {
  str="$(zenity --entry --text="$1")"
  if [ "$str" == "" ] ;then
    show_note "Aborted"
    return 1
  fi
  echo "$str"
  return 0
}

show_note() {
  $(zenity --info --no-wrap --text="$1")
}

show_info() {
  $(notify-send "reminder" "$1" )
}

# parse time from caller (format: [xm yh zd])
parse_time() {

  if [ "$(echo "$1" | sed -r 's/[0-9mMhHdD[:space:]]*//g')" != "" ] ;then
    echo "invalid time string"
    return 1
  fi

  m="$(echo "$1" | sed -r 's/([0-9]*)\s*[mM].*|./\1/g')"
  h="$(echo "$1" | sed -r 's/([0-9]*)\s*[hH].*|./\1/g')"
  d="$(echo "$1" | sed -r 's/([0-9]*)\s*[dD].*|./\1/g')"

  [ "$m" == "" ] && m=0
  [ "$h" == "" ] && h=0
  [ "$d" == "" ] && d=0

  echo "$m min, $h hours, $d days"

  if [ "$(($m + $h + $d))" -eq 0 ] ;then
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
  echo " --on                 ... set a timer"
  echo " --off                ... unset a timer [only if reboot timer]"
  echo " -m | --message <str> ... set the reminder message string"
  echo " -t | --time    <str> ... set time for timer"
  echo "                          time must be quoted and in format \"5m 3h 1d\""
  echo "                          -> 5 minutes, 3 hours, one day"
  echo "                          (only non-zero values must be specified)"
  echo " -l | --link          ... transform the message to a clickable link in the reminder"
  echo " -h | --help              show this help screen"
  echo
  echo " note:"
  echo "  if no time is set, a reminder is set for next reboot."
  echo "  if no message is provided, the user in queried interactively."
  echo "  same goes for -t time, if -t is specified without a time string"
}

### SCRIPT START

# parse arguments
while [ "$#" -ne 0 ] ;do
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
      if [ ! -z "$2" ] && [[ "${2:0:1}" != "-" ]] ;then
        message="$2"
        shift
      fi
      shift
      ;;
    -l | --link)
      link=1
      shift
      ;;
    -t | --time)
      timer=1
      if [ ! -z "$2" ] && [[ "${2:0:1}" != "-" ]] ;then
        time_str="$2"
        shift
      fi
      shift
      ;;
    -h |--help)
      print_help
      exit 0
      ;;
    --debug)
      set -x
      shift
      ;;
    *)
      echo "invalid command"
      print_help
      exit 1
      ;;
  esac
done

if [ $link -eq 1 ] && [ ! -z "$message" ];then
  message="<a href='$message'>$linktext</a>"
fi

# execute arguments
if [ "$op" -eq 1 ] ;then

  if [ -z "$message" ] ;then
    # query message from user
    message="$(get_input "Remind you of what, exactly?")"
    [ $? -eq 1 ] && exit 0
  fi

  if [ "$timer" -eq 1 ] ;then
    set_timer "$message" && show_info "timer set for $(echo $timer_time | sed -r 's/^([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2}).*$/\3.\2.\1, \4:\5/g')"
  else
    set_cron "$message"
  fi

elif [ "$op" -eq 0 ] ;then
    unset_cron "$message"
else
  echo "no (valid) operation set!"
  print_help
  exit 1
fi

exit $?
