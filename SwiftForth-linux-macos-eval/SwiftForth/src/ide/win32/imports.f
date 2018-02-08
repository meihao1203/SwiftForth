{ ====================================================================
External library call interface

Copyright (C) 2001 FORTH, Inc.  All rights reserved.

External library functions are accessed through this interface.  There
are two steps to access an external function:

1. Open the library that contains the function.
2. Find the function within the library and instantiate a call to it.

Any library may be marked as optional, which means that if it is
missing at compile or turnkey initialization load time, we won't
complain about it.  However, if an imported function is called (not
referenced, but actually called at run time) that requires a missing
library in the turnkey, the program will abort.

The library names are stored in the single-strand wordlist LIBS.

The imported proc names are stored in the current wordlist in which
they are defined (like any Forth definition).  In order to instantiate
all of them as part of turnkey initialization, the IMPORTS chain ties
them all together.

LIBRARY parameter field:  | handle | flag |
FUNCTION: parameter field:  | proc addr | #params | ^lib |
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
   CR  DUP N>BODY 2@  H.8   IF ."  [REQUIRED]  "
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
   S" Error opening library"   >THROW ENUM IOR_LIB_UNKNOWN
   S" Error importing function"  >THROW ENUM IOR_LIB_UNKNOWNFN
TO THROW#

: (BAD-LIB-BOX)  ( nfa -- )
   256 R-ALLOC >R  S" The required library " R@ ZPLACE
   COUNT R@ ZAPPEND  S"  was not found." R@ ZAPPEND
   0 R> Z" Missing library" 0 MessageBox DROP
   IOR_LIB_UNKNOWN THROW ;

: (BAD-LIB)  ( nfa -- )
   S" Error opening library " ERRMSG PLACE
   COUNT ERRMSG APPEND  -2 THROW ;

' (BAD-LIB) IS BAD-LIB

: (OPEN-LIB) ( nfa -- )
   DUP N>BODY                           \ nfa pfa
   DUP @ IF  2DROP EXIT  THEN           \ skip if already loaded (handle in PFA)
   OVER COUNT +ROOT  OVER + 0 SWAP C!   \ expand path if needed, null-terminate filename
   LoadLibrary  ?DUP IF  SWAP !         \ found: put handle in pfa
      ELSE  CELL+ @ IF  BAD-LIB         \ not found: complain if required, otherwise skip
   THEN THEN DROP ;

PUBLIC

: OPEN-LIBS ( -- )
   ['] (BAD-LIB-BOX) IS BAD-LIB         \ use msgbox from turnkey startup
   LIBS WID> CELL+ BEGIN                \ link to LIBS wordlist
      @REL ?DUP WHILE                   \ done when link=0
      DUP L>NAME (OPEN-LIB)             \ pass nfa to (OPEN-LIB)
   REPEAT
   ['] (BAD-LIB) IS BAD-LIB ;           \ default to command-line error

: LIB-LOADED? ( c-addr u -- flag )
   LIBS SEARCH-WORDLIST DUP -EXIT       \ false if not in the LIBS list
   DROP >BODY @ 0<> ;                   \ true if there's a handle

: CLOSE-LIB ( c-addr u -- )
   LIBS SEARCH-WORDLIST -EXIT           \ Skip silently if not found
   >BODY @ FreeLibrary DROP ;           \ Get handle, close it

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

FIND-PROC looks for an export in all the known DLLs.  If found,
returns PFA of LIBRARY word, proc address to call, and true.  Othwise
returns 0 0 (for handle and addr) and false.

GET-PROC looks for a function when the DLL is already known.

FUNCTION-EXISTS? returns true if the next name in the input stream can
any library in the LIBS list.

(BAD-PROC) displays an error message and throws an error code for a
function lookup that fails on turnkey initialization.

RESOLVE-PROCS is used on turnkey initializaiton to resolve all proc
calls in the IMPORTS chain.  OPEN-LIBS must be called first so that we
have the DL handles.  Any DL that doesn't have a handle is therefore
optional (otherwise, OPEN-LIBS would have aborted) and the proc call
is not resolved.
-------------------------------------------------------------------- }

: FIND-PROC ( addr u -- 0 0 0 | lib addr -1 )
   R-BUF  R@ ZPLACE
   LIBS WID> CELL+ BEGIN ( z-addr link)
      @REL ?DUP WHILE ( link)
         DUP L>NAME N>BODY DUP @                \ link pfa(lib)
         ?DUP IF  R@ GetProcAddressX            \ link pfa addr
         ?DUP IF  ROT R> 2DROP -1  EXIT         \ found: lib addr -1
      THEN THEN DROP REPEAT
   R> DROP  0 0 0 ;                             \ not found

: GET-PROC ( lib addr u -- proc | 0 )
   R-BUF  R@ ZPLACE  R> GetProcAddressX ;

PUBLIC

: FUNCTION-EXISTS? ( _name -- flag )
   BL WORD COUNT FIND-PROC NIP NIP ;

PRIVATE

: (BAD-PROC) ( nfa -- )   R-BUF
   S" Can't find function " R@ ZPLACE
   DUP COUNT R@ ZAPPEND  N>BODY CELL+ CELL+ @REL
   ?DUP IF  S"  in library " R@ ZAPPEND  BODY> >NAME COUNT
   ELSE  S"  in any known library"  THEN  R@ ZAPPEND
   0 R> Z" Missing DLL Function" 0 MessageBox
   IOR_LIB_UNKNOWNFN THROW ;

' (BAD-PROC) IS BAD-PROC

PUBLIC

: RESOLVE-PROCS ( -- )
   IMPORTS BEGIN                        \ link
      @REL ?DUP WHILE                   \ link
      DUP CELL+ @REL                    \ link nfa
      DUP N>BODY                        \ link nfa pfa
      DUP CELL+ CELL+ @REL              \ link nfa pfa lib
      ?DUP IF  @ ROT COUNT GET-PROC     \ link pfa proc
         ?DUP IF  OVER !  THEN DROP     \ store addr|FUNCTION: in pfa of proc call
   ELSE  2DROP  THEN  REPEAT ;          \ skip if not there

PRIVATE

{ --------------------------------------------------------------------
Imported functions list

?DEFINED returns true if the next name parsed from the input stream is
already found in the given wordlist.  This is used both in LIBRARY
defining and later for defining the API calls themselves.  If not
found, >IN is moved back for a subsequent call to CREATE.

Imported library functions are directly executable as Forth words with
this PFA layout:

   | proc addr | #params | ^lib |

When uninitialized, the proc addr is 0, and calling the word results
in a call to BAD-PROC, which displays a diagnostic error in a message
box and aborts.
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

: (NOPROC) ( pfa -- )   BODY> >NAME BAD-PROC ;
: EXTCALL ( -- )   DOES> ( -- x )   DUP @ IF  2@ EXTERN-CALL  EXIT  THEN  (NOPROC) ;
: EXTCALL-NR ( -- )   DOES> ( -- )   DUP @ IF  2@ EXTERN-CALL DROP EXIT  THEN  (NOPROC) ;

DECOMPILER +ORDER

: .PROC ( -- )   ?WHERE  ." Proc: " I@ U. ."  Params: " I@ .  ?LIMIT ;

'EXTCALL ' .PROC DECODE,        \ xt from EXTCALL in the kernel
' EXTCALL 5 + ' .PROC DECODE,   \ xt from the two variants of EXTCALL above
' EXTCALL-NR 5 + ' .PROC DECODE,

PREVIOUS

VARIABLE ?RETURN

: ?DEFINED ( wid -- flag )
   >IN @ >R  BL WORD COUNT  ROT SEARCH-WORDLIST
   DUP IF  NIP R> DROP  ELSE  R> >IN !  THEN ;

: _IMPORT: ( n -- )
   >AS @ IF  -?  ELSE  CURRENT @ ?DEFINED IF    \ Suppress redefine if importing with different Forth name
   DROP EXIT  THEN THEN                         \ Skip if already defined and not making alternate name
   CREATE +SMUDGE                               \ make dictionary header, but leave smudged until proc call is built
   LAST @ COUNT FIND-PROC                       \ if lib is present, look for proc name in it
   NOT @REQUIRED AND                            \ if not found, check if required
   ABORT" not in any open library"              \ complain if required function not found
   ( proc) , SWAP ( n) ,                        \ compile address of proc or 0 if unresolved
   ( lib) ,REL                                  \ compile relative pointer to library
   ?RETURN @ IF  EXTCALL  ELSE  EXTCALL-NR  THEN
   IMPORTS >LINK  LAST @ ,REL                   \ add pointer to IMPORTS chain
   >AS @ 0= IF  -SMUDGE EXIT  THEN              \ ready to use, so unsmudge it
   >IN @  >AS @ >IN !                           \ import with different Forth name?
   LAST CELL+ CELL+ @ HEADER  ,JMP              \ if so, leave import name smudged and make AS header
   >IN ! 0 >AS ! ;

{ --------------------------------------------------------------------
Declare library function calls

FUNCTION: defines calls in the current LIBRARY.  It parses the stack
comment for a mandatory -- and a mandatory ). Example:

   FUNCTION: MessageBoxA ( hwnd ztext zbody flags -- res )

If the right side of the stack comment is empty, there is no return
value on the data stack.
-------------------------------------------------------------------- }

: PARAMETERS ( -- n )
   0 BEGIN  TOKEN  S" --" COMPARE WHILE  1+  REPEAT
   0 BEGIN  TOKEN  S" )" COMPARE WHILE 1+  REPEAT
   ?RETURN ! ;

PUBLIC

: PARAMETERS() ( -- n )
   >IN @ >R  [CHAR] ( WORD DROP PARAMETERS  R> >IN ! ;

: FUNCTION: ( "name" -- )
   PARAMETERS()  _IMPORT: ;

{ --------------------------------------------------------------------
Compatibility

These words are obsolescent and their use is deprecated.  They will
eventually be removed.
-------------------------------------------------------------------- }

: CFUNCTION: ( "name" -- )   FUNCTION: ;
: IMPORT: ( n "name" -- )   ?RETURN ON  _IMPORT: ;
: CIMPORT: ( n "name" -- )   IMPORT: ;

{ --------------------------------------------------------------------
Clear DLL structures

0PROCS zeros the vector field of all the imports in the system.
0LIBS writes 0 to the handles of all the libraries.
-------------------------------------------------------------------- }

PRIVATE

: 0LIBS ( -- )   LIBS WID> CELL+  BEGIN @REL ?DUP WHILE
   0 OVER L>NAME N>BODY !  REPEAT ;

: 0PROCS ( -- )   IMPORTS BEGIN  @REL ?DUP WHILE
   0 OVER CELL+ @REL N>BODY !  REPEAT ;

END-PACKAGE
