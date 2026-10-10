#!/usr/bin/env bash
# Must stay bash 3.2 compatible: sudo on macOS runs /bin/bash 3.2.

SCRIPTNAME=$(basename "$0")
BLOCK_SIZE=4194304 # 4MiB in bytes: GNU and BSD dd disagree on suffixes

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

Works on Linux and macOS.

USAGE:

$SCRIPTNAME -i <input image file> -o <output volume>

ARGS:

-i | --input-image | --input-file
        Path to image file. Must be *.iso, *.img or *.sav

-o | --output-volume
        Whole disk to write to.
        Linux: sdb, nvme0n1, mmcblk0   macOS: disk5 or rdisk5
        List disks with: lsblk (Linux) / diskutil list external (macOS)

-y | --yes
        Skip the confirmation prompt

-f | --force
        Allow writing to a disk reported as internal / non-removable

-h | --help
        Show this message

AUTHOR:

Christopher James Ward (2021)
E: christopher.ward@264nm.pw

******************************************************************
EOF
exit 1
}

function die {
  echo "$*" >&2 && exit 1
}

function is_root {
  if [ "$EUID" -ne 0 ]; then
    die "Must be run as root.."
  fi
}

function detect_platform {
  case "$(uname -s)" in
    Linux)  PLATFORM=linux ;;
    Darwin) PLATFORM=darwin ;;
    *)      die "Unsupported OS: $(uname -s)" ;;
  esac
}

function validate_image {
  local fullfile="$1"
  local filename extension
  filename=$(basename -- "$fullfile")
  extension="${filename##*.}"

  [[ -f "$fullfile" ]] || die "Input image file not found: ${fullfile}"
  if [[ ! ${extension} =~ ^(img|iso|sav)$ ]]; then
    die "Not a valid extension. Please use *.img *.iso *.sav"
  fi
  IMAGE_SIZE=$(wc -c < "$fullfile" | tr -d ' ')
  echo "Input image file: ${filename} ($(human_size "$IMAGE_SIZE"))"
}

function human_size {
  awk -v b="$1" 'BEGIN { split("B KiB MiB GiB TiB", u); i = 1
    while (b >= 1024 && i < 5) { b /= 1024; i++ }
    printf "%.1f %s", b, u[i] }'
}

# ---- Linux -------------------------------------------------------------

# Sets DISK (used for queries) and TARGET (what dd writes to)
function linux_resolve_volume {
  DISK="/dev/${1#/dev/}"
  TARGET="$DISK"
  [[ -b "$DISK" ]] || die "Volume does not exist: ${DISK}"
  [[ "$(lsblk -dno TYPE "$DISK")" == "disk" ]] \
    || die "${DISK} is not a whole disk. Use e.g. sdb, not sdb1"
  if lsblk -no MOUNTPOINT "$DISK" | grep -qx '/'; then
    die "${DISK} holds the running root filesystem. Refusing."
  fi
}

function linux_is_removable {
  local rm tran
  read -r rm tran <<< "$(lsblk -dno RM,TRAN "$DISK")"
  [[ "$rm" == "1" || "$tran" == "usb" ]]
}

function linux_disk_size {
  lsblk -bdno SIZE "$DISK"
}

function linux_show_disk {
  lsblk -o NAME,SIZE,MODEL,TRAN,MOUNTPOINT "$DISK"
}

function linux_unmount {
  local part
  for part in $(lsblk -lnpo NAME "$DISK" | tail -n +2); do
    umount "$part" 2>/dev/null
  done
  if lsblk -no MOUNTPOINT "$DISK" | grep -q .; then
    die "Could not unmount all partitions on ${DISK}"
  fi
}

function linux_dd_flags {
  echo "oflag=direct"
}

function linux_eject {
  command -v eject > /dev/null && eject "$DISK"
}

# ---- macOS -------------------------------------------------------------

function darwin_plist_value {
  diskutil info -plist "$DISK" | plutil -extract "$1" raw - 2>/dev/null
}

function darwin_resolve_volume {
  local name="${1#/dev/}"
  name="${name#r}"
  [[ "$name" =~ ^disk[0-9]+$ ]] \
    || die "${1} is not a whole disk. Use e.g. disk5 or rdisk5, not disk5s1"
  DISK="/dev/${name}"
  TARGET="/dev/r${name}" # raw device is much faster to write
  [[ -b "$DISK" ]] || die "Volume does not exist: ${DISK}"
}

function darwin_is_removable {
  [[ "$(darwin_plist_value Internal)" == "false" ]]
}

function darwin_disk_size {
  darwin_plist_value TotalSize
}

function darwin_show_disk {
  diskutil list "$DISK"
}

function darwin_unmount {
  diskutil unmountDisk "$DISK" || die "Could not unmount ${DISK}"
}

function darwin_dd_flags {
  echo ""
}

function darwin_eject {
  diskutil eject "$DISK"
}

# ---- Main --------------------------------------------------------------

function platform {
  local fn="$1"
  shift
  "${PLATFORM}_${fn}" "$@"
}

function validate_volume {
  platform resolve_volume "$1"

  if ! platform is_removable; then
    if [[ -z "$FORCE" ]]; then
      die "${DISK} is reported as internal / non-removable. Use --force if you are sure."
    fi
    echo "WARNING: ${DISK} is internal / non-removable (--force given)"
  fi

  local disk_size
  disk_size=$(platform disk_size)
  if [[ -n "$disk_size" && "$IMAGE_SIZE" -gt "$disk_size" ]]; then
    die "Image ($(human_size "$IMAGE_SIZE")) is larger than ${DISK} ($(human_size "$disk_size"))"
  fi
}

function confirm {
  echo
  platform show_disk
  echo
  [[ -n "$ASSUME_YES" ]] && return
  local answer
  read -r -p "ALL DATA on ${DISK} will be destroyed. Type YES to continue: " answer
  [[ "$answer" == "YES" ]] || die "Aborted."
}

function burn {
  local flags progress
  flags=$(platform dd_flags)
  # status=progress is missing from dd on older macOS releases
  if dd if=/dev/zero of=/dev/null count=0 status=progress 2> /dev/null; then
    progress="status=progress"
  fi
  # shellcheck disable=SC2086 # flags/progress are intentionally word-split
  dd if="$INPUT_IMAGE" of="$TARGET" bs="$BLOCK_SIZE" conv=fsync $flags $progress \
    || die "dd failed"
  sync
}

[ $# -lt 1 ] && show_usage
while [ -n "$1" ]; do
  case "$1" in
    -h|--help)
      show_usage
      ;;
    -i|--input-image|--input-file)
      shift
      INPUT_IMAGE="$1"
      ;;
    -o|--output-volume)
      shift
      VOLUME="$1"
      ;;
    -y|--yes)
      ASSUME_YES=1
      ;;
    -f|--force)
      FORCE=1
      ;;
    *)
      echo "Incorrect input provided: $1"
      show_usage
  esac
  shift
done

[[ -n "$INPUT_IMAGE" && -n "$VOLUME" ]] || show_usage

detect_platform
is_root
validate_image "$INPUT_IMAGE"
validate_volume "$VOLUME"
confirm
platform unmount
burn
platform eject
echo "Done. ${INPUT_IMAGE##*/} written to ${DISK}."
