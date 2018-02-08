{ ====================================================================
External library call interface

Copyright 2008  FORTH, Inc.

External library functions are accessed through this interface.  There
are two steps to access an external function:

1. Open the library that contains the function.
2. Find the function within the library and instantiate a call to it.

Any library may be marked as optional, which means that if it is
missing at compile or turnkey initialization load time, we won't
complain about it.  However, if an imported function is called (not
referenced, but actually called at run time) that requires a missing
library in the turney, the program will abort.

The library names are stored in the single-strand wordlist LIBS.

The imported proc names are stored in the current wordlist in which
they are defined (like any Forth definition).  In order to instantiate
all of them as part of turnkey initialization, the IMPORTS chain ties
them all together.

LIBRARY parameter field:    | handle | flag |
FUNCTION: parameter field:  | proc addr | #params | ^lib |
GLOBAL: parameter field:    | doconstant | data addr | 0 | ^lib |
==================================================================== }

?( External library interface)

PACKAGE LIB-INTERFACE

{ --------------------------------------------------------------------
Import library functions

BAD-LIB and BAD-PROC are the vectored behaviors for missing library
and proc calls.  These are defined with DEFER so the application can
install a custom handler.  BAD-LIB takes the nfa of the LIBRARY word.
BAD-PROC takes the nfa of the imported word.

.LIBS prints the LIBS wordlist showing handles when loaded and the
required/optional flag setting.
-------------------------------------------------------------------- }

PUBLIC

DEFER BAD-LIB ( nfa -- )
DEFER BAD-PROC ( nfa --)

PRIVATE

: .LIB ( nfa -- )
   CR  DUP N>BODY 2@  8 H.0   IF ."  [REQUIRED]  "
   ELSE  ."  [OPTIONAL]  "  THEN   COUNT TYPE ;

PUBLIC

: .LIBS ( -- )
   LIBS WID> CELL+ BEGIN
      @REL ?DUP WHILE
      DUP L>NAME .LIB
   REPEAT ;

PRIVATE

{ --------------------------------------------------------------------
Optional libraries and functions

[OPTIONAL] clears the ?REQUIRED field for the next library or imported
function definition.

@REQUIRED retruns the current value of ?REQUIRED and resets it back to
its default (true).
-------------------------------------------------------------------- }

VARIABLE ?REQUIRED   TRUE ?REQUIRED !   \ Required?  Default=yes

: @REQUIRED ( -- flag )   ?REQUIRED @  TRUE ?REQUIRED ! ;

PUBLIC

: [OPTIONAL] ( -- )   FALSE ?REQUIRED ! ;

PRIVATE

{ --------------------------------------------------------------------
Loading libraries

OPEN-LIBS loads all unloaded (PFA=0) libraries in the LIBS wordlist.
Calls (OPEN-LIB) for each one.  If the open fails and the library is
required (2nd cell in its PFA is -1), then we stop and complain.
Otherwise, we just leave it with a 0 in the PFA in place of a handle.

LIB-LOADED? returns true if the named library is known and loaded.
-------------------------------------------------------------------- }

THROW#
   ENUM IOR_LIB_UNKNOWN
   ENUM IOR_LIB_UNKNOWNFN
TO THROW#

[+SWITCH (THROW) ( -- addr u )
   IOR_LIB_UNKNOWN RUN:  @ERRMSG ;
   IOR_LIB_UNKNOWNFN RUN:  @ERRMSG ;
SWITCH]

: (BAD-LIB)  ( nfa -- )
   DLERROR ?DUP IF  ZCOUNT ERRMSG PLACE  DROP
      ELSE  S" Error opening library " ERRMSG PLACE
   COUNT ERRMSG APPEND  THEN  -2 THROW ;

' (BAD-LIB) IS BAD-LIB

: (OPEN-LIB) ( nfa -- )
   DUP N>BODY                           \ nfa pfa
   DUP @ IF  2DROP EXIT  THEN           \ skip if already loaded (handle in PFA)
   OVER COUNT +ROOT  OVER + 0 SWAP C!   \ expand path if needed, null-terminate filename
   DLOPEN  ?DUP IF  SWAP !              \ found: put handle in pfa
      ELSE  CELL+ @ IF  BAD-LIB         \ not found: complain if required, otherwise skip
   THEN THEN DROP ;

PUBLIC

: OPEN-LIBS ( -- )
   LIBS WID> CELL+ BEGIN                \ link to LIBS wordlist
      @REL ?DUP WHILE                   \ done when link=0
      DUP L>NAME (OPEN-LIB)             \ pass nfa to (OPEN-LIB)
   REPEAT ;

: LIB-LOADED? ( c-addr u -- flag )
   LIBS SEARCH-WORDLIST DUP -EXIT       \ false if not in the LIBS list
   DROP >BODY @ 0<> ;                   \ true if there's a handle

: CLOSE-LIB ( c-addr u -- )
   LIBS SEARCH-WORDLIST -EXIT           \ Skip silently if not found
   >BODY @ DLCLOSE DROP ;               \ Get handle, close it

PRIVATE

