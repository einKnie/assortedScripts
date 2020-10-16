#!/usr/bin/env bash

# script shall take three args: binary1 binary2 commands
# the binaries are both called with the given commands and their output
# is compared for differences.
# script returns 0 if output is the same, else 1
# usage example:
#   $0 -x1 ./lbimaker_old -x2 ./lbimaker_new -c [ testcmds]

print_help() {
  echo "refactorTester v0.1"
  echo
  echo "usage:"
  echo " $name -x1 <executable1> -x2 <executable2> -c [commands ... ]"
  echo 
  echo "note: commands will glob all remaining arguments"
  echo "      so it should be the last argument given"
  echo
}

name="$(basename $0)"
path="$(cd "$(dirname "$0")"; pwd -P)/"
bin_left=""
bin_right=""
res_left="$path/res_left"
res_right="$path/res_right"

echo "running in \"$path\""

while [ "$#" -ne 0 ]; do
  case $1 in
    -x1) 
      shift
      bin_left="$1"
      echo -e "left:      $bin_left"
      ;;
    -x2)
      shift
      bin_right="$1"
      echo -e "right:     $bin_right"
      ;;
    -c)
      shift
      command="$@"
      echo -e "commands:  \"$command\""
      ;;
    *)
      print_help
      exit 1
  esac
  shift
done

echo

err=0
[ -x "$bin_left"  ] || (echo "executable 1 is not actually executable!" ; err=1)
[ -x "$bin_right" ] || (echo "executable 2 is not actually exacutable!" ; err=1)
[ "$err" -eq 1    ] && exit 1

$($bin_left $command > $res_left)
$($bin_right $command > $res_right)

res="$(diff $res_left $res_right)"
if [ "$?" -eq 0 ]; then
  echo "it's the same!"
  exit 0
else
  echo "there are differencs!"
  echo
  echo -e "$res"
  exit 1
fi

