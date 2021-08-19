# shellshite
Dumping ground for shell scripts

## Contents

**usburnbaby.sh**
Wrapper around DD for creating live USBs that I wrote so I didn't have to worry about looking up arguments like block size etc and has some basic validation around files, mount status, privilege etc. 

```
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
