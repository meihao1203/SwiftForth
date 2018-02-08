{ ====================================================================
User debug messages in a DOS box

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL CONSOLEBUG Debug messages written to a DOS box; works even in callbacks!

REQUIRES DOSBOX

PACKAGE CONSOLE-DEBUG

DOS-BOX +ORDER

{ --------------------------------------------------------------------
BUGSEQ has how many times the debug sequence has been run.

/BUG opens the personality, creating the window if necessary and
BUG/ closes the personality. Use these in pairs.

[BUG begins a compiled bug phrase and
BUG] ends it.  Use these in pairs.

The use of [BUG and BUG] is intended to be a stack-neutral compiled
phrase for producing debug output during program execution. Whether
the phrase is run or not is controlled by the system value BUGME.
-------------------------------------------------------------------- }

VARIABLE BUGSEQ

: /BUG ( -- )    BUGSEQ ++  DOS-CONSOLE OPEN-PERSONALITY ;

: BUG/ ( -- )   CLOSE-PERSONALITY ;

PUBLIC

-? : [BUG ( -- )
   POSTPONE BUGME POSTPONE IF
      POSTPONE /BUG ; IMMEDIATE

-? : BUG] ( -- )
      POSTPONE BUG/  POSTPONE THEN ; IMMEDIATE

PRIVATE

{ --------------------------------------------------------------------
Output debug stuff

BUG.H displays a single number in hex
-------------------------------------------------------------------- }

: (.S) ( -- addr len )
   <%
      DEPTH 0 ?DO
         I PICK %d  S"  " %s
      LOOP S"  - " %s
   %> ZCOUNT ;

: BUG.S ( -- )
   (.S)  40 OVER -  DUP 0< IF ABS /STRING ELSE SPACES THEN TYPE ;

PUBLIC

: [@] ( ... n -- ... )
   [BUG CR BUG.S BUGSEQ ? BUG] DROP ;

: BUG.H ( n -- )   <% %x S"  " %s %> ZCOUNT TYPE ;

PRIVATE

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

PUBLIC

0 VALUE :BUG              \ non-zero means compile colon references

PRIVATE

: COLON-BUG ( -- )   BUGME -EXIT  R@ /BUG >R
   CR BUG.S
   R0 @ RP@ - CELL/ 3 - 0 MAX 3 .R SPACE
   R> BODY> >NAME COUNT TYPE
   BUG/ ;

PUBLIC

-? : :
   : :BUG IF  POSTPONE COLON-BUG  THEN ;

PRIVATE

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

PUBLIC

0 VALUE XTBUG

PRIVATE

0 VALUE RZERO

: /R0   0 TO RZERO ;

: NORMALIZE
   RZERO ?EXIT  RP@ TO RZERO ;

: NICE ( n -- flag )
   ORIGIN HERE WITHIN ;

: .INLINE ( addr xt -- )
   /BUG CR
   2>R BUG.S 2R>  SWAP
   NORMALIZE
   RZERO RP@ - CELL/
   DUP -10 20 WITHIN IF 3 .R SPACE ELSE DROP ."  () " THEN
   BUG.H  >NAME COUNT TYPE
   70 C# @ - SPACES
   7 4 DO
      I CELLS RP@ + @ DUP NICE IF .' ELSE H. THEN
   LOOP
   BUG/ ;

: INLINE-BUG ( -- )
   R> @+ OVER >R  BUGME IF .INLINE EXIT THEN 2DROP ;

: XTBUG, ( xt -- )
   XTBUG IF
      STATE @ IF
         ['] INLINE-BUG (COMPILE,)  DUP ,
      THEN
   THEN  (COMPILE,) ;

' XTBUG, IS COMPILE,

DECOMPILER +ORDER

: .BUGIN  >IP @ @+ >CODE ."   ==> " .' >IP ! ;

DECODE: INLINE-BUG .BUGIN

DECOMPILER -ORDER

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

PUBLIC

: BUG-HELP
   CR ." Console debug functions"
   CR ." (c) 1998 FORTH, Inc."
   CR
   CR ." [BUG begins a debug phrase and"
   CR ." BUG] ends the phrase.  "
   CR
   CR ." Typical use is:"
   CR
   CR ."    : FOO"
   CR ."       ( ... ) "
   CR ."       [BUG HERE 100 DUMP BUG] "
   CR ."       ( ... ) ;"
   CR
   CR ." The debugger is controlled by the value BUGME. No debug behavior"
   CR ." is executed if BUGME is zero."
   CR ;

DOS-BOX -ORDER  END-PACKAGE

{ --------------------------------------------------------------------
Testing
-------------------------------------------------------------------- }

EXISTS RELEASE-TESTING [IF] VERBOSE

1 TO BUGME

\ first, we compile a simple debug display. dump memory.
: MORE    [BUG HERE 100 DUMP KEY DROP BUG] ;

MORE

\ now, turn on xt tracing and compile some more stuff

1 TO XTBUG

88 VALUE FOO

: XYZ   7 TO FOO ;

: TEST ( n -- )   DROP 5 [@] ;
: TRY 10 0 DO I TEST LOOP ;

\ now run the new stuff and watch the debug window...
TRY

KEY DROP BYE [THEN]

BUG-HELP

{ --------------------------------------------------------------------
What you type is

   [BUG HERE 100 DUMP KEY DROP BUG]

What is compiled is

   BUGME IF
      /BUG
      HERE 100 DUMP KEY DROP EXIT
      BUG/
   THEN

-------------------------------------------------------------------- }
