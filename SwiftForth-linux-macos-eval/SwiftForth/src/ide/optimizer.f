{ ====================================================================
Optimizing compiler extensions

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

The optimizer works by replacing the COMPILE, behavior with a new one
that looks for patterns to optimize before laying down the xt that
COMPILE, was given. The search is over a list of xts that have
optimizations -- ie the list of optimizations contains an entries for
OR, AND, XOR, and + .

This list is matched against for the xt that COMPILE, is supposed to
compile. If an xt is matched, then the xt's entry is searched for a
match to the xt in XTHIST.  No match here means no optimization and
therefore COMPILE, should just compile the xt given.

A match here is associated with an xt "replace action" -- the xt of a
routine to run that will optimize the last xt followed by the current
xt.  The optimizer first forgets the XTHIST code and then runs the
xtreplace routine.

Predefined words /OPT and [/OPT] clear XTHIST so as to break the
optimization behavior.
==================================================================== }

?( Optimizing compiler)

PACKAGE OPTIMIZING-COMPILER

{ --------------------------------------------------------------------

This is the data structure that the optimizer uses. It is presented
in this block comment so it is more readable in my editor, which
italicizes comments built with curly braces.

Each item in the lists is a triple: link, xtmatch, (list|xtrun)

optimizer @
          |
          |
          @-| xt0 | list |
          |           @------------------------------.
          |                                          |
          @-| xt0 | list |                           |
          |           @---------.                    @-| xt-1 | xt-r |
          |                     |                    |
          @-| xt0 | list |      |                    |
          |                     @-| xt-1 | xt-r |    @-| xt-1 | xt-r |
                                |                    |
                                |                    |
                                @-| xt-1 | xt-r |    @-| xt-1 | xt-r |
                                |                    |
                                |
                                @-| xt-1 | xt-r |
                                |

@ is a relative link
xt0 is the current xt being compiled
xt-1 is the last xt compiled
xt-r is what to do if you get a match on current and last
-------------------------------------------------------------------- }

{ --------------------------------------------------------------------
Error messages
-------------------------------------------------------------------- }

THROW#
   S" Can't uncompile." >THROW  ENUM OPT_UNCOMPILE
   S" Rulestack empty." >THROW  ENUM OPT_NORULE
   S" Bad rule"         >THROW  ENUM OPT_BADRULE
TO THROW#

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CREATE RULESTACK  8 CELLS  /ALLOT

: /RULES ( -- )
   RULESTACK 8 CELLS ERASE ;

: >RULE ( x -- )
   RULESTACK DUP CELL+ 7 CELLS CMOVE>   RULESTACK ! ;

\ 0 is always the current one

: RULE@ ( n -- x )
   7 AND CELLS RULESTACK + @ DUP ?EXIT  OPT_NORULE THROW ;

: RULEX ( n -- )
   RULE@ 3 CELLS + @ CATCH THROW ;

{ --------------------------------------------------------------------
XTHIST is the most recently compiled token
XTHIST1 is the one before XTHIST

/XTHIST wipes the history.

+XTHIST gets ready for a new entry, "pushing", and
-XTHIST discards the top, "popping"

RECORD compiles an xt via the old system word (COMPILE,), recording
   the values of the xt and here before and after compilation.
-------------------------------------------------------------------- }

4 CELLS CONSTANT |OPT|

CREATE XTHIST   3 |OPT| * /ALLOT

: XTHIST1 XTHIST |OPT| + ;
: XTHIST2 XTHIST1 |OPT| + ;

: /XTHIST ( -- )
   XTHIST 3 |OPT| * ERASE  /RULES ;

: -XTHIST ( -- )
   XTHIST1 XTHIST |OPT| CMOVE
   XTHIST2 XTHIST1 |OPT| CMOVE
   XTHIST2 |OPT| ERASE ;

: +XTHIST ( -- )
   XTHIST1 XTHIST2 |OPT| CMOVE
   XTHIST XTHIST1 |OPT| CMOVE ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

VARIABLE VIEW-OPT

: RECORD ( xt xt -- )   >R
   VIEW-OPT @ IF DUP >NAME .ID THEN
   +XTHIST  HERE OVER XTHIST 2!  R> EXECUTE  HERE XTHIST CELL+ CELL+ ! ;

{ --------------------------------------------------------------------
OPTIMIZING? is a global flag indicating whether or not to perform
optimization on each xt compiled.

+OPT turns on optimization and
-OPT turns it off.

OPTIMIZE, resolves COMPILE, to provide an optimizing compiler.
-------------------------------------------------------------------- }

VARIABLE OPTIMIZING?

PUBLIC

: +OPT   OPTIMIZING? ON ;       : +OPTIMIZER   +OPT ;
: -OPT   OPTIMIZING? OFF ;      : -OPTIMIZER   -OPT ;

PRIVATE

-OPT

