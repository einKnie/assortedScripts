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
  # check if $1 is a git repository
  local ret=1
  pushd "$1" &>/dev/null
  git rev-parse --git-dir &>/dev/null && ret=0
  popd &>/dev/null
  return $ret
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
  # shot basic info about repo
  if is_git . ; then

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
  echo " -c <cfg file>     ... provide a config file *"
  echo " -q                ... quiet, no regular log output"
  echo " -v                ... enable debug output"
  echo " -h                ... print this help"
  echo ""
  echo "* config file:"
  echo "  provide settings via file. generate a default file with -c \"\""
  echo ""
}

print_cfg() {
  # print the current settings
  log "repo:           $maindir"
  log "remote branch:  $branch"
  log -n "using config:   "
  [ "$cfg" == "" ] && { log "none"; } || { log "$cfg"; }
  log "commit message: $commit"
  log ""

  [ $debug -eq 0 ] && return 0
  
  log "DEBUG  enabled"
  log -n "QUIET "
  [ $quiet -eq 1 ] && { log " enabled"; } || { log " disabled"; }
  log ""
}

generate_cfg() {
  # generate a config file $1 with the current settings
  local file=""

  [ -n "$1" ] && { file="$1"; } || { logerr "gencfg no filename provided"; return 1; }

  [ -f "$file" ] && { logerr "gencfg: file exists $file"; return 1; }

  echo "workdir: $maindir" >> "$file"
  echo "branch: $branch" >> "$file"
}

parse_cfg() {
  # parse a config file $1 and apply settings if valid
  local file=""
  logdbg "trying to parse provided cfg $1"

  [ -n "$1" ] && { file="$1"; } || { logerr "genparse no filename provided"; return 1; }
  [ -f "$file" ] || { logerr "genparse: file not found $file"; return 1; }

  tmpdir="$(realpath $(cat $file | grep workdir | sed -r 's/^.*workdir:\s*(.*)$/\1/g'))"
  logdbg "parsed workdir: $tmpdir"
  if [ -d "$tmpdir" ] && is_git "$tmpdir" ; then
    logdbg "cfg workdir valid"
    maindir="$tmpdir"
  else
    logerr "cfg workdir invalid"
    ((err++))
  fi

  tmpbr="$(cat $file | grep branch | sed -r 's/^.*branch:\s*(.*)$/\1/g')"
  logdbg "parsed branch: $tmpbr"
  if [ -z "$tmpbr" ] || [[ $tmpbr =~ [[space]] ]]; then
    logerr "cfg invalid branch name $tmpbr"
    ((err++))
  else
    logdbg "cfg branch valid: $tmpbr"
    branch="$tmpbr"
  fi

  # commit message optional
  tmpmsg="$(cat $file | grep commit | sed -r 's/^.*commit:\s*(.*)$/\1/g')"
  logdbg "parsed commit message: $tmpmsg"
  if [ -n "$tmpmsg" ]; then
    commit="$tmpmsg"
  fi

  [ $err -gt 0 ] && return 1
  return 0

}


# defaults
cfg_dflt=".repocfg"
maindir="$(pwd)"
branch="master"
cfg=""
scriptname="$0"
commit="automatic push by $scriptname"

# parameter parsing
err=0
while getopts "d:b:c:qvh" arg; do
  case $arg in
    d)
      [ -d "$OPTARG" ] && { maindir="$(realpath $OPTARG)"; } || { logerr "-d not a directory"; ((err++)); }
      ;;
    b)
      branch="$OPTARG"
      ;;
    c)
      tmp="$OPTARG"
      if [ "$tmp" == "" ]; then
        logdbg "generating default config file"
        generate_cfg "$cfg_dflt" && tmp="$cfg_dflt"
      fi
      [ -f "$tmp" ] && { cfg="$tmp"; } || { logerr "-c config file not found;"; ((err++)); }
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
# - more parameters for specific actions (update, push, etc...)i

if [ "$cfg" != "" ] ; then
  parse_cfg "$cfg" || { logerr "Failed to parse provided config file"; exit 1; }
fi

print_cfg
pushd "$maindir" &>/dev/null

print_info

popd &>/dev/null
