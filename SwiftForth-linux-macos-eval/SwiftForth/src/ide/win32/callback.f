{ ====================================================================
Callbacks

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

CB: defines entry points into the Forth environment that can be called
by the OS.
==================================================================== }

?( Windows Callbacks)

/FORTH

PACKAGE WINDOWS-INTERFACE

{ ------------------------------------------------------------------------
Callback code

Preserve: EDI, ESI, EBX, EBP
------------------------------------------------------------------------ }

DEFER CAUGHT   ' NOOP IS CAUGHT

: CALLBACK ( xt -- res )
   CATCH DUP IF CAUGHT 0 SWAP THEN DROP ;

LABEL RUNCB
   8 [ESP] ECX LEA                      \ ECX points to parameters
   0 [ESP] EDX MOV                      \ Return addr in CB: word's parameter field

   EBX PUSH                             \ Save registers
   ESI PUSH
   EDI PUSH
   EBP PUSH

   -16 [ESP] EBP LEA                    \ start stack in open space
   $1000 # ESP SUB                      \ move return stack below
   8 [ESP] ESI LEA                      \ user area above stack
   ECX 'WF [U] MOV                      \ set callback parameter pointer
   ESP R0 [U] MOV                       \ save stack pointers in user area
   EBP S0 [U] MOV

   |CB-USER| [ESI] EAX LEA              \ generate a new dictionary pointer
   EAX H [U] MOV                        \ and set into user area
   |CB-USER| $400 + [ESI] EAX LEA       \ top of dictionary =  here + 1k available
   EAX HLIM [U] MOV                     \ and top of dictionary

   $0A # BASE [U] MOV                   \ decimal
   0 # 'METHOD [U] MOV                  \ default method
   0 # STATE [U] MOV                    \ not compiling

   BEGIN 5 + DUP CALL   EDI POP         \ establish data space pointer in EDI
   ( *) -ORIGIN # EDI SUB

   0 # 0 [EBP] MOV                      \ nos=zero
   4 [EDX] EBX MOV                      \ get xt for tos
   ' CALLBACK >CODE CALL                \ and run the word...
   EBX EAX MOV                          \ return result

   S0 [U] ESP MOV                       \ restore
   16 # ESP ADD                         \ and negate the padding
   EBP POP                              \ restore registers
   EDI POP
   ESI POP
   EBX POP
   RET   END-CODE

PUBLIC

: CB: ( xt n -- )  \ Usage: xt n CB: <name>
   CREATE  RUNCB ,CALL  ( nRET) $C2 C, CELLS H,
   ( Filler) 0 C,  ( xt) , ;

END-PACKAGE
