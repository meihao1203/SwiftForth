{ ====================================================================
Launch Apple's LLDB

Copyright (c) 2013-2017 Roelf Toxopeus

SwiftForth version.
Last: 7 November 2013 10:33:21 CET    -rt
==================================================================== }

{ --------------------------------------------------------------------
Launching Apple's LLDB with SwiftForth attached
Using '3 INT' signal sigtrap instruction directly ensures we stop immediately
in the right calling thread!
Original in GDB.f
Gnu's GDB changed for Apple's LLDB.
Layout is very important for Applescript!

DB -- launch LLDB with me attached.
>DB -- jump into LLDB as a breakpoint.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ lacking system.framework  framework System.framework

\ system.framework

LACKING getpid  FUNCTION: getpid ( -- mypid )

: "debugme" ( -- pad )
<SCRIPT>
tell application "Terminal"
	activate
	do script with command "lldb -p  </SCRIPT>
ZCOUNT PAD ZPLACE	
getpid S>D <# #S #> PAD ZAPPEND
<SCRIPT> "
end tell </SCRIPT>
ZCOUNT PAD ZAPPEND PAD ;

\ Launch LLDB with me attached
: DB   "debugme" doscript ;

\ Jump into LLDB as a breakpoint
icode >DB
	3 int
	ret
end-code

: db-help
cr ."   sf:   db      -- start new lldb session: sf stopped in lldb"
cr ."   sf:   >db     -- break in to lldb if there and attached"
\ cr ."   gdb:  hi        -- see current and next 3 three instructions"
cr ."   lldb: c       -- continue (till breakpoint if any) eventually in to sf"
\ cr ."   gdb:  words     -- show simple macsbug like words"
cr ."   lldb: quit    -- quits lldb, sf continues if detached"
;

cr .( lldb stuff loaded)

\\ ( oef )