{ ====================================================================
Callbacks

Copyright 2010  FORTH, Inc.

CB: defines entry points into the Forth environment that can be called
by the OS.
==================================================================== }

?( Callbacks)

/FORTH

{ ------------------------------------------------------------------------
Callback parameters

Callbacks are passed parameters on the stack.  User variable 'WF has
a pointer to the callback parameters.  These are variables in the
"stack frame" of the callback API, passed as indexed parameters on
the stack below the return address.

We name the first 8 parameters in a generic fashion. If more are
needed, it is easy to compile more.
------------------------------------------------------------------------ }

#USER
   CELL +USER 'WF               \ Callback parameter frame pointer
( n ) TO #USER

PACKAGE LIB-INTERFACE

: NTH_PARAM ( n -- )
   ICODE
   [+ASM]
      PUSH(EBX)
      'WF [U] EBX MOV
      ( n) CELLS [EBX] EBX MOV
      RET   END-CODE
   [-ASM] ;

PUBLIC

0 NTH_PARAM _PARAM_0
1 NTH_PARAM _PARAM_1
2 NTH_PARAM _PARAM_2
3 NTH_PARAM _PARAM_3
4 NTH_PARAM _PARAM_4
5 NTH_PARAM _PARAM_5
6 NTH_PARAM _PARAM_6
7 NTH_PARAM _PARAM_7

PRIVATE

{ ------------------------------------------------------------------------
Callback code

Preserve: EDI, ESI, EBX, EBP
------------------------------------------------------------------------ }

DEFER CAUGHT   ' NOOP IS CAUGHT

: CALLBACK ( xt -- res )
   CATCH DUP IF CAUGHT 0 SWAP THEN DROP ;

LABEL RUNCB
   8 [ESP] ECX LEA                      \ ECX points to parameters
   EDX POP                              \ Pop pointer to parameter field

   EBX PUSH                             \ Save registers
   ESI PUSH
   EDI PUSH
   EBP PUSH

   -16 [ESP] EBP LEA                    \ start stack in open space
   $1000 # ESP SUB                      \ move return stack below
   8 [ESP] ESI LEA                      \ user area above stack
   ECX 'WF [U] MOV                      \ set callback paramater pointer
   ESP R0 [U] MOV                       \ save stack pointers in user area
   EBP S0 [U] MOV

   |CB-USER| [ESI] EAX LEA              \ generate a new dictionary pointer
   EAX H [U] MOV                        \ and set into user area
   |CB-USER| $400 + [ESI] EAX LEA       \ top of dictionary = here + 1k available
   EAX HLIM [U] MOV                     \ and top of dictionary

   $0A # BASE [U] MOV                   \ decimal
   0 # 'METHOD [U] MOV                  \ default method
   0 # STATE [U] MOV                    \ not compiling

   BEGIN 5 + DUP CALL   EDI POP         \ establish data space pointer in EDI
   ( *) -ORIGIN # EDI SUB

   0 # 0 [EBP] MOV                      \ nos=zero
   0 [EDX] EBX MOV                      \ get xt for tos
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
   CREATE  RUNCB ,CALL  ( n) DROP  ( xt) , ;

END-PACKAGE
