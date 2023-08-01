# shellshite
Dumping ground for shell scripts

## Contents

**usburnbaby.sh**
Wrapper around DD for creating live USBs that I wrote so I didn't have to worry about looking up arguments like block size etc and has some basic validation around files, mount status, privilege etc. 

```bash
$ ./usburnbaby.sh -h

******************************************************************
usburnbaby.sh - A wrapper around dd for live usb creation
******************************************************************

DESCRIPTION:

Completely overkill and started as a means of avoiding remembering
a bunch of options required for dd to burn a live USB and then my inner dev 
took control completely ignoring my inner sysad taking what was meant to be
a basic function in my bash profile to this and here we have it...

USAGE:

usburnbaby.sh -i <input image file> -o <output volume>

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

```

**groupandsyncshows.sh**
RSync TV Shows Downloaded Individually into Grouped Folders

```bash
$ ./groupandsyncshows.sh -h

******************************************************************
groupandsyncshows.sh - Transfer and Group TV Shows by Folder
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

    groupandsyncshows.sh [-s <source-folder> -d <dest-folder> (-o <older-than> | -n <newer-than> )]

e.g

    groupandsyncshows.sh -s /source/folder -d /dest/folder

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

Christopher James Ward (2023)
E: chris@krzwrd.net

******************************************************************

```
