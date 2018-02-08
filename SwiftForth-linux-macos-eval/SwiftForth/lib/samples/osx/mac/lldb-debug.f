{ ====================================================================
Load file for debugging with LLDB

Copyright (c) 2013-2017 Roelf Toxopeus

SwiftForth version.
Last: 16 Nov 2015 12:31:19 CET  -rt
==================================================================== }

CR .( Loading LLDB ...)

PUSHPATH
MAC

INCLUDE system/mach-task.f
INCLUDE system/applescript.f
INCLUDE system/LLDB.f

POPPATH

DB-HELP

cr
cr .( ... starting new lldb session: sf stopped in lldb)
cr .( the first time, you'll be asked to allow lldb to take over control.)
cr .( after allowing this, wait till you see the lldb prompt,)
cr .( the first time, it takes a while...)

DB

\\ ( eof )

Note: you should see something like the following:

Last login: Thu Nov  7 10:37:45 on ttys000
rt2:~ roelf$ lldb -p  1961
Attaching to process with:
    process attach -p 1961
Process 1961 stopped
Executable module set to "/Users/roelf/Applications/F O R T H/SwiftForth OSX/SwiftForth/bin/osx/coco-sf".
Architecture set to: i486-apple-macosx.

Continue in LLDB:
(lldb) c
Process 1961 resuming

Break in coco-sf with >DB:
Process 1961 stopped
* thread #4: tid = 0x19e2c, 0x0004a270 coco-sf, name = 'impostor, stop reason = EXC_BREAKPOINT (code=EXC_I386_BPT, subcode=0x0)
    frame #0: 0x0004a270 coco-sf
-> 0x4a270:  ret    
   0x4a271:  orb    %ah, 100(%edi)
   0x4a274:  bound  1886152040, %ebp
   0x4a27a:  addb   %ch, (%ecx)
(lldb) 





























