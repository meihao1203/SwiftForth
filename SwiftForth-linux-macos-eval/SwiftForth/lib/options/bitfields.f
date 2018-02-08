{ ====================================================================
Bit fields for SWOOP

Copyright (C) 2001 FORTH, Inc.  All rights reserved.
==================================================================== }

OPTIONAL BITFIELDS A bit-field data type for SWOOP

{ --------------------------------------------------------------------
Bit field operators

BIT@ reads byte at the address, and right-justifies the resulting bits
according to the mask field.

BIT! writes bits into the mask fields of the data at the address.
-------------------------------------------------------------------- }

CODE BIT@ ( mask addr -- n )
   EAX EAX XOR                          \ zero
   0 [EBP] AL MOV  4 # EBP ADD          \ get mask
   0 [EBX] BL MOV  EAX EBX AND          \ get value and mask
   $100 # EAX OR  BEGIN                 \ failsafe mask
      1 # AL TEST  0= WHILE             \ check mask
      EBX SHR  EAX SHR                  \ move data down, mask down
   REPEAT
   RET   END-CODE

CODE BIT! ( n mask addr -- )
   EAX EAX XOR                          \ zero
   0 [EBP] AL MOV  AL CL MOV            \ cl and al are is mask
   4 [EBP] CH MOV                       \ ch is data
   $100 # EAX OR   BEGIN                \ failsafe mask
      1 # AL TEST  0= WHILE             \ check mask
      CH SHL  EAX SHR                   \ move data up, mask down
   REPEAT                               \ data positioned
   CL CH AND                            \ only required bits
   CL NOT                               \ invert mask
   0 [EBX] CL AND                       \ read into inverted mask
   CH CL OR                             \ insert my data
   CL 0 [EBX] MOV                       \ and write to memory
   8 [EBP] EBX MOV                      \ refill tos
   12 # EBP ADD
   RET   END-CODE

{ --------------------------------------------------------------------
1. Determine what data the member record will contain. For our
bitfield operators, it will contain the byte offset in the object and
the bitmask for access. This was determined by our choice of bit
operators. Had operators been chosen that used different parameters,
we would have decided to keep different data in this record.  Note
that the offset is kept as the first data item. This keeps
compatability with the other data operators such as BUFFER:

| compiler-xt | link | member handle | runtime-xt | offset | mask |

2. Implement the early and late binding code for the data type.

RUN-BITFIELD is the late binding version. Given the address of the
object, and the address of the data portion of the member record, we
compute the proper parameters to be left on the stack for the type
specific operators.

COMPILE-BITFIELD is the early binding routine. It is executed at
compile time, and must lay down code that will generate the proper
reference to the data when executed.  Note the use of "SELF" -- this
is so that when a reference is made inside a class definition, the
object address gets pushed on the stack.  This reference is simply a
noop in code outside the class definition, since we assume that the
object address is on the stack already.  The rest of the code is
compiling a reference which is exactly equivalent to the run-time code
above, except that the offset and mask are compiled as literals here
so the optimizer can work magic on them.
-------------------------------------------------------------------- }

PACKAGE OOP

: RUN-BITFIELD ( object 'data -- mask addr )   2@ ROT +  0 >THIS ;

: COMPILE-BITFIELD ( 'data -- )   "SELF"   \ 'data: offset
   2@ ?DUP IF POSTPONE LITERAL POSTPONE + THEN
   POSTPONE LITERAL POSTPONE SWAP  END-REFERENCE ;

{ --------------------------------------------------------------------
Support words for the bitfield definition.

ONES generates a pattern of n ones.

?CROSSING aborts if the bit field being added crosses a byte boundary.

?BITVAR is a syntax checking word. I always try to check syntax when
building multi-part structures.
-------------------------------------------------------------------- }

: ONES ( n -- ones )
   1 MAX  1 SWAP 1 ?DO  2* 1+  LOOP ;

: ?CROSSING ( bit size -- )
   + 8 > ABORT" Bit fields cannot cross byte boundaries" ;

: ?BITVAR ( flag -- )
   ['] ONES <> ABORT" Error defining bit field" ;

{ --------------------------------------------------------------------
Here we extend the class compiler to implement a bit field. The syntax
I have chosen to implement is

   BIRVAR name          \ define the start of the bit fields
      n BITS bitfield1  \ define a series of bit fields
      n BITS bitfield2  \
      BITALIGN          \ realign to start of next byte.
      n BITS bitfield3  \
      n BITS bitfield4  \
   END-BITVAR

Bits are allocated from the lsb upward, filling bytes sequentially from
the start of the BITVAR definition.

BITVAR names a 0-length buffer, and leaves a syntax flag on the stack
along with an initial bit position (0).

END-BITVAR checks the structure syntax and aligns the data allocation
to the nearest byte.

BITALIGN forces the next bit to be byte-aligned.

BITS defines a new bit field, saving its byte offset in the class and a
bit mask which is used for accessing its data.  The bit position is
updated for its next use, and a byte of the instance variable space is
allocated if needed.
-------------------------------------------------------------------- }

GET-CURRENT ( *) CC-WORDS SET-CURRENT

   : BITVAR ( -- flag bit )
      [ +CC ] 0 BUFFER: [ -CC ] ['] ONES  0 ;

   : BITALIGN ( flag bit -- flag bit )
      OVER ?BITVAR
      DUP IF DROP  1 THIS >SIZE +!  0  THEN ;

   : END-BITVAR ( flag bit -- )
      [ +CC ] BITALIGN [ -CC ] 2DROP ;

   : BITS ( flag bit size -- flag bit2 )
      2DUP ?CROSSING  2 PICK ?BITVAR
      MEMBER  THIS SIZEOF
      ['] RUN-BITFIELD ['] COMPILE-BITFIELD  NEW-MEMBER
      DUP ONES  2 PICK LSHIFT , +
      8 /MOD THIS >SIZE +! ;

   : UNUSED-BITS ( flag bit size -- flag bit2 )
      2 PICK ?BITVAR  +  8 /MOD THIS >SIZE +! ;

GET-CURRENT CC-WORDS <> THROW ( *) SET-CURRENT

END-PACKAGE
