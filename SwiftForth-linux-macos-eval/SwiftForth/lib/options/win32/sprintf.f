{ ====================================================================
Formatted output

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL SPRINTF Formatted output, ala "C"

{ --------------------------------------------------------------------
%
-               left alignment
digitstr        min field width, wider if necessary, pad with blanks
                unless the field is defined with leading zero
period          separator
digitstr        max chars to print
convchar        d decimal
                o octal
                x unsigned hex
                b unsigned binary
                u unsigned decimal
                c single char
                s string ( addr len)
                z string ( zaddr)

min is how wide to display, max is how many chars from the source
-------------------------------------------------------------------- }

CLASS FORMATTING

   4096 BUFFER: BUF
      0 BUFFER: TOP

   VARIABLE PX

   : /PX ( -- )   TOP PX ! ;

   : PX/ ( -- addr len )   PX @ TOP OVER - ;

   : HELD ( addr len -- )
      PX @ BUF - 0 MAX MIN
      DUP NEGATE PX +!  PX @ SWAP CMOVE ;

   : HELDC ( char -- )   SP@ 1 HELD  DROP ;

   : PADDING ( n char -- )
      SWAP 0 MAX 0 ?DO DUP HELDC LOOP DROP ;

{ --------------------------------------------------------------------
Parse the conversion string.
-------------------------------------------------------------------- }

   : ALIGNMENT ( addr len -- addr len align )
      OVER C@ [CHAR] - = DUP -EXIT DROP  1 /STRING -1 ;

   : DOT ( addr len -- addr len )
      OVER C@ [CHAR] . = IF 1 /STRING THEN ;

   DEFER: CONVCHARS ( -- addr len )   S" doxbucszDOXBUCSZ" ;

   : CONVCHAR ( addr len -- addr len char )
      OVER 1  CONVCHARS 2SWAP SEARCH NIP NIP IF  GETCH
      ELSE [CHAR] d THEN ;

   : MINFIELD ( addr len -- addr len n )
      0 0 2SWAP >NUMBER 2SWAP DROP ;

   : MAXFIELD ( addr len -- addr len n )
      MINFIELD ?DUP ?EXIT 255 ;

   : SPACING ( addr len -- addr len char )
      OVER C@ [CHAR] 0 = IF  GETCH ELSE BL THEN ;

   : PARSED ( addr len -- align spacing minwidth maxwidth cnvchar addr len )
      1 /STRING  ALIGNMENT -ROT SPACING -ROT
      MINFIELD -ROT  DOT  MAXFIELD -ROT  CONVCHAR -ROT ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

   : %FMT ( addr len -- rest len fmt len )
      2DUP  PARSED  2NIP 2NIP ROT DROP  0 MAX  2SWAP THIRD -  0 MAX ;

   : %TOKEN ( addr len -- before len after len fmt len )
      0 MAX  S" %" SPLITSTR 2SWAP  %FMT ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

   : %STRING ( addr len align spacing minwidth maxwidth -- )
      LOCALS| maxw minw spacech left len addr |
      addr len maxw MIN  minw OVER - 0 MAX  0
      left IF ( left)  SWAP  THEN   spacech PADDING >R
      HELD R> spacech PADDING ;

   : %ZSTRING ( zaddr align spacing minwidth maxwidth -- )
      2>R 2>R ZCOUNT 2R> 2R> %STRING ;

   : %CHAR ( char align spacing minwidth maxwidth -- )
      2>R 2>R SP@ 1 2R> 2R> %STRING DROP ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

   : %D. ( n align spacing minwidth maxwidth signed -- )
      IF 2>R 2>R S>D  ELSE 2>R 2>R 0 THEN  (D.) 2R> 2R> %STRING ;

   : %DECIMAL ( n align spacing minwidth maxwidth -- )
      DECIMAL 1 %D. ;

   : %OCTAL ( n align spacing minwidth maxwidth -- )
      OCTAL 0 %D. ;

   : %HEX ( u align spacing minwidth maxwidth -- )
      HEX  0 %D. ;

   : %UDECIMAL ( u align spacing minwidth maxwidth -- )
      DECIMAL 0 %D. ;

   : %BINARY ( u align spacing minwidth maxwidth -- )
      BINARY 0 %D. ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

   : NOFMT ( align spacing minwidth maxwidth cnvchar -- )
      2DROP 2DROP DROP ( and hope for the best) ;

   DEFER: %USERFMT ( ... align spacing minwidth maxwidth cnvchar -- )
      NOFMT ;

   : %FORMAT ( ... align spacing minwidth maxwidth cnvchar -- )
      BASE @ >R UPPER CASE
         [CHAR] O OF ( octal int)     %OCTAL    ENDOF
         [CHAR] X OF ( hex uint)      %HEX      ENDOF
         [CHAR] B OF ( binary uint)   %BINARY   ENDOF
         [CHAR] U OF ( decimal uint)  %UDECIMAL ENDOF
         [CHAR] C OF ( single char)   %CHAR     ENDOF
         [CHAR] S OF ( addr len)      %STRING   ENDOF
         [CHAR] Z OF ( zaddr)         %ZSTRING  ENDOF
         [CHAR] D OF ( decimal int)   %DECIMAL  ENDOF
                     ( unknown)       %USERFMT  0
      ENDCASE R> BASE ! ;

{ --------------------------------------------------------------------
`#PRINTF` assumes that the output buffer has been preped; then
recursively evaluates the given string for percent-tokens. This is
parsed left-to-right, then as the recursion unravels, the first item
resolved will be the last found and the stack usage will be nicer.
-------------------------------------------------------------------- }

   : #PRINTF ( addr len -- addr len )
      %TOKEN DUP IF
         2ROT 2>R 2>R RECURSE 2DROP  2R>  PARSED 2DROP %FORMAT 2R> HELD  0 0
      ELSE 2DROP 2SWAP  HELD  THEN ;

   : FORMAT ( ... addr len -- addr len )
      /PX #PRINTF 2DROP PX/ ;

END-CLASS

{ --------------------------------------------------------------------
`SPRINTF` is the lowest level interface to the package. Give it
the proper number of parameters on the stack and a specifier string
and it will produce a string of formatted output.

`PRINTF` formats and `TYPE` -s the string.
-------------------------------------------------------------------- }

: SPRINTF ( ... addr len -- addr len )
   [OBJECTS FORMATTING MAKES FMT OBJECTS]
   FMT FORMAT TUCK PAD ZPLACE  PAD SWAP ;

: ZPRINTF ( ... addr len -- zaddr )   SPRINTF DROP ;

: PRINTF ( ... addr len -- )   SPRINTF TYPE ;



\\

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

12345678 constant bar
: foo s" 12345678901234" ;


cr

bar    S" %6.3d"     cr printf
bar    S" %3.6d"     cr printf
bar    S" %-6.3d"    cr printf
bar    S" %-3.6d"    cr printf

bar    S" %06.3d"    cr printf
bar    S" %03.6d"    cr printf
bar    S" %-06.3d"   cr printf
bar    S" %-03.6d"   cr printf

foo    S" %6.3s"     cr printf
foo    S" %3.6s"     cr printf
foo    S" %-6.3s"    cr printf
foo    S" %-3.6s"    cr printf

foo    S" %06.3s"    cr printf
foo    S" %03.6s"    cr printf
foo    S" %-06.3s"   cr printf
foo    S" %-03.6s"   cr printf

cr cr

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

: helo s" hello, world" ;

helo s" :%10s:" cr printf
helo s" :%-10s:" cr printf
helo s" :%20s:" cr printf
helo s" :%-20s:" cr printf
helo s" :%20.10s:" cr printf
helo s" :%-20.10s:" cr printf
helo s" :%.10s:" cr printf
