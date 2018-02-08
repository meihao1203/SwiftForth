{ ====================================================================
External library call for ObjC message sending

Copyright 2014 by FORTH, Inc.
Copyright (c) 2012-2017  Roelf Toxopeus

Part of the interface to ObjC 2 Runtime.
SwiftForth version.
The calling of ObjC methods is implemented here. This is specific to OS X.
Either use a fast caller adapted to each platform or use the portable
'reorder-stack' version.
Last: 24 February 2013 17:19:11 CET  -rt
==================================================================== }

{ --------------------------------------------------------------------
The message sending mechanism in ObjC uses external library functions.
When we call these we move the parameters from the Forth data stack
(pointed to by EPB) to the system stack (pointed to by ESP).  We call
the message sending external library functions using their addresses
via the OBJC-EXTERN-CALL or OBJC-EXTERN-CALL-STRET routines.
These routines handle the details of building the stack frame for the
external procedure call.

OBJC-EXTERN-CALL -- similar to EXTERN-CALL and based on it.
n is the number of parameters to pass, addr is either objc_msgSend
or objc_msgSendSuper.
The parameters in the stackframe should be positioned as follows:
data stack: x1 x2 .. xi obj sel   =>   stackframe: obj sel x1 x2 ... xi

OBJC-EXTERN-CALL-STRET -- similar to OBJC-EXTERN-CAL, but passing a
structure return pointer as well.
n is the number of parameters to pass, addr is either objc_msgSend_stret
or objc_msgSendSuper_stret.
The parameters in the stackframe should be positioned as follows:
data stack: x1 x2 .. xi stret obj sel   =>   stackframe: stret obj sel x1 x2 ... xi
-------------------------------------------------------------------- }

CODE OBJC-EXTERN-CALL ( x1 x2 .. xn obj sel n+2 addr -- x )
   EDI PUSH   ESI PUSH          \ save Forth VM context
   0 [EBP] ECX MOV              \ n args
   ESP EDX MOV                  \ save ESP before building stack frame
   $FFFFFFF0 # ESP AND          \ align SP to mod 16

\ *** differs from EXTERN-CALL, allways at least 2 items: obj sel   
   ECX EAX MOV   EAX NEG
   3 # EAX AND   EAX NEG
   0 [ESP] [EAX*4] ESP LEA

   2 # ECX SUB					\ start with possible method args
   ECXNZ IF                     \ skip if no args
\ *** prepare stack and count for moving arguments only
      EBP EAX MOV				\ save stack pointer for obj and sel later
      8 # EBP ADD				\ skip obj and sel
      BEGIN
         4 [EBP] PUSH           \ move args from data stack to system stack
         4 # EBP ADD
      LOOP
\ *** finish the stackframe and restore stack
      EBP ECX MOV				\ save stack pointer
      EAX EBP MOV				\ restore initial stack pointer
      4 [EBP] PUSH				\ finish building: selector
      8 [EBP] PUSH				\ then obj as last
      ECX EBP MOV				\ restore real stack pointer
   ELSE
\ *** no arguments, only obj and sel
      4 [EBP] PUSH				\ finish building: selector
      8 [EBP] PUSH				\ then obj as last
      8 # EBP ADD
   THEN

\ *** continue regular EXTERN-CALL   
   EDX 0 [EBP] MOV              \ preserve ESP for return
   EBX CALL                     \ call extern function
   EAX EBX MOV                  \ return value
   0 [EBP] ESP MOV              \ restore ESP
   4 # EBP ADD
   ESI POP   EDI POP            \ restore Forth VM
   RET   END-CODE

CODE OBJC-EXTERN-CALL-STRET ( x1 x2 .. xn-1 stretn obj sel n+2 a -- x )
   EDI PUSH   ESI PUSH          \ save Forth VM context
   0 [EBP] ECX MOV              \ n args
   ESP EDX MOV                  \ save ESP before building stack frame
   $FFFFFFF0 # ESP AND          \ align SP to mod 16

   3 # ECX SUB					\ start with possible method args
   ECXNZ IF                     \ skip if no args
\ *** prepare stack and count for moving arguments only
      EBP EAX MOV				\ save stack pointer for stret, obj and sel later
      12 # EBP ADD				\ skip stret, obj and sel
      BEGIN
         4 [EBP] PUSH           \ move args from data stack to system stack
         4 # EBP ADD
      LOOP
\ *** finish the stackframe and restore stack
      EBP ECX MOV				\ save stack pointer
      EAX EBP MOV				\ restore initial stack pointer
      4 [EBP] PUSH				\ finish building: selector
      8 [EBP] PUSH				\ then obj as last
      12 [EBP] PUSH				\ then structure pointer as last
      ECX EBP MOV				\ restore real stack pointer
   ELSE
\ *** no arguments, only stret, obj and sel
      4 [EBP] PUSH				\ finish building: selector
      8 [EBP] PUSH				\ then obj as last
      12 [EBP] PUSH				\ then structure pointer as last
      12 # EBP ADD
   THEN

\ *** continue regular EXTERN-CALL   
   EDX 0 [EBP] MOV              \ preserve ESP for return
   EBX CALL                     \ call extern function
   EAX EBX MOV                  \ return value
   0 [EBP] ESP MOV              \ restore ESP
   4 # EBP ADD
   ESI POP   EDI POP            \ restore Forth VM
   RET   END-CODE

\\ ( eof )