{ ====================================================================
Enumerate system date formats

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

OPTIONAL ENUMDATE Enumerate system date formats

LIBRARY KERNEL32

FUNCTION: EnumDateFormats ( lpDateFmtEnumProc Locale dwFlags -- b )

: SHOWDATE ( -- res )
   OPERATOR'S
      CR  HWND ZCOUNT TYPE
      LOCALE_SYSTEM_DEFAULT
      0
      0
      HWND
      PAD
      255
   GetDateFormat IF
      GET-XY NIP 24 SWAP AT-XY PAD ZCOUNT TYPE
   THEN 1 ;

' SHOWDATE 1 CB: &SHOWDATES


: DASHES ( -- )
   CR ." --------------------------------------" ;

: (.DATES) ( a n -- )
   CR DASHES CR 2DUP TYPE DASHES
   EVALUATE &SHOWDATES -ROT EnumDateFormats DROP ;


: .DATES ( -- )
   S" LOCALE_SYSTEM_DEFAULT  DATE_LONGDATE  " (.DATES)
   S" LOCALE_SYSTEM_DEFAULT  DATE_SHORTDATE " (.DATES)
   S" LOCALE_USER_DEFAULT    DATE_LONGDATE  " (.DATES)
   S" LOCALE_USER_DEFAULT    DATE_SHORTDATE " (.DATES) ;

CR
CR .( Type .DATES to enumerate the known system date formats)
CR
