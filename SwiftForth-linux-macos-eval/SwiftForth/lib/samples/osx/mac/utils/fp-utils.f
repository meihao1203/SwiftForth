{ ====================================================================
fp utillities

Copyright (c) 2002-2017 Roelf Toxopeus

SwiftForth version.
Origin MacForth version, which uses PPC instructions.
FP utillities for fp stack juggling and FP parameter passing.
Last: 22 February 2014 08:57:36 CET  rt
==================================================================== }

/FORTH
DECIMAL

{ --------------------------------------------------------------------
fp stack jugglers

Due to the Mac's usage of fp for all graphic related things, fp stack
jugglers similar to those for the data stack are handy.
We deal with fp pairs as used for points, sizes and ranges and fp quads
for rectangles and colours.
F2SWAP F2OVER F2DROP F4DUP FTUCK FNIP do what you expect ...
-------------------------------------------------------------------- }

CODE F2SWAP ( F: r1 r2 r3 r4 -- r3 r4 r1 r2 )
	4 >FS					\ hardwarestack
	ST(2) FXCH				\ r1 r2 r3 r4 -- r1 r4 r3 r2
	ST(1) FXCH				\ r1 r4 r3 r2 -- r1 r4 r2 r3
	ST(3) FXCH				\ r1 r4 r2 r3 -- r3 r4 r2 r1
	ST(1) FXCH				\ r3 r4 r2 r1 -- r3 r4 r1 r2
	4 FS>					\ back to fpstack
	FNEXT

CODE F2OVER ( F: r1 r2 r3 r4 -- r1 r2 r3 r4 r1 r2 )
	4 >FS					\ hardwarestack
	ST(3) FLD			   \ r1 r2 r3 r4 -- r1 r2 r3 r4 r1 
	ST(3) FLD				\ r1 r2 r3 r4 r1 -- r1 r2 r3 r4 r1 r2
	6 FS>					\ back to fpstack
	FNEXT

CODE F2DROP ( F: r1 r2 -- )
	2 >FS					\ hardwarestack
	ST(0) FSTP				\ r1 r2 -- r1
	ST(0) FSTP				\ r1 --
	FNEXT
	
CODE F4DUP ( F: r1 r2 r3 r4 -- r1 r2 r3 r4 r1 r2 r3 r4 )
	4 >FS					\ hardwarestack
	ST(3) FLD			   \ r1 r2 r3 r4 -- r1 r2 r3 r4 r1 
	ST(3) FLD				\ r1 r2 r3 r4 r1 -- r1 r2 r3 r4 r1 r2
	ST(3) FLD			   \ r1 r2 r3 r4 r1 r2 -- r1 r2 r3 r4 r1 r2 r3 
	ST(3) FLD				\ r1 r2 r3 r4 r1 r2 r3 -- r1 r2 r3 r4 r1 r2 r3 r4
	8 FS>					\ back to fpstack
	FNEXT

CODE FTUCK ( F: r1 r2 -- r2 r1 r2 )
	2 >FS					\ hardwarestack
	ST(1) FXCH			   \ r1 r2 -- r2 r1 
	ST(1) FLD			   \ r2 r1 -- r2 r1 r2
	3 FS>					\ back to fpstack
	FNEXT

CODE FNIP ( F: r1 r2 -- r2 )
	2 >FS					\ hardwarestack
	ST(1) FXCH				\ r1 r2 -- r2 r1
	ST(0) FSTP				\ r2 r1 -- r2
	1 FS>					\ back to fpstack
	FNEXT

{ --------------------------------------------------------------------
passing sfloat and dfloats to calls

Many could be just aliasses for existing words, but might involve special
handling wrt call ABI on other architectures: 32b SF and VFX - 64b iForth
FPUSHS 2FPUSHS 4FPUSHS pass fp numbers as sf's on data stack.
The names are Marcel Hendrix's from iForth, the original MacForth names
were less attractive.
The fast assembler 4FPUSHS learned from RickVanNorman in the Faq-o-Matic
OpenGL Spin Cube. 2FPUSHS and FPUSHS are derived from that version.

FPUSHD 2FPUSHD 4FPUSHD and DF>F are aliasses for George Kozlowski
fp stack passing words found in fp-passing.f
Each DF consumes 2 cells on the data stack, take care when defining
functions and methods!
-------------------------------------------------------------------- }

\ --------------------------------------------------------------------
\ fp to sfloat on data stack conversion

(* skip hi level versions
\ Here alias for F>SF hilevel version which is faster than assembler version?!?!?
: FPUSHS ( -- sfloat ) ( F: r -- )   0 >r rp@ sf! r>  ;

: 2FPUSHS ( -- sf1 sf2 ) ( F: r1 r2 -- )
	fswap fpushs fpushs ;
	
: 4FPUSHS ( -- sf1 sf2 sf3 sf4 ) ( F: r1 r2 r3 r4 -- )
	f2swap 2fpushs 2fpushs ;
*)

\ much faster code definition.
CODE 4FPUSHS ( -- sf1 sf2 sf3 sf4 ) ( F: r1 r2 r3 r4 -- )
	4 >FS                \ make sure data on hardware stack
	16 # EBP SUB         \ room for 4 integers and tos
	12 [EBP] DWORD FSTP  \ convert t
	 0 [EBP] DWORD FSTP  \ convert z
	 4 [EBP] DWORD FSTP  \ convert y
	 8 [EBP] DWORD FSTP  \ convert x
	12 [EBP] EBX XCHG    \ swap t and old tos
	RET END-CODE

\ Note: the XCHG replacement pays off!
CODE 2FPUSHS ( -- sf1 sf2 ) ( F: r1 r2 -- )
	2 >FS               \ make sure data on hardware stack
	8 # EBP SUB         \ room for 2 integers and tos
	4 [EBP] DWORD FSTP  \ convert t
	0 [EBP] DWORD FSTP  \ convert z
   EBX EAX MOV   4 [EBP] EBX MOV   EAX 4 [EBP] MOV	\ replacement for   4 [EBP] EBX XCHG    \ swap t and old tos
   RET END-CODE

\ this one is as fast as the hilevel version
CODE FPUSHS ( -- sfloat ) ( F: r -- )
	>F	                \ make sure data on hardware stack
   4 # EBP SUB         \ room for 1 integers and tos
   0 [EBP] DWORD FSTP  \ convert x
   EBX EAX MOV   0 [EBP] EBX MOV   EAX 0 [EBP] MOV	\ replacement for   0 [EBP] EBX XCHG    \ swap x and old tos
	RET END-CODE

\ --------------------------------------------------------------------
\ fp to dfloat on data stack conversion

: FPUSHD  ( -- d ; F: r -- )   FSTACK>STACK ;
: 2FPUSHD ( -- d d ; F: r r -- )   2FSTACK>STACK ;
: 4FPUSHD ( -- d d d d ; F: r r r r -- )   4FSTACK>STACK ;
: DF>F ( d -- ; F: -- r )   STACK>FSTACK ;

cr .( fp utilities loaded)

\\ ( eof )

