{ ====================================================================
Linux calendar access

Copyright (C) 2008 FORTH, Inc.  All rights reserved.
==================================================================== }

?( Clock/calendar access)

{ ---------------------------------------------------------------------
Modified Julian Date

D/Y is the number of days per year for a four-year period.

DAYS is the lookup table of total days in the year at the start of
each month.  @MTH  returns the value from days for the given month.

D-M-Y converts day, month, year into MJD.
M/D/Y takes a double number mm/dd/yyyy and converts it to MJD.
Y-DD and DM split the serial number back into its components.
--------------------------------------------------------------------- }

365 4 * 1+ CONSTANT D/Y

CREATE DAYS   -1 ,  0 ,  31 ,  59 ,  90 ,  120 ,  151 ,
   181 ,  212 ,  243 ,  273 ,  304 ,  334 ,  367 ,

: @MTH ( u1 -- u2)   CELLS DAYS + @ ;

: D-M-Y ( d m y -- u)   >R  @MTH
   58 OVER < IF  R@ 3 AND 0= - THEN + 1-
   R> 1900 -  D/Y UM*  4 UM/MOD SWAP 0<> - + ;

: M/D/Y ( ud -- u)   10000 UM/MOD  100 /MOD  ROT D-M-Y ;

: Y-DD ( u1 -- y u2 u3)   4 UM* D/Y  UM/MOD 1900 +  SWAP 4 /MOD 1+
   DUP ROT 0= IF  DUP 60 > +  SWAP DUP 59 > +  THEN ;

: DM ( u1 u2 -- d m)   1 BEGIN  1+  2DUP @MTH > NOT UNTIL  1-
   SWAP DROP SWAP  OVER @MTH - SWAP ;

{ ---------------------------------------------------------------------
Date display and setting

(MM/DD/YYYY) formats the system date (u1) as a string with the format
mm/dd/yyyy and is the default for (DATE) output.

(DD-MMM-YYYY) formats the date as "dd-MMM-yyyy" where MMM is a
3-letter month abbreviation.

.DATE displays the system date (u) as mm/dd/yyyy.
DATE gets the current system date and displays it.
--------------------------------------------------------------------- }

: (MM/DD/YYYY) ( u1 -- c-addr u2)   BASE @ >R  DECIMAL  Y-DD
   ROT 0 <#  # # # #  2DROP  [CHAR] / HOLD  DM SWAP
   0 # #  2DROP   [CHAR] / HOLD  0 # #  #>  R> BASE ! ;

: (DD-MMM-YYYY) ( u1 -- c-addr u2)   BASE @ >R  DECIMAL  Y-DD
   ROT 0 <#  # # # #  2DROP  [CHAR] - HOLD  DM 3 *
   C" JanFebMarAprMayJunJulAugSepOctNovDec" +
   3 0 DO  DUP C@ HOLD 1-  LOOP DROP  [CHAR] - HOLD
   0 # #  #>  R> BASE ! ;

DEFER (DATE)   ' (MM/DD/YYYY) IS (DATE)

: .DATE ( u -- )   (DATE) TYPE SPACE ;

{ --------------------------------------------------------------------
Date/time API

0DAY is the MJD (see below) for the start of Linux time.

@NOW returns time of day in seconds since midnight and modified Julian
date (MJD) in days since 01/01/1900.
-------------------------------------------------------------------- }

01/01/1970 M/D/Y CONSTANT 0DAY

: @NOW ( -- ud u )  GET-TIME NIP  86400 /MOD 0 SWAP 0DAY + ;
: @DATE ( -- n )   GET-TIME NIP 86400 / 0DAY + ;
: @TIME ( -- ud )  GET-TIME NIP 86400 MOD 0 ;

: TIME&DATE ( -- sec min hour day month year )
   @NOW >R  60 UM/MOD 60 /MOD  R> Y-DD DM ROT ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: :00 ( ud1 -- ud2)   DECIMAL  #  6 BASE !  # [CHAR] : HOLD ;

: (TIME) ( ud -- c-addr u)   BASE @ >R  <#  :00 :00
   DECIMAL # #  #>  R> BASE ! ;

: .TIME ( ud -- )   (TIME) TYPE SPACE ;

: TIME ( -- )   @TIME .TIME ;

: DATE ( -- )   @DATE .DATE ;
