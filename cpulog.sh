#!/bin/bash

# Collect CPU usage data from a process and plot resulting data
# version 1.1
# author  einKnie@gmx.at

# internal flags
RUN=1
DEBUG=0
ERROR=0
CONFIG=0
PLOT=1
SETPID=1
AUTO=0

# config
FILE="/tmp/generic.log"
APP=""
PID=0
COMMENT=""

# FUNCTIONS
# --------

function on_abort {
  RUN=0
  log_debug "Measure aborted"
}

function log_error() {
  echo Error: $1
}

function log_debug() {
  if [ $DEBUG -eq 1 ]; then
    echo Debug: $1
  fi
}

function plot() {
  if [ $PLOT -eq 0 ]; then
    echo "gnuplot is not available. Not plotting."
    return
  fi

  gnuplot -p << END
    set title "CPU Usage of $APP $COMMENT"
    set yrange [0.0:100.0]
    set xlabel "time [h:m:s]"
    set ylabel "CPU load caused by $APP [%]"
    set timefmt "%s "
    set xdata time
    set format x "%H:%M:%S"
    set format y "%.0f"
    
    plot "$FILE"  using 1:2 t "CPU usage" with lines
END
}

function print_usage {
  echo
  echo "Collect CPU usage of a given process over time and store data to specified file."
  echo "Optionally plot collected data using gnuplot"
  echo
  echo "-f | --file <filename>  ... output file [default: /tmp/generic.log]"
  echo "                            if the file exists, you have the option to plot it"
  echo "-n | --name <name>      ... set target by name"
  echo "-p | --pid <pid>        ... set target by pid"
  echo "-c | --comment <string> ... an optional title appendix for the graph"
  echo "                            for example, 'while playing a video'"
  echo "-a                      ... automatic mode. Files are overwritten and data is plotted."
  echo "-x                      ... don't do anything, just print the config"
  echo "                            that resulted from your parameters"
  echo "-h | --help             ... show this help message"
  echo
}

function print_config {
  if [ $DEBUG -eq 1 ]; then
    echo "Current Configuration:"
    echo "Output file:  $FILE"
    echo "Looking for PID: $SETPID"
    echo "Watching app: $APP"
    echo "Watching app by PID: $PID"
    echo "Adding comment: $COMMENT"
  fi
}

function get_name_from_pid {
  APP=$(cat /proc/$PID/stat | grep $PID | sed -r s/^.*$PID\\s+.\([a-zA-Z]+\).*$/\\1/)
  if [ "$APP" == "" ]; then
    log_error "Did not find a running process with PID $PID"
    ERROR=$((ERROR+1))
  fi
}

function get_pid_from_name {
  pid=$(pgrep -xi $APP 2> /dev/null)
  if [ $(grep -c . <<<$pid) -gt 1 ]; then
    log_error "Found more than one process of the name $APP. Please provide the PID"
    ERROR=$((ERROR+1))
  elif [ "$pid" == "" ]; then
    log_error "Did not find a running process of the name $APP."
    ERROR=$((ERROR+1))
  else
    PID=$pid
    return
  fi

  PID=0
}

function check_dependencies {
  which gnuplot &> /dev/null
  if [ $? -eq 1 ]; then
    log_error "Gnuplot not found. Plotting is not available."
    PLOT=0
  fi
}

# SCRIPT START
# -----------

# get arguments
while (( "$#" )); do
  case "$1" in
    -f | --file)
      FILE=$2
      shift 2
      ;;
    -n | --name)
      APP=$2
      shift 2
      ;;
    -p | --pid)
      PID=$2
      SETPID=0
      shift 2
      ;;
    -c | --comment)
      COMMENT=$2
      shift 2
      ;;
    -a)
      AUTO=1
      shift 1
      ;;
    -h | --help)
      print_usage
      exit 0
      ;;
    -x)
      CONFIG=1
      shift 1
      ;;
    *)
      log_error "unknown parameter $1"
      print_usage
      exit 1
      ;;
  esac
done

# verify arguments and get APP && PID
if [ "$APP" == "" ] && [ $PID -eq 0 ]; then
  log_error "Need either target name or pid"
  print_usage
  exit 
elif [ $SETPID -eq 0 ] && [ "$APP" != "" ]; then
  log_error "Need either target name or pid, not both"
  print_usage
  exit 1
elif [ $SETPID -eq 0 ]; then
  get_name_from_pid
  log_debug "$APP"
elif [ $SETPID -eq 1 ]; then
  get_pid_from_name
  log_debug "$PID"
fi

# abort if there were any errors
if [ $ERROR -gt 0 ]; then
  echo "Too many errors. Aborting..."
  exit 1
fi

# flag set by '-x' parameter
if [ $CONFIG -eq 1 ]; then
  print_config
  exit 0
fi

# check if gnuplot is installed
check_dependencies

# if file exists, ask to plot instead of collecting new data
# auto mode skips this step
if [ $AUTO -eq 0 ]; then
  if [ -f $FILE ]; then
    echo "I see that '$FILE' already exists."
    if [ $PLOT -eq 0 ]; then
      read -p "Overwrite file? [y/N]" INPUT
      if [ "$INPUT" == "y" ] || [ "$INPUT" == "Y" ]; then
        :
      else
        exit 0
      fi
    else
      read -p "Plot the old file? [y/N] " INPUT
      if [ "$INPUT" == "y" ] || [ "$INPUT" == "Y" ]; then
        plot
        exit 0
      fi
    fi
  fi
fi

# file rotation
if [ $DEBUG -eq 0 ]; then
  rm "$FILE.bak" &> /dev/null
  mv $FILE $FILE.bak &> /dev/null
  touch $FILE
fi

trap on_abort SIGINT
echo "Collecting data..."
echo "(stop collecting with CTRL-C)"

# collect data and log to file
while [ $RUN -eq 1 ]; do
  echo -n "$(date +%s) " >> $FILE
    top -b  -p $PID -n1 | grep -i $PID | sed -r 's/^.*[^0-9]([0-9]+\.[0-9]+)\s*[0-9]+\.[0-9]+\s*.*$/\1/' >> $FILE
    sleep 1
done

# ask to plot collected data
if [ $AUTO -eq 0 ]; then
  if [ $PLOT -eq 1 ]; then
    read -p "Plot data? [y/N] " INPUT
    if [ "$INPUT" == "y" ] || [ "$INPUT" == "Y" ]; then
      plot
    fi
  fi
else
  plot
fi

echo 
