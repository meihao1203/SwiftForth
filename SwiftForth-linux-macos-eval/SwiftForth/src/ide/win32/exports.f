{ ====================================================================
Exported functions

Copyright 2011  FORTH, Inc.

Exporting Forth words as DLL functions is managed here.
==================================================================== }

PACKAGE TURNKEY-TOOLS

{ --------------------------------------------------------------------
Exports linked list

'EXPORTS points to the linked list of exported functions.  Each node
in the list has this structure:
  +0  Link to next node; 0 if end
  +4  Ptr to function code
  +8  Counted, null-terminated function name string

Note that this list is only used to build the export directory table.
It is discarded after use.  It it not intended to be used by the
turnkey code at runtime.

+EXPORTS adds a new node for the name [addr len] to the 'EXPORTS list
in lexicographic order.

RVA returns the relative virtual address (the address in memory
relative to the start of the program's image, HINST).

.EXPORTS dumps the list of exported public function names for debug
purposes.

#EXPORTS returns the number of entries in the 'EXPORTS list.
-------------------------------------------------------------------- }

VARIABLE 'EXPORTS

:PRUNE   'EXPORTS UNLINKS ;

: +EXPORTS ( addr len -- )
   'EXPORTS  BEGIN  DUP @REL WHILE
      3DUP @REL 2 CELLS + COUNT COMPARE
      DUP 0= ABORT" Function name already in exports list"
      0< IF  >LINK 2DROP EXIT  THEN
   @REL REPEAT  >LINK 2DROP ;

PUBLIC

: RVA ( addr -- rva )   HINST - ;

: .EXPORTS ( -- )
   'EXPORTS BEGIN  @REL ?DUP WHILE
      CR  DUP CELL+ @ RVA H. SPACE  DUP 2 CELLS + COUNT TYPE SPACE
   REPEAT ;

PRIVATE

: #EXPORTS ( -- n )
   0  'EXPORTS BEGIN  @REL ?DUP WHILE  SWAP 1+  SWAP REPEAT ;

{ --------------------------------------------------------------------
Export tables

,XDIR compiles the export directory table if there are any exports.
This must be the first structure in the export section (as defined by
the address and length in the Export Table field of the Optional PE
Header).

,ORDINALS compiles the ordinals list.

,NAMES compiles the list of RVA pointers to the public names of the
exported functions.

,ADDRS compiles the list of RVA pointers to the exported functions.

-------------------------------------------------------------------- }

: ,ORDINALS ( -- )
   #EXPORTS 0 DO I H, LOOP ;

: ,NAMES ( -- )
   'EXPORTS BEGIN  @REL ?DUP WHILE  DUP 2 CELLS + 1+ RVA ,  REPEAT ;

: ,ADDRS ( -- )
   'EXPORTS BEGIN  @REL ?DUP WHILE  DUP CELL+ @ RVA ,  REPEAT ;

2VARIABLE >XDIR         \ RVA and length of export directory

: ,XDIR ( addr len -- )
   #EXPORTS 0= IF  0. >XDIR 2!  2DROP  EXIT  THEN
   2>R  HERE RVA
   0 , 0 , 0 ,                  \ export flags, timestamp, version info
   HERE  0 ,                    \ name rva
   1 ,                          \ ordinal base
   #EXPORTS DUP , ,             \ number in address and name pointer tables
   HERE 0 ,                     \ export address table rva
   HERE 0 ,                     \ name pointer rva
   HERE 0 ,                     \ ordinal table rva
   HERE RVA SWAP !  ,ORDINALS
   HERE RVA SWAP !  ,NAMES
   HERE RVA SWAP !  ,ADDRS
   HERE RVA SWAP !  2R> Z,
   HERE RVA OVER -  >XDIR 2! ;

{ --------------------------------------------------------------------
DLL entry and exit

BOOL WINAPI DllMain(
  __in  HINSTANCE hinstDLL,
  __in  DWORD fdwReason,
  __in  LPVOID lpvReserved
);

-------------------------------------------------------------------- }

[SWITCH DLL-STARTUP NOOP ( reason -- )
   DLL_PROCESS_ATTACH RUN:  /PE-IMPORTS  /IMPORTS  'ONDLLLOAD CALLS ;
   DLL_PROCESS_DETACH RUN:  'ONDLLEXIT CALLS ;
SWITCH]

:NONAME ( -- bool )
   MSG ['] DLL-STARTUP CATCH 0= 1 AND ;   3 CB: DLL-ENTRY

{ --------------------------------------------------------------------
Exported functions

RUNEXP is the runtime code for exported functions.  It instantiates a
Forth environment (stacks, user area, a tiny dictionary for HERE and
PAD), copies the calling parameters to the data stack and calls the
Forth word that followed the EXPORT: declaration.

EXPORT: takes the number of parameters and is followed by the name of
a word to export from the Forth DLL.  The "public" name of the
exported function need not be the same as the name of the Forth word.
Precede the call to EXPORT: with AS <name> to assign the expored
public name.
-------------------------------------------------------------------- }

LABEL RUNEXP
   8 [ESP] EAX LEA                      \ EAX points to parameters
   0 [ESP] EDX MOV                      \ Return addr in code compiled by EXPORT:

   EBX PUSH                             \ Save registers
   ESI PUSH
   EDI PUSH
   EBP PUSH

   -16 [ESP] EBP LEA                    \ start stack in open space
   $1000 # ESP SUB                      \ move return stack below
   8 [ESP] ESI LEA                      \ user area above stack
   ESP R0 [U] MOV                       \ save stack pointers in user area
   EBP S0 [U] MOV

   8 [EDX] ECX MOV   ECXNZ IF           \ number of parameters; skip copy if 0
      BEGIN   0 [EAX] EBX MOV
         4 # EAX ADD   PUSH(EBX)
      ECX DEC   0= UNTIL
   4 # EBP ADD   THEN

   |CB-USER| [ESI] EAX LEA              \ generate a new dictionary pointer
   EAX H [U] MOV                        \ and set into user area
   |CB-USER| $400 + [ESI] EAX LEA       \ top of dictionary =  here + 1k available
   EAX HLIM [U] MOV                     \ and top of dictionary

   $0A # BASE [U] MOV                   \ decimal
   0 # 'METHOD [U] MOV                  \ default method
   0 # STATE [U] MOV                    \ not compiling

   BEGIN 5 + DUP CALL   EDI POP         \ establish data space pointer in EDI
   ( *) -ORIGIN # EDI SUB

   4 [EDX] ECX MOV                      \ xt from EXPORT: structure
   EDI ECX ADD   ECX CALL               \ add base addr and call xt
   EBX EAX MOV                          \ return result

   S0 [U] ESP MOV                       \ restore
   16 # ESP ADD                         \ and negate the padding
   EBP POP                              \ restore registers
   EDI POP
   ESI POP
   EBX POP
   RET   END-CODE

PUBLIC

: EXPORT: ( n -- )  \ Usage: { AS <ExportName> }  n EXPORT: <word>
   HERE >R  RUNEXP ,CALL  ( nRET) $C2 C, DUP CELLS H,  ( Filler) 0 C,
   >AS @  ?DUP 0= IF  >IN @  THEN  ' ( xt) , SWAP ( n) ,  >IN @
   OVER >IN !  BL WORD COUNT ( a n) +EXPORTS  ( Ptr) R> ,
   SWAP >IN !  BL STRING  >IN ! ;

END-PACKAGE
