#!/usr/bin/env bash


# this script shall perform several actions with a git repo.
# basically, check if remote has changes, update local, update remote, merge(?) etc..

# used to keep personal notes in sync
# i want to work on my personal notes from both the pc and laptop
# worst case simultaneously, and keep the notes synchronized, available on both devices, and w/o loss.
# preliminary idea:
# git stash && git pull && git stash pop && git status || git add * && git commit -m "$action $node $date" && git push
# ---------------------
# todo:
# - possibility to generate commit message from tokens, e.g. 
# commit= "automatic commit from $ME on $NODENAME" and the script replaces $ME w/ scriptname && $NODENAME $hostname
# - better cfg file parsing: no params are required, do not err our when no workdir found etc.
# - implement caller notification in case of merge conflict
# - better auto mode: more error checking, dealing w/ errors etc.
# ---------------------

# try this concept:
# file-global variable, every function writes relevant output to this variable
# and thus, output may be parsed after call, if necessary, depending on return value
output=""

# defaults
debug=0
quiet=0
owndir="$(cd "$(dirname "$0")"; pwd -P)"
scriptname="$(basename $0)"
maindir="$owndir"
branch="master"
cfg="$HOME/.config/repomgr/.cfg"
commit="automatic commit by $scriptname on $HOSTNAME"
auto=0

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

    if [ $has_stash -eq 1 ]; then
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
  git add * && git commit -m "$commit" && git push 
  return $?
}

print_help() {
  echo "$(basename $scriptname)"
  echo ""
  echo " -d <path/to/repo> ... git repo on which to perform operations"
  echo " -b <branch name>  ... remote branch name [default: master]"
  echo " -c                ... generate a default config file *"
  echo " -q                ... quiet, no regular log output"
  echo " -v                ... enable debug output"
  echo " -h                ... print this help"
  echo ""
  echo "* config file:"
  echo "  if a cfg file exists at $cfg, it is parsed"
  echo "  but will be overridden by cmd line params."
  echo ""
}

print_cfg() {
  # print the current settings
  log "repo:           $maindir"
  log "remote branch:  $branch"
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

  [ -d "$(dirname $file)" ] | mkdir -p "$(dirname $file)"

  echo "workdir: $maindir" >> "$file"
  echo "branch: $branch" >> "$file"
  echo "commit: $commit" >> "$file"
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


# parameter parsing
err=0

# if a config file exists at the default location, parse that first
# so we can overwrite the default cfg file values w/ cmd line params (if given)
if [ -f "$cfg" ]; then
  parse_cfg "$cfg" || { logerr "could not parse cfg file at $cfg"; ((err++)); }
fi

while getopts "d:b:caqvh" arg; do
  case $arg in
    d)
      [ -d "$OPTARG" ] && { maindir="$(realpath $OPTARG)"; } || { logerr "-d not a directory"; ((err++)); }
      ;;
    b)
      branch="$OPTARG"
      ;;
    c)
      if [ -f "$cfg" ]; then
        logerr "cfg file already exists at $(dirname "$cfg")"
        ((err++))
      else
        generate_cfg "$cfg" || { logerr "could not create default cfg at $cfg"; ((err++)); }
      fi
      ;;
    a)
      auto=1
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

if ! is_git "$maindir" ; then
  logerr "$maindir is not a git repo"
  ((err++))  
fi

[ $err -gt 0 ] && { logerr "invalid parameter(s) provided. aborting."; exit 1; }

[ $debug -eq 1 ] && print_cfg
pushd "$maindir" &>/dev/null
print_info

ret=0
if [ $auto -eq 1 ]; then
  if remote_has_changes ; then
    fetch_remote || { logerr "failed to apply remote echanges"; ((err++)); }
  fi

  if local_has_changes; then
    push_local || { logerr "failed to push local changes"; ((err++)); }
  fi

  [ $err -gt 0 ] && { logerr "experienced errors"; ret=1; }
fi

popd &>/dev/null
exit $ret
