#!/usr/bin/env bash

# todo:
# * maybe add option to remove all other echos
#		(but this might be tricky, b/c at reversal, how do we know whether an echo was already commented out beforehand)

print_help() {
    echo "debugifier v0.1"
    echo
    echo "usage:"
    echo " ./debugifier.sh -s <filename> -o <1|0>"
    echo "   -o <1/0>            ... 1 debugify, 0 undebugify"
    echo "   -s <path/to/script>"
    echo
}

while [ "$#" -ne 0 ]; do
    case "$1" in
        -s)
            if [ -n "$2" ] && [[ ${2:0:1} != "-" ]]; then
                inputfile="$2"
                shift
            fi
            shift
            ;;
        -o)
            if [ -n "$2" ] && [[ ${2:0:1} != "-" ]]; then
                op="$2"
                shift
            fi
            shift
            ;;
        -h | --help)
            print_help
            exit 0
            ;;
        *)
            print_help
            exit 1
            ;;
    esac
done

[[ -z "$inputfile" || -z "$op" ]] && { print_help ; exit ; }

rep="\techo \"in \$(basename \$BASH_SOURCE) \${FUNCNAME[0]}\"\n"
rer="$(echo "$rep" | sed -r 's/\$|\{|\}|\(|\)|\[|\]/\\&/g')"

if [ "$op" -eq 1 ]; then
    sed -i.bak -r -z "s/\n\s*(function\s*)?[a-zA-Z0-9_]+\s*(\(\))?\s*(\n)?\s*\{.*\n/&${rep}/gm" "$inputfile"
else
    sed -i.bak -r -z "s/${rer}//g" "$inputfile"
fi
