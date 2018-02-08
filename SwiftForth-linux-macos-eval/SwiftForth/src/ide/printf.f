{ ====================================================================
Output string formatting ala printf

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

==================================================================== }

?( ... String formatting like printf)

{ --------------------------------------------------------------------
String output

The string is built at pad as a zero terminated string.

<% begins the output string and

%> ends it, returning the address and length of the string.

%s inserts a counted string.
%d inserts a decimal number.
%x inserts a hex number.

%s.r inserts a string justified right in a field, and
%s.l inserts a string justified left in a field.

%cr inserts a line-end.

So a string may be built like this:

<%  S" This is a test " %s  DPL @ %d  S"  finally" %s %cr %>
-------------------------------------------------------------------- }

?( ... Formatted text)

0 VALUE %BUF

:ONSYSLOAD ( -- )   4096 ALLOCATE THROW TO %BUF ;
:ONSYSEXIT ( -- )   %BUF FREE THROW 0 TO %BUF ;

: <% ( -- )   0 %BUF ! ;
: %> ( -- zstr )   %BUF ;

: %s ( a n -- )  %BUF ZAPPEND ;
: %z ( zstr -- )   ZCOUNT %s ;

: %cr ( -- )   <EOL> COUNT %s ;
: %sp ( -- )   S"  " %s ;

: %d ( n -- )   [OBJECTS I-TO-Z MAKES OBUF OBJECTS]   OBUF Z(.) %z ;
: %x ( n -- )   [OBJECTS I-TO-Z MAKES OBUF OBJECTS]   OBUF Z(H.) %z ;

: %spaces ( n -- )
   256 R-ALLOC >R  R@ 256 BLANK
   BEGIN
      DUP 256 > WHILE  R@ 256 %s  256 -
   REPEAT R> SWAP %s ;

: %s.r ( addr n width -- )
   2DUP < IF OVER - %spaces ELSE OVER SWAP - /STRING THEN %s ;

: %s.l ( addr n width -- )
   2DUP < IF OVER - -ROT %s %spaces ELSE NIP %s THEN ;
