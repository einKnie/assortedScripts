#!/usr/bin/env bash

# todo:
# *need to account for functions w/o ()
# * maybe add option to remove all other echos
#		(but this might be tricky, b/c at reversal, how do we know whether an echo was already commented out beforehand)


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

rep="\n\techo \"in \$(basename \$BASH_SOURCE) \${FUNCNAME[0]}\""
rer="$(echo "$rep" | sed -r 's/\$|\{|\}|\(|\)|\[|\]/\\&/g')"

echo "$rep"
echo
echo "$rer"
echo

if [ "$op" -eq 1 ] ;then
	sed -i.bak -r "s/^(function\s*)?[a-zA-Z0-9_]+\s*(\(\))?\s*\{\s*$/&${rep}/gm" "$inputfile"
else
	sed -i.bak -r -z "s/${rer}//g" "$inputfile"
fi
