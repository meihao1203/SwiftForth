{ ====================================================================
Protect users from common errors

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL PROTECTION Check for common relocation errors during compilation

{ --------------------------------------------------------------------
WARNING mask is extended to include

        0000.0000.0000.0001 display warnings on console
        0000.0000.0000.0010 display warnings in message box
        0000.0000.0001.0000 non-uniqueness
        0000.0001.0000.0000 address warning for , (comma)
        0000.0010.0000.0000 address warning for CONSTANT
        0000.0100.0000.0000 address warning for ! (store)

: BOX.PROTECTED ( zaddr -- )
   HWND SWAP Z" Warning:" [(OR MB_OKCANCEL MB_ICONWARNING)] MessageBox
   IDCANCEL = -9900 ?THROW ;
-------------------------------------------------------------------- }

PACKAGE PROTECTION-LAYER

: BOX.PROTECTED ( zaddr -- )
   0 SWAP Z" Warning:" 49 MessageBox  2 = -9900 ?THROW ;

: (.PROTECTED) ( a buf -- )   >R   0 R@ !
   SOURCE-ID IF
      #TIB 2@ R@ ZAPPEND
      <EOL> COUNT R@ ZAPPEND
      <EOL> COUNT R@ ZAPPEND
   THEN
   S" WARNING: Possible non-relocatable data "  R@ ZAPPEND
   8 (H.0) R@ ZAPPEND
   SOURCE-ID IF
      <EOL> COUNT R@ ZAPPEND
      S" at line " R@ ZAPPEND  LINE @ (.) R@ ZAPPEND
      S"  in file " R@ ZAPPEND  INCLUDING R@ ZAPPEND
   THEN
   R> DROP ;

: .PROTECTED ( a -- )
   256 R-ALLOC >R   R@ (.PROTECTED)
   1 WARNS IF  CR R@ ZCOUNT BOUNDS ?DO I C@ EMIT LOOP CR  THEN
   2 WARNS IF  R@ BOX.PROTECTED  THEN
   R> DROP ;

: ?PROTECTED ( a mask -- )
   WARNING @ IF
      ( mask) WARNS IF
         DUP ORIGIN PAD WITHIN IF
            DUP .PROTECTED
         THEN
      THEN 0
   THEN 2DROP ;

{ ----------------------------------------------------------------------
We set the flag which is used by warncfg to enable the address warnings
section of the option dialog. This is a bit of global state which
is preserved only by saving a new image of the executable.
---------------------------------------------------------------------- }

ERROR-HANDLERS +ORDER

1 TO USING-PROTECTED-MEMORY

ERROR-HANDLERS -ORDER

{ --------------------------------------------------------------------
overload the original functions to check for memory range problems.
-------------------------------------------------------------------- }

PUBLIC

-? : , ( a -- )
   DUP $100 ?PROTECTED , ;

-? : CONSTANT ( n -- )
   DUP $200 ?PROTECTED CONSTANT ;

-? : ! ( n a -- )
   STATE @ IF ( compiling)
      POSTPONE ! EXIT
   THEN
   SOURCE=FILE IF
      OVER $400 ?PROTECTED
   THEN ! ; IMMEDIATE

END-PACKAGE
