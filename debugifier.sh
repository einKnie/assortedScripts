#!/usr/bin/env bash

# todo:
# *need to account for functions w/o ()


print_help() {
	echo "debugifier v0.1"
	echo
	echo "usage:"
	echo " ./debugifier.sh <filename>"
}

[ -z "$1" ] && { print_help ; exit 1 ; }
[ -z "$2" ] && { print_help ; exit 1 ; }

inputfile="$1"
op="$2"

if [ "$op" -eq 1 ] ;then
	sed -i.bak -r 's/(^.*[^\s]*\s*\(\)\s*\{.*$)/\1\n\techo "in $(basename $BASH_SOURCE) ${FUNCNAME[0]}"/gm' "$inputfile"
else
	sed -i.bak -r -z 's/\n\t*echo "in \$\(basename \$BASH_SOURCE\) \$\{FUNCNAME\[0\]\}"//g' "$inputfile"
fi
