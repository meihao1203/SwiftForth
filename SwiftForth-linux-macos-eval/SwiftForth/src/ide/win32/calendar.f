{ ====================================================================
Windows clock and calendar access

Copyright 2001  FORTH, Inc.

Windows keeps its system time in UTC. We use the GetLocalTime API to
read the time and date in the current timezone.
==================================================================== }

?( Windows clock and calendar access)

{ --------------------------------------------------------------------
Date/time access

Windows gets and sets time of day and date using the SYSTEMTIME structure.
TIME&DATE returns the time and date from a single call to GetLocalTime.
(@DATE) and (@TIME) return date and time, respectively.
-------------------------------------------------------------------- }

CLASS SYSTEMTIME

   HVARIABLE YEAR
   HVARIABLE MONTH
   HVARIABLE DOW        \ Day of week
   HVARIABLE DAY
   HVARIABLE HOUR
   HVARIABLE MINUTE
   HVARIABLE SECOND
   HVARIABLE MILLISECONDS

: GET-TIME ( -- )
   ADDR GetLocalTime DROP ;

END-CLASS

: TIME&DATE ( -- sec min hour day month year )
   [OBJECTS SYSTEMTIME MAKES LT OBJECTS]  LT GET-TIME
   LT SECOND W@  LT MINUTE W@  LT HOUR W@
   LT DAY W@  LT MONTH W@  LT YEAR W@ ;

: (@date) ( -- day month year )
   [OBJECTS SYSTEMTIME MAKES LT OBJECTS]  LT GET-TIME
   LT DAY W@  LT MONTH W@  LT YEAR W@ ;

: (@time) ( -- sec min hour )
   [OBJECTS SYSTEMTIME MAKES LT OBJECTS]  LT GET-TIME
   LT SECOND W@  LT MINUTE W@  LT HOUR W@ ;

{ =====================================================================
Calendar

Copyright (c) 1972-1998, FORTH, Inc.

This calendar represents the date as the number of days since 01/01/1900,
or "modified Julian date" (MJD).

Requires: @NOW

Exports: D/M/Y  M/D/Y  (DATE)  .DATE  @DATE  DATE  NOW
===================================================================== }

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

: D-M-Y ( day month year -- u)   >R  @MTH
   58 OVER < IF  R@ 3 AND 0= - THEN + 1-
   R> 1900 -  D/Y UM*  4 UM/MOD SWAP 0<> - + ;

: M/D/Y ( ud -- u)   10000 UM/MOD  100 /MOD  ROT D-M-Y ;

: Y-DD ( u1 -- y u2 u3)   4 UM* D/Y  UM/MOD 1900 +  SWAP 4 /MOD 1+
   DUP ROT 0= IF  DUP 60 > +  SWAP DUP 59 > +  THEN ;

: DM ( u1 u2 -- d m)   1 BEGIN  1+  2DUP @MTH > NOT UNTIL  1-
   SWAP DROP SWAP  OVER @MTH - SWAP ;

{ ---------------------------------------------------------------------
Date display

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
User API for time and date

@DATE returns the modified Julian date as the number of days since 01/01/1900.

@TIME returns the time as the number of seconds since midnight. This
is a double number for source compatibility with 16-bit systems.

@NOW returns time and date from a single call to GetLocalTime.
-------------------------------------------------------------------- }

: @DATE ( -- n )   (@date) D-M-Y ;
: @TIME ( -- ud )   (@time) 60 * + 60 * + 0 ;

: @NOW ( -- ud n )   TIME&DATE  D-M-Y >R
   60 * + 60 * + 0  R> ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: :00 ( ud1 -- ud2)   DECIMAL  #  6 BASE !  # [CHAR] : HOLD ;

: (TIME) ( ud -- c-addr u)   BASE @ >R  <#  :00 :00
   DECIMAL # #  #>  R> BASE ! ;

: .TIME ( ud -- )   (TIME) TYPE SPACE ;

: TIME ( -- )   @TIME .TIME ;

: DATE ( -- )   @DATE .DATE ;

{ --------------------------------------------------------------------
Vectors for various date format routines
-------------------------------------------------------------------- }

: (WINDATE) ( method n -- addr n )
   R-BUF  R@ 16 ERASE
   DUP  Y-DD DM ( y d m)  R@ 2+ W!  R@ 6 + W!  R@ W!
   7 MOD R@ 4 + W!
      LOCALE_SYSTEM_DEFAULT
      SWAP
      R>
      0
      PAD
      256
   GetDateFormat IF PAD ZCOUNT ELSE PAD 0 THEN ;

: (WINLONGDATE)  ( n -- addr n )   DATE_LONGDATE  SWAP (WINDATE) ;
: (WINSHORTDATE) ( n -- addr n )   DATE_SHORTDATE SWAP (WINDATE) ;

\ ' (WINLONGDATE) IS (DATE)
\ ' (WINSHORTDATE) IS (DATE)
