{ ====================================================================
Load file for debugging with GDB

Copyright (c) 2011-2017 Roelf Toxopeus

SwiftForth version.
Last: 21 April 2014 09:30:23 CEST  -rt
==================================================================== }

CR .( Loading GDB ...)

PUSHPATH
MAC

INCLUDE system/mach-task.f
INCLUDE system/applescript.f
INCLUDE system/GDB.f

POPPATH

GDB-HELP

cr .( ... starting new gdb session: sf stopped in gdb)
cr .( It reads the symbols for the shared libraries twice!)
cr .( The second read takes some time, don't worry...)

GDB

\\ ( eof )

Note: prior to Mavericks the GDB reads the symbols for the shared libraries twice.
You should see something like the following:

/Users/roelf/1738: No such file or directory
Attaching to process 1738.
Reading symbols for shared libraries . done
Reading symbols for shared libraries ............................................................................................................................................................................................................................ done
0x95f7b7d2 in mach_msg_trap ()
(gdb) 

In gdb 7.7 you'll see something like this:

Attaching to process 34564
[New Thread 0x1703 of process 34564]
[New Thread 0x1803 of process 34564]
[New Thread 0x1903 of process 34564]
[New Thread 0x1a03 of process 34564]
[New Thread 0x1b03 of process 34564]
[New Thread 0x1c03 of process 34564]
[New Thread 0x1d03 of process 34564]
[New Thread 0x1e03 of process 34564]
[New Thread 0x1f03 of process 34564]
[New Thread 0x2003 of process 34564]
Reading symbols from /Users/roelf/Applications/F O R T H/SwiftForth OSX/SwiftForth/bin/osx/coco-sf...(no debugging symbols found)...done.
0x95c5df7a in ?? ()
(gdb) tds
  Id   Target Id         Frame 
  11   Thread 0x2003 of process 34564 0x95c63046 in ?? ()
  10   Thread 0x1f03 of process 34564 0x95c63046 in ?? ()
  9    Thread 0x1e03 of process 34564 0x95c63046 in ?? ()
  8    Thread 0x1d03 of process 34564 0x95c5df7a in ?? ()
  7    Thread 0x1c03 of process 34564 0x95c629ee in ?? ()
  6    Thread 0x1b03 of process 34564 0x95c63046 in ?? ()
  5    Thread 0x1a03 of process 34564 0x95c63046 in ?? ()
  4    Thread 0x1903 of process 34564 0x95c63046 in ?? ()
  3    Thread 0x1803 of process 34564 0x95c63992 in ?? ()
  2    Thread 0x1703 of process 34564 0x95c63046 in ?? ()
* 1    Thread 0x1603 of process 34564 0x95c5df7a in ?? ()
(gdb) 
