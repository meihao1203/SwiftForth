{ ====================================================================
Common multitasking support

Copyright 2008 by FORTH, Inc.
Portions contributed by Andrew Haley.

==================================================================== }

PACKAGE TASKING

{ --------------------------------------------------------------------
Resource serialization

GRAB, GET, and RELEASE operate on facility variables.  Generally, the
pair GET and RELEASE would be used to serialize access to a facility
as documented in the SwiftForth Reference Manual.
-------------------------------------------------------------------- }

ICODE ?! ( addr prev new -- bool )
   0 [EBP] EAX MOV
   4 [EBP] EDX MOV
   LOCK  0 [EDX] EBX CMPXCHG
   0 # EBX MOV
   BL SETNZ
   8 # EBP ADD
   RET   END-CODE

PUBLIC

: GRAB ( addr -- )
   DUP @ STATUS <> IF
      BEGIN  DUP 0 STATUS ?! WHILE  PAUSE  REPEAT
   THEN DROP ;

: RELEASE ( addr -- )
   STATUS 0 ?!  DROP ;

: GET ( a -- )
   PAUSE GRAB ;

END-PACKAGE
