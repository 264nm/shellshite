#!/bin/bash

SCRIPTNAME=$(basename $0)

function show_usage {
    cat <<- EOF

******************************************************************
$SCRIPTNAME - Transfer and Group TV Shows by Folder
******************************************************************

DESCRIPTION:

Find downloaded TV episodes and copy them to a target folder,
grouping by show name.

i.e.

    ~/Downloads/Good.Omens.S02E01.The.Arrival.2160p.AMZN.WEB-DL.DDP5.1.HDR.H.265-NTb.mkv
    ~/Downloads/Good.Omens.S02E05.The.Ball.2160p.AMZN.WEB-DL.DDP5.1.H.265-NTb.mkv

-->

    /Videos/Good.Omens/Good.Omens.S02E01.The.Arrival.2160p.AMZN.WEB-DL.DDP5.1.HDR.H.265-NTb.mkv
    /Videos/Good.Omens/Good.Omens.S02E05.The.Ball.2160p.AMZN.WEB-DL.DDP5.1.H.265-NTb.mkv

USAGE:

    $SCRIPTNAME [-s <source-folder> -d <dest-folder> (-o <older-than> | -n <newer-than> )]

e.g

    $SCRIPTNAME -s /source/folder -d /dest/folder

OPTIONS:

-i | --source-folder (default: ~/Downloads)
        Source folder to recurse

-d | --dest-folder (default: ~/Videos)
        Dest folder to move files

-o | --older-than
        Match files older than (days)

-n | --newer-than
        Match files newer than (days)

-h | --help
        Show this message

AUTHOR:

Christopher James Ward (2021)
E: chris@krzwrd.net

******************************************************************
EOF
    exit 1
}

function is_installed {
    which $1 > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "\nERROR: Missing dependency in PATH - '$1'."
        echo -e "\nPlease install '$1' via package manager. i.e."
        echo -e "\n\tbrew install $1"
        echo -e "\n\tapt install $1"
        echo -e "\n\tdnf install $1"
        exit 10
    else
        return 0
    fi
}

if [ $# -ne 0 ]; then
    while [ ! -z "$1" ]; do
        case "$1" in
                -h|--help)
                show_usage
                ;;
                -s|--source-folder)
                shift
                OPTS_SOURCE="$1"
                ;;
                -d|--dest-folder)
                shift
                OPTS_DEST="$1"
                ;;
                -o|--older-than)
                shift
                OPTS_OLDER=$1
                ;;
                -n|--newer-than)
                shift
                OPTS_NEWER=$1
                ;;
                *)
            echo "Incorrect input provided"
            show_usage
        esac
        shift
    done
fi

if [ -n $OPTS_OLDER ] && [[ $OPTS_OLDER =~ ^-?[0-9]+$ ]]; then
    extra_args="-mtime +${OPTS_OLDER}d"
elif [ -n $OPTS_NEWER ] && [[ $OPTS_NEWER =~ ^-?[0-9]+$ ]]; then
    extra_args="-mtime -${OPTS_NEWER}d"
elif ([[ -n $OPTS_OLDER ]] && [[ -n $OPTS_NEWER ]]); then
    echo -e "ERROR: Cannot specify -n AND -o values. Choose one or the other."
    exit 1
fi

is_installed parallel
is_installed rsync

declare -a sources
declare -a folders

source_folder="${OPTS_SOURCE:-"$HOME/Downloads"}"
dest_folder="${OPTS_DEST:-"$HOME/Videos"}"

echo -e "\nOPTIONS:\n"
echo -e "\tSource Directory: ${source_folder}\n"
echo -e "\tDestination Directory: ${dest_folder}\n"
echo -e "\tExtra Find Args: ${extra_args}\n"

sources=( "$(find "$source_folder" -type f \( -name "*.mkv" -o -name "*.avi" -o -name "*.mp4" \) -not -name "*ample*" $extra_args)" )
folders=( "$(sed 's/\.S[0-9][0-9].*$//g' <<< "${sources[@]}" | xargs basename | sort | uniq)" )

while IFS= read -r folder; do
    dest_dir="${dest_folder}/${folder}"
    if [ ! -d "${dest_dir}" ]; then
       echo "Creating directory: ${dest_dir}"
       mkdir -p "${dest_dir}"
    fi
    echo -e "The following files will be transferred to ${dest_dir}:\n"
    grep "${folder}" <<< "${sources[@]}" | sed 's/^/\t/g'; echo -e "\n"

    grep "${folder}" <<< "${sources[@]}" | parallel -j 4 -k rsync --inplace -c -v -u {} "$dest_dir"
done <<< "${folders[@]}"