{ --------------------------------------------------------------------
The optimizer is a list of lists.
each primary token gets its own list based on xt
so OPT: takes the tos and finds its list in the OPTIMIZER list

OPTIMIZER is the list of all optimizations

OPTIMIZED searches the highest level optimizer list for an xt.  Any
xt targeted for optimization will have an entry on this list and
an associated list of particular optimizations of its own.

-------------------------------------------------------------------- }

CREATE OPTIMIZER  0 ,

CODE OPTIMIZED ( xt -- addr | 0 )       \ : OPTIMIZED ( xt -- addr | 0 )
   ' OPTIMIZER >CODE CALL               \    OPTIMIZER BEGIN
   BEGIN                                \       @REL  DUP WHILE
      0 [EBX] EAX MOV                   \       DUP CELL+ @  THIRD =
      EAX EAX OR                        \    UNTIL
      0<> WHILE                         \       NIP CELL+ CELL+ EXIT
      EAX EBX ADD                       \    THEN 2DROP 0 ;
      4 [EBX] EAX MOV                   \
      0 [EBP] EAX CMP                   \
   0= UNTIL                             \
      4 # EBP ADD                       \
      8 # EBX ADD                       \
      RET                               \
   THEN                                 \
   4 # EBP ADD                          \
   0 # EBX MOV                          \
   RET END-CODE                         \

{ --------------------------------------------------------------------
UNCOMPILABLE is true if the last thing can still be uncompiled.

UNCOMPILE gets rid of the last compiled thing if it can; else throws.
-------------------------------------------------------------------- }

: ANY ;

: UNCOMPILABLE ( -- flag )
   XTHIST CELL+ CELL+ @ HERE = ;

: OPTIMIZABLE? ( optlink -- flag )
   CELL+ @  DUP ['] ANY =
   SWAP  XTHIST @ =  UNCOMPILABLE AND  OR ;

: UNCOMPILE ( -- )
   0 RULE@ CELL+ @ ['] ANY = ?EXIT
   UNCOMPILABLE NOT OPT_UNCOMPILE ?THROW
   XTHIST CELL+ @ H ! -XTHIST ;

{ --------------------------------------------------------------------
(OPTIMIZE,) traverses the list looking for a match to the xt on the
stack. If found, then the optimization list associated with the xt
is searched for a match to LASTOP. If found, the optimization rule
is executed. If no match, the system default compilation behavior is
executed to compile the xt normally.
Note the potential trap here for matches to PARENT: if the first
5 bytes of the xt you are attempting to optimize result in a
call operation, we think this is the parent we should optimize
this might should be taken out, but give it some thought first.
-------------------------------------------------------------------- }

: OPTIMIZATION ( chain -- optlink | 0 )
   BEGIN
      @LINK DUP WHILE
      DUP OPTIMIZABLE?
   UNTIL THEN ;

: IMPROVED ( xt -- optlink | 0 )
   DUP >R
   OPTIMIZED DUP IF
      VIEW-OPT @ IF R@ >NAME .ID THEN
      OPTIMIZATION
   THEN
   R> DROP ;

: IMPROVE ( optlink -- )
   BEGIN ( o)  DUP >RULE
      UNCOMPILE  CELL+ CELL+ @
      DUP IMPROVED DUP WHILE  NIP
   REPEAT DROP
   VIEW-OPT @ IF  ." ==> " THEN
   ['] EXECUTE RECORD ;

: DUMB, ( xt -- )
   ['] (COMPILE,) RECORD ;

2VARIABLE LASTCHILD

{ --------------------------------------------------------------------
SAFE-PARENT returns the given XT if it is in the list. Otherwise, it
discards the valid xt and replaces it with zero. This corrects the
old optimizer problem with ": test do i . loop ; : try 10 0 test ;"
-------------------------------------------------------------------- }

[SWITCH SAFE ZERO
   ' (VALUE)    RUN: ['] (VALUE)     ;
   ' (USER)     RUN: ['] (USER)      ;
   ' (CREATE)   RUN: ['] (CREATE)    ;
   ' (CONSTANT) RUN: ['] (CONSTANT)  ;
SWITCH]

PUBLIC

