#!/usr/bin/env bash


# this script shall perform several actions with a git repo.
# basically, check if remote has changes, update local, update remote, merge(?) etc..

# used to keep personal notes in sync
# i want to work on my personal notes from both the pc and laptop
# worst case simultaneously, and keep the notes synchronized, available on both devices, and w/o loss.
# preliminary idea:
# git stash && git pull && git stash pop && git status || git add * && git commit -m "$action $node $date" && git push
# ----------------------

# try this concept:
# file-global variable, every function writes relevant output to this variable
# and thus, output may be parsed after call, if necessary, depending on return value
output=""

debug=0
quiet=0

logdbg() {
  [ $debug -eq 1 ] && echo "$@"
}

logerr() {
  echo "$@" 1>&2
}

log() {
  [ $debug -eq 0 -a $quiet -eq 1 ] && return 0
  echo "$@"
}

is_git() { 
  # check if pwd is a git repository
  git rev-parse --git-dir &>/dev/null && return 0
  return 1
}

has_remote() {
  # check if remote is reachable
  output="$(git ls-remote 2>&1)"
  return $?
}

local_has_changes() {
    # check if local worktree has changes
    output="$(git status --porcelain)"
    if [ $(git status --porcelain | wc -l) -gt 0 ]; then
      return 0
    else
      return 1
    fi
}

remote_has_changes() {
    # check if remote has updates
    update || { logerr  "failed to fetch remote changes"; return 1; }
    output="$(git rev-list HEAD...origin/${branch} --count)"
    if [ $output -gt 0 ]; then
      logdbg "remote changes detected"
      return 0
    else
      logdbg "no remote updates"
      return 1
    fi
}

update() {
  # fetch remote
  logdbg "updating"
  output="$(git fetch origin)"
  return $?
}

fetch_remote() {
    # update local with remote changes
    # this should also stash and pop any local changes to avoid losing them
    local ret=0
    local has_stash=0


    if local_has_changes ; then
        git stash && { has_stash=1; } || { logerr "failed to stash"; return 1; }
    fi

    git pull || { logerr "failed to pull remote changes"; ret=1; }

    if [ has_stash -eq 1 ]; then
        git stash pop || { logerr "failed to pop stash"; return 1; }
    fi

    return $ret
}

print_info() {

if is_git ; then

  if ! has_remote ; then
    logerr "no connection to remote!"
  fi

  if local_has_changes ; then
    log "local changes detected:"
    log "$output"
  else
    log "worktree clean"
  fi
  logdbg "$output"

  if remote_has_changes; then
    log "remote changes detected:"
    log "$output commits behind target branch"
  else
    log "up to date with remote"
  fi
  logdbg "$output"

else
  log "this is not a git repo"
fi

}

push_local() {

  # commit && push local changes
  return 0
}

print_help() {
  echo "$(basename $scriptname)"
  echo ""
  echo " -d <path/to/repo> ... git repo on which to perform operations"
  echo " -b <branch name>  ... remote branch name [default: master]"
  echo " -q                ... quiet, no regular log output"
  echo " -v                ... enable debug output"
  echo " -h                ... print this help"
  echo ""
}

print_config() {
  log "repo:          $maindir"
  log "remote branch: $branch"
  log ""

  [ $debug -eq 0 ] && return 0
  
  log "DEBUG  enabled"
  log -n "QUIET "
  [ $quiet -eq 1 ] && { log " enabled"; } || { log " disabled"; }
  log ""
}


# defaults
maindir="$(pwd)"
branch="master"
scriptname="$0"

# parameter parsing
err=0
while getopts "d:b:qvh" arg; do
  case $arg in
    d)
      [ -d "$OPTARG" ] && { maindir="$OPTARG"; } || { logerr "-d not a directory"; ((err++)); }
      ;;
    b)
      branch="$OPTARG"
      ;;
    q)
      quiet=1
      ;;
    v)
      debug=1
      ;;
    h)
      print_help
      exit 0
      ;;
  esac
done

[ $err -gt 0 ] && { logerr "invalid parameter(s) provided. aborting."; exit 1; }


# TODOs:
# - more parameters for specific actions (update, push, etc...)

print_config

pushd "$maindir" &>/dev/null

print_info

popd &>/dev/null
