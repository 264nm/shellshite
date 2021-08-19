#!/usr/bin/env bash

SCRIPTNAME=$(basename $0) 

function is_root {

  if [ "$EUID" -ne 0 ]; then
    echo "Must be run as root.." && exit 1
  fi
}

function show_usage {
cat << EOF

******************************************************************
$SCRIPTNAME - A wrapper around dd for live usb creation
******************************************************************

DESCRIPTION:

Completely overkill and started as a means of avoiding remembering
a bunch of options required for dd to burn a live USB and then my inner dev 
took control completely ignoring my inner sysad taking what was meant to be
a basic function in my bash profile to this and here we have it...

USAGE:

$SCRIPTNAME -i <input image file> -o <output volume>

ARGS:

-i | --input-file
        Path to image file. Must be *.iso, *.img or *.sav

-o | --output-volume
        Path to the volume you wish to write to i.e sdb

-h | --help
        Show this message

AUTHOR:

Christopher James Ward (2021)
E: christopher.ward@264nm.pw

******************************************************************
EOF
exit 1
}

function validate_image {
  if [ $# -ne 1 ]; then
    echo "BAD DEV MISTAKE BRAH" && exit 10
  fi
  readonly fullfile="${1}"
  filename=$(basename -- "$fullfile")
  extension="${filename##*.}"
  filename="${filename%.*}"
  extension_accepted='(\img|iso|sav)\'
  
  if [[ -e "$fullfile" ]]; then
    echo "Input image File: (${filename})"
  else
    echo "Input image File: (NOT FOUND)"
    echo "Path to ${fullfile} does not exist."
    exit 1
  fi
  if [[ ${extension} =~ $extension_accepted ]]; then
    echo "Not a valid extension. Please use *.img *.image *.sav"
    exit 1
  fi
}

function validate_volume {
  if [ $# -ne 1 ]; then
    echo "BAD DEV MISTAKE BRAH" && exit 10
  fi
  readonly _volume="$1"
  if [[ $_volume =~ *.blk.* ]]; then
    vol=${_volume%p*}; echo $vol
    part=${_volume/$vol/}; echo $part
  elif [[ $_volume =~ ^sd.*$ ]]; then
    part=${_volume%[[:digit:]]}
    vol=${_volume/$part/}; echo $vol
  fi

  if [[ $(</proc/partitions) =~ ${vol} ]]; then
    echo "Volume exists: ${_volume}"
  else
    echo "Volume does not exist: ${_volume}" && exit 1
  fi

}
[ $# -lt 1 ] && show_usage
while [ ! -z "$1" ];do
   case "$1" in
        -h|--help)
          show_usage
          ;;
        -i|--input-image)
          shift
          INPUT_IMAGE="$1"
          echo "Input Image File: $INPUT_IMAGE"
          ;;
        -o|--output-volume)
          shift
          VOLUME="$1"
          echo "Volume Name: $VOLUME"
          ;;
        *)
       echo "Incorrect input provided"
       show_usage
   esac
shift
done

is_root
validate_image $INPUT_IMAGE
validate_volume $VOLUME

dd if="$INPUT_IMAGE" of="$VOLUME" bs=16M oflag=direct status=progress

