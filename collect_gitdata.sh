#!/usr/bin/env bash

# take folder as argument, recurse through subfolders.
# if  git dir is found, check remote url, branch/tag and hash
# optionally return to stdout or write to file (?)

is_git_dir() {
  if [ -d "$1/.git" ] ;then
    return 0
  fi
  return 1

}

# expects topdir to be a full path
check_subdirs() {
  [ ! -d "$1" ] && return 1

  cd "$1"
  local curdir="$(pwd)"

  for d in * ; do
    cd "$curdir"
    [ -f "${curdir}/$d" ] &&  continue
    [ -L "${curdir}/$d" ] &&  continue

    if $(is_git_dir "$(pwd)/$d") ; then
      pushd "./$d" &>/dev/null

      repourl="$(echo "$(git remote get-url --all origin 2>/dev/null)" | sed -r 's;^git@([^:]*):;https://\1/;g')"
      [ -z "$repourl" ] && repourl="< no remote >"
      hash="$(git rev-parse @)"
      refs="$(git show-ref --heads --tags --dereference | grep $hash)"

      echo "path:   $(pwd)"
      echo "remote: $repourl"
      echo "hash:   $hash"
      echo "tags/heads:"
      echo "$refs"
      echo

      popd &>/dev/null
    fi

    check_subdirs "${curdir}/${d}/"
  done
  return 0
}

#
# MAIN
#

[ -z "$1" ] && { echo "need a path" ; exit 1 ; }
[ ! -d "$1" ] && { echo "need a valid path" ; exit 1 ; }

topdir="$(cd "$1" ; pwd -P)"
check_subdirs "$topdir"
