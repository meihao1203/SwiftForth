{ ====================================================================
Win32-specific preamble

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

==================================================================== }

{ ------------------------------------------------------------------------
Callback parameters

Windows passes parameters on the stack to the callback routine.

NTH_PARAM defines variables in the stack frame of the callback API
passed as indexed parameters on the stack below the return address.

These take standard formats for Windows callbacks, so we give the
first four of them the standard names HWND MSG WPARAM LPARAM.

We also name all of the first 8 in a generic fashion.  If more are
needed, it is easy to add them.
------------------------------------------------------------------------ }

#USER
    8 CELLS +USER WINMSG                \ bytes for GetMessage
      CELL  +USER 'WF                   \ the Windows stack frame pointer
    4 CELLS +USER WPARMS                \ dummy frame
( n ) TO #USER

PACKAGE WINDOWS-INTERFACE

WPARMS 'WF !                            \ set pointer for remainder of load

: NTH_PARAM ( n -- )
   ICODE
   [+ASM]
      4 # EBP SUB
      EBX 0 [EBP] MOV
      'WF [U] EBX MOV
      ( n) CELLS [EBX] EBX MOV
      RET END-CODE
   [-ASM] ;

PUBLIC

0 NTH_PARAM HWND
1 NTH_PARAM MSG
2 NTH_PARAM WPARAM
3 NTH_PARAM LPARAM

0 NTH_PARAM _PARAM_0
1 NTH_PARAM _PARAM_1
2 NTH_PARAM _PARAM_2
3 NTH_PARAM _PARAM_3
4 NTH_PARAM _PARAM_4
5 NTH_PARAM _PARAM_5
6 NTH_PARAM _PARAM_6
7 NTH_PARAM _PARAM_7

END-PACKAGE

{ --------------------------------------------------------------------
Windows message optimizations
-------------------------------------------------------------------- }

PACKAGE OPTIMIZING-COMPILER

: MSG-LIT-COMP ( -- )   [+ASM]
      PUSH(EBX)
      'WF [U] EAX MOV
      LASTLIT @ # 4 [EAX] CMP
      0 # EBX MOV
      HERE 3 + 1 RULEX
      EBX DEC
   [-ASM] ;

OPTIMIZE MSG LIT-COMPARE  WITH MSG-LIT-COMP

: MSG-LIT-COMP-IF ( -- )   [+ASM]
      'WF [U] EAX MOV
      LASTLIT @ # 4 [EAX] CMP
      HERE $400 + 2 RULEX
   [-ASM] ;

OPTIMIZE MSG-LIT-COMP (IF) WITH MSG-LIT-COMP-IF

END-PACKAGE
