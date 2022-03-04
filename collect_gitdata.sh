#!/usr/bin/env bash

# collect_gitdata.sh
#
# usage:
# script.sh -p <toplevel dir path> [-d <depth> -r -h]
# start looking at <toplevel dir path> until depth <depth> and list any found git repos

topdir=""
remote_only=0

show_help() {
    echo
    echo "$(basename "$0")"
    echo " usage:"
    echo " ./$(basename "$0") -p <toplevel dir path> [-d <depth> -r -h]"
    echo
    echo " -p <path>    ... set starting directory"
    echo " -d <depth>   ... set depth to descend into [default: infinite]"
    echo " -r           ... show remote repos only    [default: remote and local]"
    echo " -h           ... show this help"
    echo
}

# check if directory contains a git repo
is_git_dir() {
    # check for -e instead of -d b/c sometimes .git is a file in submodules
    if [ -e "$1/.git" ]; then
        if $(git -C "$1/" status &>/dev/null); then
            return 0
        fi
    fi
    return 1
}

# check if directory contains an svn repo
is_svn_dir() {
    if [ -d "$1/.svn" ]; then
        return 0
    fi
    return 1
}

# print git/svn info of directory if there is any
get_info() {
    found=0
    if $(is_git_dir "$1"); then
        found=1
        pushd "$1" &>/dev/null

        path="$(pwd)"
        repourl="$(echo "$(git remote get-url --all origin 2>/dev/null)")"
        hash="$(git rev-parse @ 2>/dev/null)"
        refs="$(git show-ref --dereference 2>/dev/null | grep $hash)"
        dirty="$(git status --short 2>/dev/null)"

        popd &>/dev/null

    elif $(is_svn_dir "$1"); then
        found=1
        pushd "$1" &>/dev/null

        path="$(pwd)"
        repourl="$(svn info --show-item repos-root-url 2>/dev/null)"
        hash="$(svn info --show-item revision 2>/dev/null)"
        refs="$(svn info --show-item relative-url 2>/dev/null)"
        dirty="$(svn status 2>/dev/null)"

        popd &>/dev/null
    fi

    # print info
    if [ $found -eq 1 ]; then
        if [ -z "$repourl" ]; then
            [ $remote_only -eq 1 ] && { return 0; } || { repourl="<no remote>"; }
        fi
        echo "remote:     $repourl"
        echo "local path: $path"
        [ -n "$dirty" ] && {
            echo "working dir is dirty:"
            echo "$dirty"
            echo
        }
        echo "revision:   $hash"
        echo "tags/heads:"
        echo "$refs"
        echo "--------------------"
        echo
    fi
}

# expects topdir to be a full path
check_subdirs() {
    [ ! -d "$1" ] && return 1

    # if depth has reached 0, quit
    [ $2 -eq 0 ] && return 0

    cd "$1"
    local curdir="$(pwd)"
    local depth=$2

    for d in $(find . -maxdepth 1 -type d -not -path '*/\.*' -not -path '.' | sed 's/^\.\///g'); do
        cd "$curdir"

        [ -f "${curdir}/$d" ] && continue

        # check if $d is a git/svn dir and print info
        get_info "${curdir}/$d"

        # recursively call check_subdirs w/ depth-1
        # once depth==0 is reached, this will stop
        check_subdirs "${curdir}/${d}/" $((depth - 1))
    done
    return 0
}

#
# MAIN
#

while getopts "p:d:rh" arg; do
    case $arg in
        p)
            [ ! -d "${OPTARG}" ] && { echo "need a valid path" ; exit 1 ; } || { startdir="$OPTARG" ; }
            ;;
        d)
            case "$OPTARG" in
                *[!0-9]*) echo "depth is not a number" ; exit 1 ;;
                *) depth="$OPTARG" ;;
            esac
            ;;
        r)
            remote_only=1
            ;;
        h)
            show_help
            exit 0
            ;;
        *)
            echo "Invalid parameter" ; exit 1
            ;;
    esac
done

[ -z "$startdir" ] && { echo "no starting directory set" ; exit 1 ; }
[ -z "$depth" ] && depth="-1"

topdir="$(cd "$startdir" ; pwd -P)"
get_info "$topdir"
check_subdirs "$topdir" "$depth"
