{ ====================================================================
petwords for porting harness

Copyright (c) 1988-2017 Roelf Toxopeus

SwiftForth version.
Much used words acumulated over the years using several Forth systems.
Originates in Mach2 -> Power/Carbon MacForth -> iForth -> SwiftForth -> VFX
Some are favourites, some are just system specific often found in source
files. Some will be replaced by nicer versions found in new systems,
while porting. Finding new favourites continues...
Last: 29 Nov 2015 12:13:09 CET   -rt
==================================================================== }

{ --------------------------------------------------------------------
List of pets
Note: some are commented out, because they're already in used Forth.
Others are superceded by better ones, but left for portability.

ANEW -- If next word found, execute it, assuming it's a marker. Then
re-create the marker. Effectively it's an persisting marker. 

LACKING -- If next word in inputstream exists, ignore rest of line.
Else continue interpretting line. Kind of conditional compiling.

DEFAULT-ORDER -- Set default context and wordlist for current.

/FORTH -- Set default context and wordlist for current.

PRIOR.STREAM -- Stop interpreting a file. 

\\ -- Stop interpreting a file.

COMPILING -- Leaves a flag, true when compiling. In SwiftForth use
STATE @ !!!!

ASCII - State smart version of CHAR and [CHAR], *but* capable of
leaving a 4 chars string, used a lot as id on the Mac.

ALLOTERASE -- Allot and erase memory in one go.

/ALLOT -- Allot and erase memory in one go.

BUFFER: -- Create word pointing to allotted memory.

RECURSIVE -- Used to make current word under construction visible.
Allows for simple BEGIN AGAIN loops, assuming tail optimization. 
Also allows for getting the xt from current word under construction,
calling ['] on word etc. All in all superior over RECURSE.
Some systems know this word as REVEAL.
Note: Charles Moore removed the smudge stuff all together.

QUERY -- Query for input, use with INTERPRET, very handy while debugging.
Very much preferred over REFILL as name.

0" -- Return zero terminated string (no count field). In some systems
known as Z"

POCKET -- Transient area for string manupilation.

PARSE>POCKET -- Parse text and move as 0string or zstring in pocket.
Transient area, use immediately.

NEXTWORD -- Scan for next word over line brakes till end of input.
Unlike Baden's NEXT-WORD, it returns a counted string like WORD.

SKIPS -- Skip text over string pointed by addr n. Allows other
'skippers' than those found in currently used Forth. Not case sensitive!

{ is used by many Forth systems for locals, so 2 preferred replacements:
(* -- Skip text till *)  MacForth, iForth, VFX
(( -- Skip text till ))  VFX, MFonVFX

LCOUNT -- Used as COUNT but for counted strings with a CELL size
count field.

CLS -- Clear screen.

SIFTING -- Print words containing pattern from next parsed word.
SIFTING DUP, will print all words containing DUP

.. -- Print what ever on the data and fp stacks, clearing them in
the process.
Note: lifo order left to right, unlike .S

.B -- Temporary change base to binary and print number.
Easy for eyeballing masks.

.H -- Temporary change base to hex and print number.    
Prefer over often found H.

.D -- Temporary change base to decimal and print number.
Obviously can't use D.

.BASE -- Print base in decimal.

?PAUSE -- Like KEY?, but when a key is hit, it pauses waiting
for another key. All keys except spacebar leave a true flag. 

MANY -- Looping in interpreter until a key hit. Uses ?PAUSE.

SNAP -- Suspend program, showing stack. Waits for a keypres to
continue. Q aborts.
Alternative: : SNAP   .s  key 27 = if cr prompt quit then ;                            
Example: : tt    begin random random random snap drop drop drop again ;      

SNAP" -- SNAP with message.

G -- Jump to line in file which caused an abort during an INCLUDE

STARTER -- Startup word in turnkey

EMPTY -- Wipe dictionary from user added words down till FENCE
-------------------------------------------------------------------- }

ONLY FORTH ALSO DEFINITIONS
DECIMAL

\ --------------------------------------------------------------------
\ --- used during evaluating file contents:

{ --------------------------------------------------------------------
  -- left over CarbonMacForth
  -- no replacement, phase out
: ANEW ( spaces<name> -- )
   >IN @   BL WORD FIND IF EXECUTE ELSE DROP THEN  >IN ! MARKER ;
-------------------------------------------------------------------- }

: LACKING ( spaces<name> -- )   BL WORD FIND NIP IF [COMPILE] \ THEN ;

{ --------------------------------------------------------------------
  -- left over CarbonMacForth
  -- replace with /FORTH
: DEFAULT-ORDER    only forth also definitions ;
-------------------------------------------------------------------- }

\ /FORTH exists in SwiftForth

{ --------------------------------------------------------------------
  -- left over CarbonMacForth
  -- replace with \\
: PRIOR.STREAM		\\ ;
-------------------------------------------------------------------- }

\ \\ exists in SwiftForth

\ --------------------------------------------------------------------
\ --- simple redefinitions and oneliners:

\ COUNTER exists in SwiftForth

\ TIMER existst in SwiftForth

\ EXPIRED existst in SwiftForth

\ INTERPRET exists in SwiftForth

\ COMPILING existst in SwiftForth but differently!!!
\ use  STATE @

: ASCII ( spaces<chars> -- n )
	BL PARSE ?DUP 
	IF OVER C@ SWAP 1- 3 MIN 0 ?DO
		8 LSHIFT OVER I 1+ + C@ + LOOP
		NIP
		STATE @ IF POSTPONE LITERAL THEN
	ELSE TRUE ABORT" ASCII NO Characters !" THEN ; IMMEDIATE


{ --------------------------------------------------------------------
  -- left over CarbonMacForth
  -- replace with /ALLOT
: ALLOTERASE ( n -- )  /ALLOT ;
-------------------------------------------------------------------- }

\ /ALLOT exists in SwiftForth

\ BUFFER: exists in SwiftForth

: RECURSIVE ( -- )   -SMUDGE ; IMMEDIATE

: QUERY ( -- )   REFILL DROP ;

\ --------------------------------------------------------------------
\ --- string stuff:

: 0" ( spaces<string> -- a )   POSTPONE Z" ; IMMEDIATE

\ POCKET exists in SwiftForth

: PARSE>POCKET ( char -- )   PARSE 255 MIN POCKET ZPLACE ;

: NEXTWORD ( -- c-addr)   NEXT-WORD DROP [ 1 CHARS ] LITERAL - ;

: SKIPS ( a n -- )
			BEGIN  NEXTWORD COUNT DUP
		WHILE  2OVER COMPARE(NC) 0= IF  2DROP EXIT  THEN
	REPEAT 2DROP 2DROP ;   \ <= eof, drop pattern as well!

: (* ( text -- )   S" *)" SKIPS ; IMMEDIATE

: (( ( text -- )   S" ))" SKIPS ; IMMEDIATE

\ : LCOUNT ( addr1 -- addr2 n )  DUP CELL+ SWAP @ ;
AKA @+ LCOUNT

\ --------------------------------------------------------------------
\ --- user interface:

: CLS ( -- )   PAGE ;

: SIFTING ( <text> -- )   WORDS ;

: ..  ( whatever on the stacks )
	CR DEPTH 0 ?DO . LOOP
	CR FDEPTH 0 ?DO F. LOOP ;

: .B ( N -- )   BASE @ SWAP BINARY U. BASE ! ;

: .H ( N -- )   BASE @ SWAP HEX U. BASE ! ;

: .D ( N -- )   BASE @ SWAP DECIMAL U. BASE ! ;

: .BASE ( -- )   ." Base (in decimal): " BASE @ .D ;

: ?PAUSE ( -- f )
	KEY? DUP IF							\ any key action? 
		DROP KEY DROP					\ drop flag and pressed key
		CR ." Spacebar to Continue" CR
		KEY BL <> THEN ;				\ wait for key action and flag it

: MANY	( -- )   ?PAUSE 0= IF 0 >IN ! THEN ;

: SNAP ( -- )   .S  CR ." any key continues, q aborts" KEY [CHAR] q = ABORT" aborts ..." ;

: SNAP" ( <string"> -- )   POSTPONE CR POSTPONE ." POSTPONE SNAP ; IMMEDIATE

\ G exists in SwiftForth

\ STARTER exists in SwiftForth

\ EMPTY exists in SwiftForth

CR .( Pets and port harness loaded)

\\  ( eof )