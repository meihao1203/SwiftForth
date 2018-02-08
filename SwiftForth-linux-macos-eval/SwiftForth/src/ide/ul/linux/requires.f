{ ====================================================================
Library management tool

Copyright (C) 2008 FORTH, Inc.  All rights reserved

This file implements REQUIRES, a library-searching INCLUDE
alternative.
==================================================================== }

PACKAGE LIB-TOOLS

{ --------------------------------------------------------------------
REQUIRES acts like include, except that the entire LIB subdirectory
is recursively searched for the file if it doesn't exist in the
current directory.
-------------------------------------------------------------------- }

PRIVATE

: PATH-REQUIRES ( z-addr addr u -- z-addr false | true )
   R-BUF  +ROOT R@ ZPLACE  PUSHPATH  R> chdir
   0= IF  DUP IS-FILE IF  ZCOUNT ['] INCLUDED CATCH
   POPPATH THROW  -1  EXIT  THEN THEN  POPPATH  0 ;

: (REQUIRES) ( z-addr -- )
   S" SFLOCAL_USER" FIND-ENV IF  PATH-REQUIRES ?EXIT  ELSE  2DROP  THEN
   S" %SwiftForth/lib" PATH-REQUIRES ?EXIT
   S" %SwiftForth/lib/options" PATH-REQUIRES ?EXIT
   S" %SwiftForth/lib/options/linux" PATH-REQUIRES ?EXIT
   S" %SwiftForth/lib/samples" PATH-REQUIRES ?EXIT
   S" %SwiftForth/lib/samples/linux" PATH-REQUIRES ?EXIT
   ZCOUNT HERE PLACE  -38 THROW ;

PUBLIC

: REQUIRES ( -- )   R-BUF
   BL WORD COUNT DEFAULT.EXT  R@ ZPLACE
   R@ IS-FILE IF  R> ZCOUNT INCLUDED EXIT  THEN
   R> (REQUIRES) ;

END-PACKAGE
