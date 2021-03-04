#!/usr/bin/env bash

# collect_gitdata.sh
#
# this script takes two parameters:
# script.sh <toplevel dir path> <depth>
# start looking at <toplevel dir path> until depth <depth> and list any found git repos

is_git_dir() {
  if [ -d "$1/.git" ] ;then
    if $(git -C "$1/" status &>/dev/null) ; then
      return 0
    fi
  fi
  return 1
}

is_svn_dir() {
  if [ -d "$1/.svn" ] ;then
    return 0
  fi
  return 1
}

# called with a directory path, will traverse into every descendent directory
# and print info on
# expects topdir to be a full path
check_subdirs() {
  [ ! -d "$1" ] && return 1

  # if depth has reached 0, quit
  [ $2 -eq 0 ] && return 0

  cd "$1"
  local curdir="$(pwd)"
  local depth=$2

  for d in $(find . -maxdepth 1 -type d -not -path '*/\.*' -not -path '.' | sed 's/^\.\///g') ; do
    cd "$curdir"

    if $(is_git_dir "$(pwd)/$d") ; then
      pushd "./$d" &>/dev/null

      repourl="$(echo "$(git remote get-url --all origin 2>/dev/null)" | sed -r 's;^git@([^:]*):;https://\1/;g')"
      [ -z "$repourl" ] && repourl="< no remote >"
      hash="$(git rev-parse @ 2>/dev/null)"
      refs="$(git show-ref --heads --tags --dereference 2>/dev/null | grep $hash)"

      echo "path:   $(pwd)"
      echo "remote: $repourl"
      echo "hash:   $hash"
      echo "tags/heads:"
      echo "$refs"
      echo

      popd &>/dev/null

    elif $(is_svn_dir "$(pwd)/$d") ; then
      pushd "./$d" &>/dev/null

      repourl="$(svn info --show-item repos-root-url 2>/dev/null)"
      [ -z "$repourl" ] && repourl="< no remote >"
      hash="$(svn info --show-item revision 2>/dev/null)"
      refs="$(svn info --show-item relative-url 2>/dev/null)"

      echo "path:   $(pwd)"
      echo "remote: $repourl"
      echo "revision:   $hash"
      echo "tags/heads:"
      echo "$refs"
      echo

      popd &>/dev/null
    fi

    # recursively call check_subdirs w/ depth-1
    # once depth==0 is reached, this will stop
    check_subdirs "${curdir}/${d}/" $((depth - 1))
  done
  return 0
}

#
# MAIN
#


[ -z "$1" ] && { echo "need a path" ; exit 1 ; }
[ ! -d "$1" ] && { echo "need a valid path" ; exit 1 ; }

depth=""
if [ -n "$2" ]; then
  case $2 in
    ''|*[!0-9]*) echo "not a number" ; exit 1 ;;
    *) depth=$2 ;;
  esac
else
  # set depth to -1 in order to keep going until no further subdirs are found
  depth="-1"
fi

topdir="$(cd "$1" ; pwd -P)"
check_subdirs "$topdir" "$depth"
