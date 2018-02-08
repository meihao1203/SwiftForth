{ ====================================================================
File include monitoring

Copyright (C) 2001 FORTH, Inc.  All rights reserved.

This file supplies a facility for monitoring INCLUDE.
==================================================================== }

{ ------------------------------------------------------------------------
Monitoring is controlled by a bit-mapped variable named MONITORS. The
bits are assigned the functions as:

  1 .....1 means display the stack on each line
  2 ....1. means display HERE on each line
  4 ...1.. means display the text of the line
  8 ..1... means execute the XT held in 'MONITOR
 16 .1.... means monitor the keyboard for the ESC key and terminate
                 if the user presses it. Any other key causes the
                 INCLUDE to be paused until a second key is pressed.

This utility may be used like this (in a file where there is a problem):

   VERBOSE  %101 MONITORS !     ( see text and stack)

   < troublesome code >

   SILENT

VERBOSE turns on monitoring and
SILENT turns monitoring off.

These words are not immediate.

The default mode for the system is SILENT.

HIGHLIGHTS sets the MSb of MONITORS; this forces the display of the
file in mode 00100 (4) to be written with the bright attribute.

HIGHLIGHTED is the same as verbose, but with highlights.
------------------------------------------------------------------------ }

PACKAGE FILE-TOOLS

THROW#
   S" Panic stop during include" >THROW ENUM IOR_PANIC
TO THROW#

2VARIABLE MONITORS   4 MONITORS !

: 'MONITOR ( -- addr )   MONITORS CELL+ ;

: ?PANIC ( -- )
   KEY? IF  KEY $1B = IOR_PANIC ?THROW  KEY $1B = IOR_PANIC ?THROW  THEN ;

: .INCLUDING ( a n -- )
   MONITORS @ 0< IF BRIGHT THEN
   CR #TIB 2@ TYPE SPACE
   MONITORS @ 0< IF NORMAL THEN ;

: SEE-INCLUDE ( -- )
   BASE @ >R  DECIMAL
   MONITORS @   1 AND IF .S THEN
   MONITORS @   2 AND IF CR HERE H. THEN
   MONITORS @   4 AND IF .INCLUDING THEN
   MONITORS @   8 AND IF 'MONITOR @EXECUTE THEN
   MONITORS @ $10 AND IF ?PANIC THEN
   R> BASE ! ;

[DEFINED] CONFIG: [IF]
CONFIG: MONITORS ( -- addr len )   MONITORS 2 CELLS ;
[THEN]

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

PUBLIC

: VERBOSE ( -- )   ['] SEE-INCLUDE IS MONITOR ;
: SILENT  ( -- )   ['] NOOP IS MONITOR ;

: HIGHLIGHTS    MONITORS @ $80000000 OR MONITORS ! ;
: HIGHLIGHTED   VERBOSE HIGHLIGHTS ;

:ONENVLOAD ( -- )    SILENT ;

END-PACKAGE
