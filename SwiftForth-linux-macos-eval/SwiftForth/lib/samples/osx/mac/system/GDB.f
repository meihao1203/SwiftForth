{ ====================================================================
Launch GDB

Copyright (c) 2003-2017 Roelf Toxopeus

SwiftForth version.
Last: 8 February 2011 10:00:48 CET    -rt
==================================================================== }

{ --------------------------------------------------------------------
Launching GDB with SwiftForth attached
Using '3 INT' signal sigtrap instruction directly ensures we stop immediately
in the right calling thread!
Original from CarbonMacForth, this version much simplified!
Layout is very important for Applescript!

GDB -- launch GDB with me attached.
>GDB -- jump into GDB as a breakpoint.
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
	do script with command "gdb -pid  </SCRIPT>
ZCOUNT PAD ZPLACE	
getpid S>D <# #S #> PAD ZAPPEND
<SCRIPT> "
end tell </SCRIPT>
ZCOUNT PAD ZAPPEND PAD ;

: GDB ( -- )   "debugme" DOSCRIPT ;

ICODE >GDB
	3 INT
	RET
END-CODE

: GDB-HELP
CR ."   sf:   gdb         -- start new gdb session: sf stopped in gdb"
CR ."   sf:   >gdb        -- break in to gdb if there and attached"
CR ."   gdb:  hi          -- see current and next 3 three instructions"
CR ."   gdb:  c  or  g    -- continue (till breakpoint if any) eventually in to sf"
CR ."   gdb:  words       -- show simple macsbug like words"
CR ."   gdb:  bye         -- quits gdb, sf continues detached"
;

cr .( gdb stuff loaded)

\\ ( oef )