{ --------------------------------------------------------------------
Declare libraries

LIBRARY creates a dictionary entry for the named library in the LIBS
wordlist (unless it's already there, in which case it does nothing).
The first cell of the PFA has the library's handle when it is loaded
(0 means not loaded) and the second cell is a flag (TRUE=required,
FALSE=optional).
-------------------------------------------------------------------- }

VARIABLE 'LIB   \ Relative pointer to "current" library

PUBLIC

: LIBRARY ( -- )
   BL WORD COUNT  2DUP LIBS SEARCH-WORDLIST IF
   >BODY 'LIB !REL  2DROP  EXIT  THEN
   LIBS (WID-CREATE) +SMUDGE  HERE 'LIB !REL
   0 , @REQUIRED ,  LAST @ (OPEN-LIB) -SMUDGE ;

PRIVATE

{ --------------------------------------------------------------------
Resolve extern proc calls

(BAD-PROC) displays an error message and throws an error code for a
function lookup that fails on turnkey initialization.

GET-PROC takes the address and length of the proc name string, makes
a temporary z-string, and does the lookup in the current library in
'LIB with DLSYM.

RESOLVE-PROCS is used on turnkey initializaiton to resolve all proc
calls in the IMPORTS chain.  OPEN-LIBS must be called first so that we
have the DL handles.  Any DL that doesn't have a handle is therefore
optional (otherwise, OPEN-LIBS would have aborted) and the proc call
is not resolved.
-------------------------------------------------------------------- }

: (BAD-PROC) ( nfa -- )
   S" Unresolved function " ERRMSG PLACE
   DUP COUNT ERRMSG APPEND
   S"  in library " ERRMSG APPEND
   N>BODY CELL+ @REL BODY> >NAME COUNT ERRMSG APPEND
   IOR_LIB_UNKNOWNFN THROW ;

' (BAD-PROC) IS BAD-PROC

: GET-PROC ( h addr u -- proc | 0 )
   R-BUF  R@ ZPLACE  R> DLSYM ;

: RESOLVE-PROCS ( -- )
   IMPORTS BEGIN                        \ link
      @REL ?DUP WHILE                   \ link
      DUP CELL+ @REL                    \ link nfa
      DUP N>BODY                        \ link nfa pfa
      DUP CELL+ CELL+ @REL              \ link nfa pfa lib
      ?DUP IF  @ ROT COUNT GET-PROC     \ link pfa proc
         ?DUP IF  OVER !  THEN DROP
   ELSE  2DROP  THEN  REPEAT ;

PRIVATE

{ --------------------------------------------------------------------
Imported functions list

Imported DL functions are directly executable as Forth words.  The
layout of each these words is like this:

   header | call *code | proc addr | DL rel ptr | *code callproc

If the proc takes a variable number of args:

   header | call varargs | proc addr | DL rel ptr | 0(1)ret

When uninitialized, the proc addr is NOPROC, so calling the word
results in a call to BAD-PROC.
------------------------------------------------------------------ }

: .IMPORT ( nfa -- )
   CR DUP NAME> >BODY @+ 8 H.R  SPACE SPACE
   CELL+ @REL BODY> >NAME COUNT 20 OVER - 1 MAX -ROT TYPE
   SPACES  COUNT TYPE ;

PUBLIC

: .IMPORTS ( -- )
   IMPORTS  BEGIN
      @REL ?DUP WHILE
      DUP CELL+ @REL .IMPORT
   REPEAT ;

PRIVATE

ICODE 2RET> ( -- d )            \ return EDX:EAX
   PUSH(EBX)   EDX EBX MOV
   RET   END-CODE

: NOPROC ( pfa -- )   CODE> >NAME BAD-PROC ;

: EXTCALL-R0 ( -- )   DOES> ( -- )   2@ EXTERN-CALL DROP ;
: EXTCALL-R1 ( -- )   DOES> ( -- x )  2@ EXTERN-CALL ;
: EXTCALL-R2 ( -- )   DOES> ( -- d )  2@ EXTERN-CALL 2RET> ;

: EXTCALL-VAR-R0 ( -- )   DOES> ( n -- )   @ EXTERN-CALL DROP ;
: EXTCALL-VAR-R1 ( -- )   DOES> ( n -- x )  @ EXTERN-CALL ;
: EXTCALL-VAR-R2 ( -- )   DOES> ( n -- d )  @ EXTERN-CALL 2RET> ;

DECOMPILER +ORDER

: .PROC ( -- )   ?WHERE  ." Proc: " I@ U.  ."  Params: " I@ DUP
   0< IF  DROP ." VAR "  ELSE  .  THEN  ?LIMIT ;

'EXTCALL ' .PROC DECODE,                \ xt from EXTCALL in the kernel
' EXTCALL-R0 5 + ' .PROC DECODE,        \ xts from variants of EXTCALL above
' EXTCALL-R1 5 + ' .PROC DECODE,
' EXTCALL-R2 5 + ' .PROC DECODE,
' EXTCALL-VAR-R0 5 + ' .PROC DECODE,
' EXTCALL-VAR-R1 5 + ' .PROC DECODE,
' EXTCALL-VAR-R2 5 + ' .PROC DECODE,

PREVIOUS

VARIABLE #RETURN

: _IMPORT: ( n -- )
   'LIB @REL DUP 0= ABORT" No library"          \ n lib
   >AS @ IF  -?  THEN                           \ Suppress redefine if importing with different Forth name
   CREATE +SMUDGE                               \ make dictionary header, but leave smudged until proc call is built
   @ ?DUP IF  LAST @ COUNT GET-PROC             \ if lib is present, look for proc name in it
      DUP 0=  @REQUIRED AND                     \ if not found, check if required
   ABORT" not in current library" THEN          \ complain if required function not found
   ?DUP 0= IF  ['] NOPROC >CODE  THEN
   ( proc) ,  DUP ( n) ,                        \ compile address of proc or NOPROC if unresolved
   ( lib) 'LIB @REL ,REL                        \ compile relative pointer to library
   #RETURN @  SWAP 0< IF
      CASE
         0 OF  EXTCALL-VAR-R0  ENDOF            \ varargs, no return
         1 OF  EXTCALL-VAR-R1  ENDOF            \ ... return single
         2 OF  EXTCALL-VAR-R2  ENDOF            \ ... return double
         1 ABORT" Illegal return count"
      ENDCASE
      ELSE
      CASE
         0 OF  EXTCALL-R0  ENDOF                \ n args, no return
         1 OF  EXTCALL-R1  ENDOF                \ ... return single
         2 OF  EXTCALL-R2  ENDOF                \ ... return double
         1 ABORT" Illegal return count"
      ENDCASE
   THEN
   IMPORTS >LINK  LAST @ ,REL                   \ add pointer to IMPORTS chain
   >AS @ 0= IF  -SMUDGE EXIT  THEN              \ ready to use, so unsmudge it
   >IN @  >AS @ >IN !                           \ import with different Forth name?
   LAST CELL+ CELL+ @ HEADER  ,JMP              \ if so, leave import name smudged and make AS header
   >IN ! 0 >AS ! ;

{ --------------------------------------------------------------------
Declare library function calls and global data

FUNCTION: defines calls in the current LIBRARY.  It parses the stack
comment for a mandatory -- and a mandatory ). Example:

   FUNCTION: malloc ( u -- addr )

If the function takes a variable number of arguments, use this format:

   FUNCTION: printf ( ... -- u )

Do not mix fixed and variable number args stack comments on the left
side.  The results will not be predictable.

If the right side of the stack comment is empty, there is no return
value on the data stack.

GLOBAL: defines a global data address in a library.  No stack comment
is required; always returns the address of the global data.
-------------------------------------------------------------------- }

PRIVATE

: PARAMETERS ( -- n )
   0 BEGIN
      TOKEN  2DUP S" ..." COMPARE IF  S" --" COMPARE
      ELSE  2DROP 2- -1 THEN  WHILE  1+  REPEAT
   0 BEGIN
      TOKEN  S" )" COMPARE WHILE 1+  REPEAT
   #RETURN ! ;

PUBLIC

: PARAMETERS() ( -- n )
   >IN @ >R  [CHAR] ( WORD DROP PARAMETERS  R> >IN ! ;

: FUNCTION: ( -- )
   PARAMETERS()  _IMPORT: ;

: GLOBAL: ( -- )
   'LIB @REL DUP 0= ABORT" No library"  \ lib
   CREATE +SMUDGE                       \ make dictionary header, but leave smudged until proc call is built
   @ LAST @ COUNT GET-PROC              \ look for name in lib
   DUP 0=  ABORT" not in current library"
   ( addr) , 0 ,                        \ addr from GET-PROC
   'LIB @REL ,REL                       \ compile relative pointer to library
   IMPORTS >LINK  LAST @ ,REL           \ add pointer to IMPORTS chain
   -SMUDGE                              \ ready to use, so unsmudge it
   DOES> ( -- x )   @ ;

PRIVATE

{ --------------------------------------------------------------------
Initialization

0PROCS zeros the vector field of all the imports in the system.
0LIBS writes 0 to the handles of all the DLs.
/EXTERNAL initializes the library and function calls chains.
-------------------------------------------------------------------- }

PRIVATE

: 0LIBS ( -- )   LIBS WID> CELL+  BEGIN @REL ?DUP WHILE
   DUP L>NAME N>BODY OFF  REPEAT ;

: 0PROCS ( -- )   IMPORTS BEGIN  @REL ?DUP WHILE
   ['] NOPROC >CODE  OVER CELL+ @REL N>BODY !  REPEAT ;

: /EXTERNAL ( -- )   0LIBS 0PROCS
   ['] OPEN-LIBS CATCH ?DUP IF  EXITSTATUS !  @ERRMSG .BYE  THEN
   ['] RESOLVE-PROCS CATCH ?DUP IF  EXITSTATUS !  @ERRMSG .BYE  THEN ;

\ ' /EXTERNAL IS /IMPORTS       \ Assign extended behavior to kernel start-up

END-PACKAGE
