{ ====================================================================
fp precission conversion

Copyright (c) 2002-2017 Roelf Toxopeus

SwiftForth version.
Comes from MacForth version, which uses PPC instructions.
Converting between single precision (SF) and native format precision (F) fp.
Many OS calls need and/or return single precision fp. These 32bit SF's
are passed via the data stack.
Also contains the integer <=> fp formats conversions.
Last: 22 February 2014 08:56:40 CET  -rt
==================================================================== }

/FORTH
DECIMAL

{ --------------------------------------------------------------------
conversion between fp formats

These are the faster assembler versions. The Intel XCHG opcode is replaced
by a faster sequence of opcodes.
Also the stock SF S>F F>S D>F F>D versions are redefined: 3 times faster!

SF>F converts 32b SFLOAT on data stack to native FLOAT on fp stack.
F>SF does the reverse.
Note: F is not necessarely a DF. In SwiftForth it is, but not in iForth.

LOCATE S>F D>F F>D F>S o.s.s. for info on those.
-------------------------------------------------------------------- }

CODE SF>F ( sfloat -- ) ( F: -- r )
	EBX EAX MOV   0 [EBP] EBX MOV   EAX 0 [EBP] MOV	\ replacement for    0 [EBP] EBX XCHG
	0 [EBP] DWORD FLD  4 # EBP ADD  f>
	FNEXT

CODE F>SF ( -- sfloat ) ( F: r -- )
	>f  4 # EBP SUB  0 [EBP] DWORD FSTP
	EBX EAX MOV   0 [EBP] EBX MOV   EAX 0 [EBP] MOV	\ replacement for    0 [EBP] EBX XCHG
	FNEXT

\ --------------------------------------------------------------------
\ redefined SwiftForth versions:

CODE S>F ( n -- ) ( -- r )
	EBX EAX MOV   0 [EBP] EBX MOV   EAX 0 [EBP] MOV	\ replacement for   0 [EBP] EBX XCHG
	0 [EBP] DWORD FILD  4 # EBP ADD  f>
	FNEXT

CODE D>F ( d -- ) ( -- r )
	EBX EAX MOV   4 [EBP] EBX MOV   EAX 4 [EBP] MOV	\ replacement for   4 [EBP] EBX XCHG
	0 [EBP] QWORD FILD  8 # EBP ADD  f>
	FNEXT

CODE (F>S) ( -- n ) ( r -- )
	>f  4 # EBP SUB  0 [EBP] DWORD FISTP
	EBX EAX MOV   0 [EBP] EBX MOV   EAX 0 [EBP] MOV	\ replacement for   0 [EBP] EBX XCHG
	FNEXT

CODE (F>D) ( -- d ) ( r -- )
	>f  8 # EBP SUB  0 [EBP] QWORD FISTP
	EBX EAX MOV   4 [EBP] EBX MOV   EAX 4 [EBP] MOV	\ replacement for   4 [EBP] EBX XCHG
	FNEXT

: F>D ( -- d ) ( r -- )   TRUNCATE (F>D) ;
: F>S ( -- n ) ( r -- )   TRUNCATE (F>S) ;

{ --------------------------------------------------------------------
integer <=> (s)fp conversions

Some words are here for 'old times' sake. They should be replaced in
due time for 'standard' versions:
INT -- convert native fp format on fp stack to integer on stack.
FLOAT -- convert integer on data stack to native fp format on fp stack.
SFLOAT -- convert integer on data stack to 32b fp format on data stack.
SINT -- convert 32b fp format on data stack to integer on stack.
Note: these are re-definitions of the 'standard' versions.

S>SF -- convert integer on data stack to 32b fp format on data stack.
SF>S -- convert 32b fp format on data stack to integer on stack.
-------------------------------------------------------------------- }

ICODE S>SF ( n -- sfloat )
	0 [EBP] EAX MOV		\ save second on stack
	EBX 0 [EBP] MOV		\ need EBP for addresing mode
	0 [EBP] DWORD FILD	\ convert integer to float
	0 [EBP] DWORD FSTP	\ return as sloat
	0 [EBP] EBX MOV		\ to top
	EAX 0 [EBP] MOV		\ restore second on stack
	RET END-CODE

ICODE SF>S ( sfloat -- n )
	0 [EBP] EAX MOV		\ save second on stack
	EBX 0 [EBP] MOV		\ need EBP for addressing mode
	0 [EBP] DWORD FLD		\ load fp
	0 [EBP] DWORD FISTP	\ for conversion to integer
	0 [EBP] EBX MOV		\ is top stack
	EAX 0 [EBP] MOV		\ restore second on stack
	RET END-CODE

AKA F>S INT

AKA S>F FLOAT

AKA S>SF SFLOAT

AKA SF>S SINT

CR .( faster fp precision loaded)

\\ ( eof )