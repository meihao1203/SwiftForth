{ ====================================================================
i386 ASSEMBLER

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman
==================================================================== }

{ --------------------------------------------------------------------
This assembler assumes at least an 80386 operating in protected mode.

Exports: Assembler word set
-------------------------------------------------------------------- }

PACKAGE ASM-WORDLIST

{ --------------------------------------------------------------------
These words are in ASM-WORDLIST . They are not normally visible;
however, they are needed during the use of the assembler.

!INLINE sets the inline expansion byte of the most recently defined
   word to its length not including an expected RET opcode.

[-ASM] removes the assembler from the search order and resets
   the xt optimizer.

ASM] is the terminator of an inline code phrase.

END-CODE is the terminator of a LABEL or CODE.
-------------------------------------------------------------------- }


: !INLINE ( -- )
   'CFA @   'CFA OFF  ?DUP -EXIT
   HERE OVER - 1-  SWAP 1- C! ;

: [-ASM] ( -- )
   ASM-WORDLIST -ORDER [/OPT] ; IMMEDIATE

: ASM]
   POSTPONE [-ASM]  ] ;

: END-CODE ( -- )
   ?DANGLING  !INLINE  POSTPONE [-ASM]  -SMUDGE ;

{ --------------------------------------------------------------------
These are the public words, the user interface to the assembler.
-------------------------------------------------------------------- }

PUBLIC

{ --------------------------------------------------------------------
Search order manipulators

[ASM] adds the assembler to the search order.

ASM initializes the assembler, resets the xt optimizer, and adds the
   assembler to the search order.

[ASM begins an inline code phrase in a high level definition.

[+ASM] adds the assembler to the search order during compilation.
   This is useful for building macros.
-------------------------------------------------------------------- }

: [ASM] ( -- )   ASM-WORDLIST +ORDER   ;  IMMEDIATE

: ASM ( -- )   /LABELS [/OPT] POSTPONE [ASM] ;

: [ASM ( -- )   POSTPONE [  ASM ;  IMMEDIATE

: [+ASM] ( -- )   POSTPONE [ASM] ; IMMEDIATE

: [+ASSEMBLER] ( -- )   POSTPONE [ASM] ; IMMEDIATE

{ --------------------------------------------------------------------
Defining words

CODE begins an executable definition in assembler. The name of the
   routine will execute the code defined.

ICODE is the same as a code definition, except that the new definition
   has its inline byte set so it is expanded at compile time.

LABEL begins a named code fragment. The name of the label returns
   the address of the fragment.

;CODE terminates a high level defining word (which must use create)
   with a code fragment which implements the runtime behavior of
   the defining word.
-------------------------------------------------------------------- }

: CODE ( -- )
   SKIP-CL  HEADER ASM  'CFA OFF ;

: ICODE ( -- )
   HEADER ASM  HERE 'CFA ! ;

: LABEL ( -- )
   CREATE ASM  'CFA OFF ;

: ;CODE ( -- )
   POSTPONE (;CODE)
   POSTPONE [ASM ; IMMEDIATE

END-PACKAGE