: OPTIMIZE, ( xt -- )
   OPTIMIZING? @ IF
      STATE @ IF
         VIEW-OPT @ IF CR THEN
         DUP >CODE C@ $E9 = IF ( vectored, substitute?)
            DUP ['] (ELSE) <> IF
               >CODE 1+ @+ + CODE>
            THEN
         THEN
         DUP IMPROVED ?DUP IF  NIP IMPROVE EXIT  THEN
         DUP PARENT SAFE IMPROVED ?DUP IF
            SWAP DUP 5 + SWAP LASTCHILD 2!  IMPROVE EXIT THEN
         DUMB, EXIT
      THEN
   THEN  DUMB, ;

PRIVATE

{ --------------------------------------------------------------------
OPTIMIZING either creates or extends an optimization list and returns
the address of the list head.

>OPTIMIZER builds an optimizer entry for the sequence XTLAST XTNOW .

OPTIMIZE parses two words and runs >OPTIMIZER. This makes a nice
syntax like:

        OPTIMIZE (LITERAL) <     WITH LIT-COMPARE   'A JGE ,
-------------------------------------------------------------------- }

: OPTIMIZING ( xt -- addr )
   DUP OPTIMIZED ?DUP IF NIP EXIT THEN
   OPTIMIZER >LINK ( xt) , HERE 0 , ;

: OPTIMIZE ( -- "last" "current" )
   ' ' OPTIMIZING  >LINK , 0 , ;

: ?RULE ( -- )
   HERE CELL- @ OPT_BADRULE ?THROW  -CELL ALLOT ;

: WITH ( -- )
   ?RULE  ' ,  0 , ;

: SUBSTITUTES ( -- )
   0 RULE@ 3 CELLS + @ ( xt)   DUP XTHIST !
   (COMPILE,) ;

: SUBSTITUTE
   ?RULE  ['] SUBSTITUTES , ' , ;


{ --------------------------------------------------------------------
'A and ['A] are shortcuts for searching the assembler vocabulary.
-------------------------------------------------------------------- }

: ASSEMBLE ( "name" -- )
   ?RULE  ASM-WORDLIST +ORDER  ['] ' CATCH  ASM-WORDLIST -ORDER  THROW , 0 , ;

PUBLIC

: /OPTIMIZER
   ['] OPTIMIZE, IS COMPILE,
   ['] /XTHIST IS /OPT
   +OPT ;

{ ----------------------------------------------------------------------
Selectively disable tail recursion in the optimizing compiler

NO-TAIL-RECURSION is used just like IMMEDIATE, and prevents tail
recursion in any definition that ends in a call to the last defined
word.

The actual rule compiled for the optimizing compiler is equivalent to:

OPTIMIZE ANY foo WITH foo WITH /OPT

The same effect could have been obtained via a rule that triggered on
"foo ;" instead of "ANY FOO" but this would require the optimizer to
evaluate the rule on every ";" to see if it was preceeded by the
reference to foo.

Simple example:

: EMBARK ( n n -- ) R> SWAP >R SWAP >R >R ; NO-TAIL-RECURSION
: DEBARK ( -- n n ) R> R> SWAP R> SWAP >R ; NO-TAIL-RECURSION

: TEST ( -- 3 4 )
   1 2 3 4 EMBARK DROP DROP DEBARK ;
---------------------------------------------------------------------- }

PRIVATE

: (NO-TAIL-RECURSION) ( -- )
   0 RULE@ 3 CELLS + @ (COMPILE,) /OPT ;

PUBLIC

: NO-TAIL-RECURSION ( -- )
   LAST CELL+ CELL+ @ CODE> ['] ANY OVER OPTIMIZING >LINK ,
   ['] (NO-TAIL-RECURSION) , , ;

END-PACKAGE

\\

{ --------------------------------------------------------------------
: .OPTXT ( link -- )
   BEGIN
      @REL ?DUP WHILE
      DUP CELL+ @ >CODE .'
   REPEAT ;

: .OPTIMIZER ( -- )
   OPTIMIZER BEGIN
      @REL ?DUP WHILE >R
      CR R@ CELL+ @+  >CODE .'  CR 3 SPACES  .OPTXT  R>
   REPEAT ;
-------------------------------------------------------------------- }

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

REQUIRES OBSERVING

: .HERE ( n -- )
   8 (H.0) %s %sp ;

: DICTIONARY? ( n -- flag )
   ORIGIN 5 +  OPERATOR H HIS @ WITHIN ;

: (.XT) ( n -- )
   DUP DICTIONARY? IF (.') COUNT EXIT THEN
   >CODE
   DUP DICTIONARY? IF (.') COUNT EXIT THEN
   DROP S" <no name> " ;

: .XT ( n -- )   (.XT) 20 %s.l ;

: (.HIST) ( addr -- addr n )
   <% @+ DUP .HERE .XT
      @+ .HERE
      @+ .HERE
      @+ DUP DICTIONARY? IF @ DUP .HERE .XT ELSE .HERE HERE 0 20 %s.l THEN
      DROP
   %> ZCOUNT ;

: (.RULESTACK) ( -- addr n )
   RULESTACK <% 8 0 DO
      @+ .HERE
   LOOP DROP %> ZCOUNT ;

[+SWITCH OBSERVE ( n -- addr n )
   0 RUN: XTHIST (.HIST) ;
   1 RUN: XTHIST1 (.HIST) ;
   2 RUN: XTHIST2 (.HIST) ;

   4 RUN: (.RULESTACK) ;

SWITCH]
