#!/usr/bin/env bash

# usage: <script.sh> <folder> [<destination>]
# <folder>       ... a folder containing audio files (may be nested ad infinitum)
# <destination>  ... destination to copy files to

# this script categorizes an assortment of audio files in a folder structure as follows:
# destination dir
#       L artist 1
#           L album 1
#           L album 2
#           L ...
#       L artist 2
#           L ...
#       L ...
#
# the filename if each song is adapted to <track number>_<title>
# in case some metadata is not available:
# - artist: file is stored under 'various/album/'
# - album:  file is stored under 'artist/other/'
# - track number: file is stored under 'artist/album/<original filename>'

DEBUG=0
COPY=0
WHATIF=0

DEFAULT_ARTIST="various"
DEFAULT_ALBUM="other"

DEST=""
SRC=""
FORMATS="mp3 wma wav"

function print_help {
  echo "Usage"
  echo "  $0 [options]"
  echo " -s | --source      ... source folder"
  echo " -o | --output-dir  ... destination folder"
  echo " -w | --what-if     ... what-if mode. don't copy files, just print what would have been copied"
  echo " -v | --verbose     ... log debug messages"
  echo " -h | --help        ... show this message"
  echo
  echo " ~~ IMPORTANT ~~"
  echo " This script will never change or rename the original files in any way"
  echo " Changes are only performed on the copy"
 }

function debug() {
  if [ $DEBUG -eq 1 ]; then
    echo $1
  fi
}

function warning() {
  echo -e "\033[0;31m$1\033[0m"
}

function isIn() {
  # isIn $list $item
  debug "checking if $2 is in $1"
  [[ $1 =~ (^|[[:space:]])"$2"($|[[:space:]]) ]] && return 1 || return 0
}

function isValid() {
  # check if file is in supported format
  isIn "$FORMATS" $(exiftool -filetypeextension "$1" 2>/dev/null | sed -r 's/.*:\s*(\w+)$/\1/')
  return $?
}

function processDir() {
  echo "processing directory $(basename "$1")"
  # process folder contents
  for FILE in "$1"/*; do
    if [ -d "$FILE" ]; then
      processDir "$FILE"
    else
      categorize "$FILE"
    fi
  done
}

function categorize() {
  # in: file
  # out: nothing, but file is copied to DEST/<artist>/<album>/newFileName.ex
  debug "processing single file: $1"
  NAME=$(basename "$1")

  isValid "$1"
  if [ $? -eq 0 ]; then
    debug "got an invalid file extension: ${NAME##*.}"
    warning "Warning: file type not supported. file <$NAME> will be ignored"
    return
  fi

  ARTIST=$(exiftool -if "\$artist" -p "\${artist;s/\s+$//;s/\s+/_/g;s/[\"\*\.\\/\[\];:?|,]//g;tr/[A-Z]/[a-z]/}" "$1" 2> /dev/null)
  if [ $? -gt 0 ]; then
    warning "Error: Artist not found for $NAME."
    ARTIST=$DEFAULT_ARTIST
  fi

  ALBUM=$(exiftool -if "\$album" -p "\${album;s/\s+$//;s/\s+/_/g;s/[\"\*\.\\/\[\];:?|,]//g;tr/[A-Z]/[a-z]/}" "$1" 2> /dev/null)
  if [ $? -gt 0 ]; then
    warning "Error: Album not found for $NAME"
    ALBUM=$DEFAULT_ALBUM
  fi

  #                                              :1=>01:             :01/10=>01:         :title =>title: :title name=>title_name: :
  FILENAME=$(exiftool -if "\$track" -p "\${track;s/\b(\d{1})\b/0\$1/;s/\/\d+//}_\${title;s/\s+$//;s/\s+/_/g;s/[\"\*\.\\/\[\]:;|,]//g}.\${filetypeextension}" "$1" 2>/dev/null)
  if [ $? -gt 0 ]; then
    warning "Warning: no usable metadata found in file $NAME. keeping original filename"
    FILENAME=$NAME
  fi
  debug "new filename: $FILENAME"

  # copy to destination with new filename
  TARGET=$DEST/"$ARTIST"/"$ALBUM"
  if [ $COPY -eq 1 ]; then
    if [ ! -d "$TARGET" ]; then
      mkdir -p "$TARGET"
    fi
    debug "copying to $TARGET"
    cp "$1" "$TARGET/$FILENAME"
    echo "copied file ($FILENAME) to $TARGET"
  else
    echo "$TARGET/$FILENAME"
  fi
}

# check arguments
if [ $# -eq 0 ]; then
  print_help
  exit 1
fi

while (( "$#" )); do
  case "$1" in
    -o | --output-dir)
      DEST=$2
      shift 2
      ;;
    -s | --source-dir)
      SRC=$2
      shift 2
      ;;
    -w | --what-if)
      WHATIF=1
      shift 1
      ;;
    -v | --verbose)
      DEBUG=1
      shift 1
      ;;
    -h | --help)
      print_help
      exit 0
      ;;
    *)
      warning "Error: Unrecoginzed parameter $1"
      print_help
      exit 1
      ;;
  esac
done

if [ ! -d "$SRC" ];then
  warning "Error: Source is not a directory"
  print_help
  exit 1
fi

if [ $WHATIF -eq 0 ]; then
  if [ "$DEST" == "" ]; then
    # what-if mode
    echo "no output directory provided. running in what-if mode."
    WHATIF=1
  else
    if [ ! -d $DEST ]; then
      read -p "Destination directory does not exist. Create? [Y/n]" INPUT 
      if [ "$(echo $INPUT | tr 'A-Z' 'a-z')" != "n" ]; then
        mkdir -p $DEST
      else
        echo "Aborting..."
        echo "To enable What-If mode, simply don't provide the '-o' option"
        exit 0
      fi
    fi
  fi
fi

# do it
processDir "$SRC"

echo "done"
