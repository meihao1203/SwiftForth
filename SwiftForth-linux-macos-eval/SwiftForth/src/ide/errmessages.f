{ ====================================================================
Throw and ior code error messages

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

Extended throw code and ior processing are supplied here.
==================================================================== }

?( Error messages)

: FUMBLED ( code -- addr n )
   S" Catch = " ERRMSG PLACE
   BASE @ >R DECIMAL  (.) ERRMSG APPEND
   R> BASE !  @ERRMSG ;

[SWITCH (THROW) FUMBLED ( code -- addr n )
       -1 RUN: HERE 0 ;                         \ ABORT
       -2 RUN: @ERRMSG ;                        \ ABORT"
       -3 RUN: S" Stack overflow" ;
       -4 RUN: S" Stack underflow" ;
       -5 RUN: S" Return stack overflow" ;
       -6 RUN: S" Return stack underflow" ;
       -7 RUN: S" Do-loops nested too deeply during execution" ;
       -8 RUN: S" Dictionary overflow" ;
       -9 RUN: S" Invalid memory address" ;
      -10 RUN: S" Division by zero" ;
      -11 RUN: S" Result out of range" ;
      -12 RUN: S" Argument type mismatch" ;
      -13 RUN: S"  ?" 'WHAT APPEND  'WHAT COUNT ;
      -14 RUN: S" Interpreting a compile-only word" ;
      -15 RUN: S" Invalid FORGET" ;
      -16 RUN: S" Attempt to use zero-length string as a name" ;
      -17 RUN: S" Pictured numeric output string overflow" ;
      -18 RUN: S" Parsed string overflow" ;
      -19 RUN: S" Definition name too long" ;
      -20 RUN: S" Write to a read-only location" ;
      -21 RUN: S" Unsupported operation" ;
      -22 RUN: S" Control structure mismatch" ;
      -23 RUN: S" Address alignment exception" ;
      -24 RUN: S" Invalid numeric argument" ;
      -25 RUN: S" Return stack imbalance" ;
      -26 RUN: S" Loop parameters unavailable" ;
      -27 RUN: S" Invalid recursion" ;
      -28 RUN: S" User interrupt" ;
      -29 RUN: S" Compiler nesting" ;
      -30 RUN: S" Obsolescent feature" ;
      -31 RUN: S" >BODY used on non-CREATEd definition" ;
      -32 RUN: S" Invalid name argument (e.g., TO xxx)" ;
      -33 RUN: S" Block read exception" ;
      -34 RUN: S" Block write exception" ;
      -35 RUN: S" Invalid block number" ;
      -36 RUN: S" Invalid file position" ;
      -37 RUN: S" File I/O exception" ;
      -38 RUN: S" File not found" ;
      -39 RUN: S" Unexpected end of file" ;
      -40 RUN: S" Invalid BASE for floating point conversion" ;
      -41 RUN: S" Loss of precision" ;
      -42 RUN: S" Floating-point divide by zero" ;
      -43 RUN: S" Floating-point result out of range" ;
      -44 RUN: S" Floating-point stack overflow" ;
      -45 RUN: S" Floating-point stack underflow" ;
      -46 RUN: S" Floating-point invalid argument" ;
      -47 RUN: S" Compilation wordlist deleted" ;
      -48 RUN: S" Invalid POSTPONE" ;
      -49 RUN: S" Search-order overflow" ;
      -50 RUN: S" Search-order underflow" ;
      -51 RUN: S" Compilation wordlist changed" ;
      -52 RUN: S" Control-flow stack overflow" ;
      -53 RUN: S" Exception stack overflow" ;
      -54 RUN: S" Floating-point underflow" ;
      -55 RUN: S" Floating-point unidentified fault" ;
      -56 RUN: S" QUIT" ;
      -57 RUN: S" Exception in sending or receiving a character" ;
      -58 RUN: S" [IF], [ELSE], or [THEN] exception" ;

      -80 RUN: S" Dictionary full" ;
      -99 RUN: S" PANIC stop during include" ;
     -100 RUN: S" ALLOCATE failed" ;
     -101 RUN: S" RESIZE failed" ;
     -102 RUN: S" FREE failed" ;

     -191 RUN: S" Can't delete file" ;          \ DELETE-FILE
     -192 RUN: S" Can't rename file" ;          \ RENAME-FILE
     -193 RUN: S" Can't resize file" ;          \ RESIZE-FILE
     -194 RUN: S" Can't flush file" ;           \ FLUSH-FILE
     -195 RUN: S" Can't read file" ;            \ READ-FILE, READ-LINE
     -196 RUN: S" Can't write file" ;           \ WRITE-FILE
     -197 RUN: S" Can't close file" ;           \ CLOSE-FILE
     -198 RUN: S" Can't create file" ;          \ CREATE-FILE
     -199 RUN: S" Can't open file" ;            \ OPEN-FILE, INCLUDE-FILE

SWITCH]

: ERRORMSG ( n -- )   (THROW) TYPE ;
' ERRORMSG IS .CATCH

{ --------------------------------------------------------------------
Make simple additions to the throw code list

The syntax of the adder is

ior S" String to report"  >THROW  ENUM name

and note that the IOR is left on the stack for use by ENUM
-------------------------------------------------------------------- }

: >THROW ( ior a n -- ior )
   2>R  :NONAME  2R> POSTPONE SLITERAL  POSTPONE ;  ( ior xt)
   ['] (THROW) >BODY >LINK OVER , , ;

-99999 VALUE THROW#

THROW#
   S" Unresolved defer"     >THROW ENUM IOR_UNRESOLVED
   S" Compile only"         >THROW ENUM IOR_COMPILEONLY
   S" Unbalanced structure" >THROW ENUM IOR_UNBALANCED
   S" Loader image wrong"   >THROW ENUM IOR_BADLOADER
   S" Break"                >THROW ENUM IOR_BREAK
   S" RegisterClass failed" >THROW ENUM IOR_REGISTERCLASS
TO THROW#
