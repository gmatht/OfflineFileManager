Offline File Manager v0.01
=======

Most file managers assume relevant files are presently accessible. This utility instead stores file info in `/var/lib/ofm`. This allows us to find files and generate stats on disconnected drives.

To install just add `ofm` to your path. E.g. link it to `/usr/bin/`.

Example of Use:

1. Attach some removable drives to your machine and run `ofm scan`
2. Repeat 1. as required
3. run `ofm p` to get an idea how much data you actually have
4. run `ofm p -g/Documents/` to see how many Documents you have
5. run `ofm grep -i /Documents/ | column -t` to list all Documents in pretty columns
6. run `ofm grep .vimrc` to look for your vimrc files
7. run `ofm sim` to see which drives have similar contents
8. run `ofm df` to see how much free space each device has
9. run `ofm fail foo bar` to see files lost if drives `foo` and `bar` fail

Please be patient. Queries on 10 million files take a couple of minutes to complete.

## Data Structures

`/var/lib/ofm/ID_SERIAL`: Directory containing information on disk with `ID_SERIAL` (as reported by udevadm)` 
This directory contains `smartctl.txt` and `udevadm.disk.txt`, which are raw output from the respective utilities.

`/var/lib/ofm/ID_SERIAL/N`: Directory containing information on Nth partition on disk
This directory contains three files `df.txt`, `du.gz` and `udevadm.part.txt`. A couple of lines in `du.gz` may look like:

    9999	1283157068	/media/path/to/file.pdf
    9999b2	1283157068      ./path/to/file.jpg
    
- `9999`:   File is 9999 bytes long
- `9999b2`: Sparse file is 9999 bytes long, but only uses 2 512 byte (b)locks.
- `1283157068`: A Unix Modification Time (in the year 2010)

## TODO

 - Investigate more efficient data-structures / cache structures
 - Support tagging sets of files
 - Support importing unique files from decommissioned drives
   -  Support importing files with only N backups
 - Support recording and operating on md5/sha256 sums etc.

## Background
I have many different disks (primarily harddisks) storing various files. I want to know that they are all backed up in some form. Given that I have terabytes of files somehow (backups of backups apparently) I don't want to just backup everything onto new media yet again.  I'd like a utility that allows me to copy all files on X that do not yet exist on Y to Y, that is also well suited to tasks such as:

1. To list all files on X that are not duplicated/backed up on other media
2. Deduplicate files on X
3. To list all files that are not duplicated onto offline or WORM storage
4. To list all files that are not duplicated onto offsite storage
5. Match JPGs by EXIF date.

Since the are many files it would be helpful to store computed hashes for re-use (Matching on filesize, modification time and path)
It would not be convenient to have multiple utilities unless they share the same hash file format.

## Current Utilities Here

These utilities are very restricted and experimental. 

[size_of_new_unique_files.pl](size_of_new_unique_files.pl): This file takes lists in `du -ab' file format and give a list of new files and the total amount of MB used by those new files.  

[mydeep.media](mydeep.media): This creates sha256sums lists for removable media and keeps records of smartctl information to help identify the media later. 

## Example Commands

`perl ~/prj/joshell/mass_file_management/parse_du.pl `find -L . | grep du.gz$` -f ./gmatht/LHAA1102241905581561/1/du.gz`

Find out what files would be lost if LHAA1102241905581561 failed

`find -L . | grep /udevadm.disk.txt | sed s,/udevadm.disk.txt,, | while read f; do [ -z "`find -L $f -name du.gz`" ] && echo $f; done`

find partitions that don't have du.gz's

## Other programs

### rsync
[Rsync](http://optics.ph.unimelb.edu.au/help/rsync/rsync.html) would be great if all my files shared the same directory structure. As they do not, it is far from a complete solution.

### du 
The [du](http://unixhelp.ed.ac.uk/CGI/man-cgi?du) command is quite handy. With the -ab option you get precise byte counts for each file, which can be quite handy for quickly guessing whether two files are duplicates.

### hashdeep
A handy set of commands for creating hashes of files. I find 
     sha256deep -reztcl
the most useful. [hashdeep](http://md5deep.sourceforge.net/) clearly isn't as fast as du, and unfortunately sha256deep normalises dates to GMT whereas du doesn't, making comparing timestamps less trivial.
Hashdeep doesn't have a inbuilt way of quickly recomputing hashes for changed files only, nor an option to restart interrupted runs.

### Various Deduplication Facilities 
Deduplication utilities often use both file sizes and hashes together, as I want. I find [bedup] (https://github.com/g2p/bedup/blob/master/README.rst) particularly interesting as it makes use of btrfs's handy deduplication facilities. One possible approach is just to copy everything onto a large btrfs drive and the deduplicate the files using bedup.

There are also many other deduplication utilities; e.g.
	[rdfind] (http://rdfind.pauldreik.se/) and
	[duff]   (http://duff.dreda.org/).

However they seem to be all limited in two ways:
1. they don't store hashes for later reuse, resulting in slow performance on huge volumes
2. it is hard to ask them to list the files that do *not* exist on my archive. 

### archivefs

Unlike the other utilities [archivefs](https://code.google.com/p/archivefs/) not only keeps a record of hashes, but also keep that record up-to-date. 

This is handy. It is designed primarily for deduplication rather than file management. It is not completely trivial to e.g. compare two archivefs filesystems.
