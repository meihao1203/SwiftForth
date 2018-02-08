{ ====================================================================
Double shift

Learned from CarbonMacForth

Last: 20 January 2011 12:26:28 CET  -rt
==================================================================== }

/FORTH
DECIMAL

{ --------------------------------------------------------------------
DLSHIFT and DRSHIFT shift the double on the stack resp. left and right
u bits.
DSHIFT shifts the double left when n is positive and right when negative.
-------------------------------------------------------------------- }

: DLSHIFT  ( d1 u -- d2 )
	DUP >R
	32 >= IF
		DROP 0	SWAP			  \ new lo, oldlo base for newhi
		R> 32 - LSHIFT			  \ new hi
	ELSE
		OVER R@ LSHIFT			  \ new lo
		SWAP R@ LSHIFT
		ROT 32 R> - RSHIFT OR  \ new hi
	THEN ;

: DRSHIFT  ( d1 u -- d2 )
	DUP >R
	32 >= IF
		NIP
		R> 32 - RSHIFT			  \ new lo
		0						     \ new hi
	ELSE
		SWAP R@ RSHIFT
		OVER 32 R@ - LSHIFT OR \ new lo
		SWAP R> RSHIFT		     \ new hi
	THEN ;

: DSHIFT  ( d1 n -- d2 )   DUP 0> IF DLSHIFT ELSE NEGATE DRSHIFT THEN ;

CR .( double extra's loaded )

\\ ( eof )
