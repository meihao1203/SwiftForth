{ ====================================================================
Common system extensions

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

?( Preamble -- miscellaneous tools added to SwiftForth)

{ ------------------------------------------------------------------------
execution chains

build a structure that looks like

   |link|xt|

   chain foo

   ' XYZ foo >chain

   foo runchain

All the chain functions will execute, the function closest to the chain
definition (ie the first defined) will execute last and is expected to
clean up the stack or whatever. If one of the routines touches the
stack, all other routines will inherit the mess made.

CALLS  runs down a linked list, executing the high level code
   that follows each entry in the list.

calls and runchain differ in that runchain is a list of xts and
calls is a list of executable definitions
------------------------------------------------------------------------ }

?( ... Chains)

THROW#
   S" Call chain error" >THROW ENUM IOR_CALLCHAIN
TO THROW#

: >CHAIN ( xt addr -- )   >LINK , ;
: <CHAIN ( xt addr -- )   <LINK , ;

: RUNCHAIN ( i*x a -- j*x )
   BEGIN
      @REL ?DUP WHILE
      DUP>R  CELL+ @EXECUTE  R>
   REPEAT ;

: CALLS ( a -- )
   BEGIN
      @REL ?DUP WHILE
      DUP>R  CELL+ ['] CALL CATCH  IOR_CALLCHAIN ?THROW   R>
   REPEAT ;

{ --------------------------------------------------------------------
Undefined token behavior is defined here

The interpret and compile loops try to find the token in the
search order, then try to convert it to a number. If both of these
defaults fail, we run the UNDEFINED chain.
-------------------------------------------------------------------- }

?( ... Undefined word behavior)

CHAIN UNDEFINED         \ each: ( c-addr len false -- true | c-addr len false )

: UNKNOWN-TOKEN ( c-addr len -- )
   0 UNDEFINED RUNCHAIN ?EXIT WHAT ;

' UNKNOWN-TOKEN IS NOT-DEFINED

{ --------------------------------------------------------------------
Extensible number conversion for the compiler and interpreter

The compiler/interpreter calls the deferred word IS-NUMBER? to
attempt number conversion.  Here we define an execution chain
of number conversion routines in order to make the 'definition'
of a number extensible.

The mechanism of the chain is that each member is called, even
after the string has been resolved; the flag that each is passed
indicates whether the member should attempt to resolve or simply
pass on the already resolved value.

So, each member is passed "addr len 0" until the string is
resolved, then each member is passed "... xt" which it is not
allowed to alter.  If a member does not resolve the string,
it should return the string and zero: "addr len 0".  If it
did resolve the string, it should return the result of the
conversion in the nominal expected place for that type of
data, and the non-zero xt of a routine which will compile the
data if executed.

Resolving members are added to the front of the chain via >CHAIN,
and to the end via <CHAIN .  Recommended that new converters be
placed at the end, not the beginning.

The code on which this is used is defined in INTERP.F .  Locate
the word IS-NUMBER? to see it.
-------------------------------------------------------------------- }

CHAIN NUMBER-CONVERSION

\ each: ( addr len zero -- ... xt | addr len 0 )
\   or: ( ... xt -- ... xt )

' INTEGER? NUMBER-CONVERSION <CHAIN

:NONAME ( addr len 0 -- ... xt | addr len 0 )
   NUMBER-CONVERSION RUNCHAIN ;  IS IS-NUMBER?

: NUMBER ( addr len -- n | d )
   0 IS-NUMBER? 0= ABORT" not a number" ;

{ --------------------------------------------------------------------
Forth-2012 character literals
-------------------------------------------------------------------- }

: CHAR? ( addr len 0 | ... xt -- addr len 0 | ... xt )
   DUP ?EXIT DROP  OVER >R  DUP 3 =
   R@ C@ [CHAR] ' = AND  R> 2+ C@ [CHAR] ' = AND
   ( char lit) IF  DROP 1+ C@ ['] LITERAL  EXIT  THEN 0 ;

' CHAR? NUMBER-CONVERSION <CHAIN

{ --------------------------------------------------------------------
This is a stupid example

: FOUNDIT ( -- )   0 Z" FOUND A MATCH" EBOX ;

: TESTME ( addr len 0 | ... xt -- addr len 0 | ... xt )
   DUP ?EXIT DROP
   2DUP S" TESTING" COMPARE IF 0 EXIT THEN
   2DROP ['] FOUNDIT ;

' TESTME NUMBER-CONVERSION <CHAIN
-------------------------------------------------------------------- }

?( ... Startup and exit behavior)

{ ----------------------------------------------------------------------
The LINKTO behavior preserves the file location and creates a call
chain.  Each of the call chains defined here is referenced at a
different time in the bootup or shutdown of the system.

:ONDLLLOAD and :ONDLLEXIT
   are called when a DLL is loaded and unloaded, respectively.

:ONSYSLOAD
   is called by the :noname definition which resolves /SYSTEM, which
   is called by START immediately after the windows api imports have
   been resolved. Errors here are not trapped by sf.

:ONLOAD
   is called by /ONLOAD, which is called by DEVELOPMENT just before the
   GUI is initialized. Errors are caught and cause sf to exit.

:ONENVLOAD is called by DEVELOPMENT just after the GUI is initialized.
   Errors here are not trapped by sf.

---------------------------------------------------------------------- }

: LINKTO ( list -- )   LOCATION , <LINK  (:) ;

CHAIN 'ONDLLLOAD  CHAIN 'ONDLLEXIT
CHAIN 'ONSYSLOAD  CHAIN 'ONSYSEXIT
CHAIN 'ONENVLOAD  CHAIN 'ONENVEXIT
CHAIN 'ONLOAD     CHAIN 'ONEXIT

: :ONSYSLOAD   'ONSYSLOAD LINKTO ;
: :ONSYSEXIT   'ONSYSEXIT LINKTO ;

: :ONDLLLOAD   'ONDLLLOAD LINKTO ;
: :ONDLLEXIT   'ONDLLEXIT LINKTO ;

: :ONENVLOAD   'ONENVLOAD LINKTO ;
: :ONENVEXIT   'ONENVEXIT LINKTO ;

: :ONLOAD      'ONLOAD LINKTO ;
: :ONEXIT      'ONEXIT LINKTO ;

{ ------------------------------------------------------------------------
Aliases for existing words. Use as:

AKA <existing> <alias>

------------------------------------------------------------------------ }

?( ... AKA)

: AKA ( -- )   ' >CODE HEADER ,JMP ;

AKA EXISTS [DEFINED]    IMMEDIATE
AKA ABSENT [UNDEFINED]  IMMEDIATE

{ --------------------------------------------------------------------
ANS wants compiler stack manipulation distinct from data stack
-------------------------------------------------------------------- }

?( ... Compiler stack manipulation)

AKA SWAP CS-SWAP
AKA ROT CS-ROT
AKA ROLL CS-ROLL

: CS-PICK ( ... n -- xn )   PICK +BAL ;

{ --------------------------------------------------------------------
SingleStep and ConsoleBug stubs
-------------------------------------------------------------------- }

?( ... Debug stubs)

THROW#
   S" Invalid BUG nesting" >THROW ENUM IOR_BUGNESTING
TO THROW#

: BUG]   IOR_BUGNESTING THROW ;  IMMEDIATE

: [BUG   BEGIN  BL WORD DUP C@ IF
         FIND SWAP ['] BUG] = AND
      ELSE  DROP  REFILL NOT
   THEN  UNTIL ;  IMMEDIATE

0 VALUE BUGME

: [DEBUG ; IMMEDIATE
: DEBUG] ; IMMEDIATE

{ --------------------------------------------------------------------
Substring search

SEARCH searches the string specified by c-addr1 u1 for the string
specified by c-addr2 u2.  Returns true if a match was found at c-addr3
with u3 characters remaining.  Returns false if there was no match and
c-addr3 u3 is the original string c-addr1 u1.

SEARCH(NC) is a case-insensitive version of SEARCH.

Example:

S" this is a test" 2DUP DUMP
  40FF10 74 68 69 73 20 69 73 20 61 20 74 65 73 74       this is a test

S" is" SEARCH . DUMP -1
  40FF12 69 73 20 69 73 20 61 20 74 65 73 74             is is a test
-------------------------------------------------------------------- }

?( ... Text search)

CODE SEARCH ( c-addr1 u1 c-addr2 u2 -- c-addr3 u3 flag )
   EBX EBX TEST  0= IF   EBX DEC        \ pat len = 0 always matches
      ELSE   EDI PUSH                   \ easier with extra reg
      0 [EBP] EDI MOV                   \ edi = addr of pattern[0]
      EBX 0 [EBP] MOV                   \ 0[ebp] = pat len
      0 [EDI] AL MOV                    \ al = pat[0]
      8 [EBP] EDX MOV                   \ edx = source[i]
      4 [EBP] ECX MOV                   \ ecx = source length
      BEGIN                             \
         EBX ECX CMP  < NOT WHILE       \ source not exausted
         0 [EDX] AL CMP 0= IF           \ source[i] == pattern[i]
            BEGIN                       \ edi = pattern[0]
               EBX DEC  0< IF           \ match
                  EDI POP               \ restore
                  4 # EBP ADD           \ discard (pat len)
                  EDX 4 [EBP] MOV       \ update source
                  ECX 0 [EBP] MOV       \ and len so exit is correct
                  RET                   \ ebx is already -1
               THEN                     \
               0 [EBX] [EDI] AH MOV     \ get pattern[n]
               0 [EBX] [EDX] AH CMP     \ compare to source[i+n]
            0<> UNTIL                   \ until mismatch
            0 [EBP] EBX MOV             \ reload pattern count
         THEN                           \
         ECX DEC  EDX INC               \ advance
      REPEAT                            \ and look again
      EDI POP                           \ restore
      EBX EBX XOR                       \ not found: flag=0
   THEN
   4 # EBP ADD                          \ discard pattern
   RET END-CODE                         \ and return


: SEARCH(NC) ( c-addr1 u1 c-addr2 u2 -- c-addr3 u3 flag )
   2OVER 2>R  BEGIN
      2OVER NIP OVER < 0= WHILE
         2OVER DROP OVER 2OVER COMPARE(NC) WHILE
            2SWAP 1 /STRING 2SWAP
   REPEAT  2DROP 2R> 2DROP -1
   ELSE  2DROP 2DROP 2R> 0
   THEN ;

{ --------------------------------------------------------------------
Parse across multiple lines in a file for a particular delimiter.
The caller supplies the buffer and length, we return the buffer
and the number of chars accumulated.

The routine uses the first cell of the buffer as a count,
and since the user supplies the buffer length, the max string
that can be parsed is the len-4 bytes long.

If the text to parse is longer than the buffer, the entire
string will be skipped, but the text in the buffer will be truncated
and no indication will be given that the parse failed...

Be suspicious if the returned length is equal to the maxlen - 4
-------------------------------------------------------------------- }

?( ... Multiline parsing)

: XPLACE ( src len dest -- )
   2DUP !  CELL+ SWAP CMOVE ;

: XAPPEND ( addr n buf -- )
   2DUP 2>R  @+ +  SWAP CMOVE  2R> +! ;

: |XAPPEND| ( addr n buf max -- )
   OVER @ - ROT MIN SWAP XAPPEND ;

: LPARSE ( buf len char -- buf n )
   >R  OVER OFF  CELL-
   BEGIN
      /SOURCE R@ SCAN                \ buf max a n
      ?DUP 0= WHILE DROP
      /SOURCE 2OVER |XAPPEND|
      REFILL WHILE
   REPEAT ELSE 2DROP THEN
   R> WORD COUNT  2OVER |XAPPEND|
   DROP @+ ;

{ --------------------------------------------------------------------
Redefine USER variables to be aware of how much user space is allocated
in callbacks.
-------------------------------------------------------------------- }

?( ... +USER)

$300 CONSTANT |CB-USER|

-? : USER ( n -- )
   DUP |CB-USER| >= IF
      WARNING @ IF
         CR >IN @ >R  BL WORD COUNT
         ." user variable " TYPE ."  exceeds callback limit"
         R> >IN !
      THEN
   THEN USER ;

-? : +USER ( o n -- o+n)   OVER + SWAP USER ;

{ --------------------------------------------------------------------
From Wil Baden

Get Next Word Across Line Breaks as a Character String.
Length of string is 0 at end of file.
-------------------------------------------------------------------- }

?( ... Next-word and token)

THROW#
   S" Unexpected end of string" >THROW ENUM IOR_ENDOFSTRING
TO THROW#

: NEXT-WORD ( -- addr len )
   BEGIN   BL WORD COUNT       ( addr len)
      DUP IF EXIT THEN
      SOURCE-ID 0= IF CR THEN REFILL
   WHILE   2DROP               ( )
   REPEAT ;                    ( addr len)

: TOKEN ( -- a n )
   BL WORD COUNT  DUP 0= IOR_ENDOFSTRING ?THROW ;

{ ------------------------------------------------------------------------
Find a word; search the context first then all wids

FINDANY searches first the normal context then all wordlists for a string.
It is deferred so that SwiftX can revector it.
------------------------------------------------------------------------ }

?( ... Find a word in any wordlist)

: FINDHARD ( c-addr -- c-addr 0 | xt flag )
   >R WIDS BEGIN
      @REL ?DUP WHILE
      R@ COUNT THIRD CELL+ >WID  SEARCH-WORDLIST ?DUP IF
         ROT DROP  R> DROP  EXIT
      THEN
   REPEAT R> 0 ;

: (FINDANY) ( c-addr -- caddr 0 | xt flag )
   DUP C@ IF
      FIND ?DUP ?EXIT  FINDHARD EXIT
   THEN 0 ;

DEFER FINDANY ( c-addr -- caddr 0 | xt flag )   ' (FINDANY) IS FINDANY

{ ------------------------------------------------------------------------
Find the symbol for an address

.'  searches all the wordlists of the system for the best match
of an address to a symbol.
------------------------------------------------------------------------ }

PACKAGE NAME-TOOLS

: BETTER ( best new addr -- best )
   >R 2DUP SWAP R> ( n b n b a) WITHIN IF SWAP THEN DROP ;

: (.'STRAND) ( addr strand -- vfa )
   SWAP >R 0 SWAP BEGIN         \ best link     \r addr
      @REL ?DUP WHILE           \ best lfa      \r addr
      TUCK L>VIEW R@ BETTER  SWAP
   REPEAT  R>DROP V>NAME ;

: (.'WID) ( addr wid -- nfa )
   0 -ROT  +ORIGIN @+ CELLS BOUNDS ?DO ( best addr)
      DUP I (.'STRAND) ( best a new) N>LINK L>VIEW
      SWAP DUP>R BETTER R>
   4 +LOOP DROP V>NAME ;

PUBLIC

: (.') ( addr -- nfa )
   >R 0  WIDS BEGIN             ( best wl)
      @REL ?DUP WHILE           ( best wl)
      TUCK  R@ SWAP             ( w b a w)
      CELL+ >WID (.'WID)        ( w b n)
      N>VIEW R@ BETTER          ( w b)
      SWAP
   REPEAT R>DROP V>NAME ;

: .' ( addr -- )
   DUP ORIGIN < IF ( this is perhaps an XT)
      ." (xt) " >CODE  THEN
   DUP (.')
   DUP ORIGIN < IF DROP C" <unknown>" THEN
   ( a nfa)  COUNT 2DUP TYPE SPACE  + 1+ -
   ?DUP IF  DUP 0> IF ." +" THEN  . THEN ;

END-PACKAGE

{ --------------------------------------------------------------------
Conditional compilation

These words behave much like IF ELSE and THEN should in a interpretive
state, skipping over text in the input stream.

[ELSE] skips over text until a [THEN] is found, carefully allowing
nested [IF] etc.

[IF] continues interpretation of the input stream if the flag is true,
otherwise scans forward for either [ELSE] or [THEN] as the point to
continue from.

[THEN] is simply a placeholder.

FILE-EXISTS returns true if the file exists.  This is a nice companion
for these conditionals.
-------------------------------------------------------------------- }

?( Conditional compilation)

: [ELSE]  ( -- )
   1 BEGIN                               \ level
     BEGIN  BL WORD COUNT  2DUP UPCASE
       DUP  WHILE                        \ level adr len
       2DUP  S" [IF]"  COMPARE 0= IF     \ level adr len
         2DROP 1+                        \ level'
       ELSE                              \ level adr len
         2DUP  S" [ELSE]"  COMPARE 0= IF \ level adr len
            2DROP 1- DUP IF 1+ THEN      \ level'
         ELSE                            \ level adr len
           S" [THEN]"  COMPARE 0= IF     \ level
             1-                          \ level'
           THEN
         THEN
       THEN ?DUP 0=  IF EXIT THEN        \ level'
     REPEAT  2DROP                       \ level
   REFILL 0= UNTIL                       \ level
   DROP ;  IMMEDIATE

: [IF]  ( flag -- )
   0= IF POSTPONE [ELSE] THEN ;  IMMEDIATE

: [THEN]  ( -- )  ;  IMMEDIATE

: FILE-EXISTS ( caddr u -- flag )
   FILE-STATUS NIP 0= ;

{ --------------------------------------------------------------------
Import/export alias support

AS BAR  3 EXPORT FOO
AS FOO  FUNCTION: BAR ( a b c -- )

-------------------------------------------------------------------- }

: AS ( -- )   >IN @ >AS !  BL WORD DROP ;
