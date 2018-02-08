{ ====================================================================
Gibbs' phenomenon -- George Kozlowski

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

OPTIONAL GIBBS Gibbs' phenomenon

{ --------------------------------------------------------------------
This version has a modeless dialog to change the number of terms in
the partial sum of the Fourier Series.  It does not require fpmath.f;
the floating point operations are defined in code and keep floats in
the chip until they are converted to integers on the Forth stack.

This builds on the HELLOWIN demo supplied with SwiftForth.
-------------------------------------------------------------------- }

ONLY FORTH ALSO DEFINITIONS DECIMAL

{ --------------------------------------------------------------------
GDI Windows functions
-------------------------------------------------------------------- }

LIBRARY GDI32

FUNCTION: MoveToEx ( hdc X Y lpPoint -- b )
FUNCTION: LineTo ( hdc nXEnd nYEnd -- b )
FUNCTION: Polyline ( hdc *lppt cPoints -- b )

{ --------------------------------------------------------------------
Window creation

This follows the generic template for Windows programs.
-------------------------------------------------------------------- }

CREATE AppName ,Z" SFAPP"

[SWITCH GIBBS-MESSAGES DEFWINPROC ( -- res )
\ other code added later
SWITCH]

:NONAME  MSG LOWORD GIBBS-MESSAGES ; 4 CB: WNDPROC

: MYWINDOW ( -- hwnd )
      0                                 \ extended style
      AppName                           \ window class name
      Z"  SwiftForth Window: Gibbs' Phenomenon" \ caption
      WS_OVERLAPPEDWINDOW               \ window style
      CW_USEDEFAULT                     \ initial x position
      CW_USEDEFAULT                     \ y
      CW_USEDEFAULT                     \ x size
      CW_USEDEFAULT                     \ y
      0                                 \ parent window handle
      0                                 \ window menu handle
      HINST                             \ program instance handle
      0                                 \ creation parameter
   CreateWindowEx ;

{ --------------------------------------------------------------------
Application-specific code here
---------------------------------------------------------------------- }

0 VALUE hwndGIBBS
0 VALUE SW-hDC
1000   CONSTANT NUM
NUM 1+ CONSTANT NUM'

VARIABLE TERMS
0 VALUE cxClient
0 VALUE cyClient

CREATE &ps 64 allot \ paintstruct
CREATE &pts NUM' 2* CELLS ALLOT

CODE fF0  ( NDP: -- r )
    FLDZ  RET END-CODE

CODE fFPI  ( NDP: -- r )
    FLDPI  RET  END-CODE

CODE fF*  ( NDP: r1 r2 -- r )
    FMULP  RET  END-CODE

CODE fF+  ( NDP: r1 r2 -- r )
    FADDP  RET  END-CODE

CODE fF/  ( NDP: r1 r2 -- r )
    fdivp  RET  END-CODE

CODE fFSIN  ( NDP: r -- r )
    fsin  RET  END-CODE

CODE fS>F  ( n -- ) ( N: -- r )
    0 [EBP] EBX XCHG  0 [EBP] DWORD FILD  4 # EBP ADD
    RET  END-CODE

CODE fF>S ( -- n) ( N: r -- )
   4 # EBP SUB  0 [EBP] DWORD FISTP  0 [EBP] EBX XCHG  RET  END-CODE

: <FCN>  ( n -- ) ( N: -- r )
    fF0
    1 TERMS @ 1 MAX
    DO
        DUP   ( the argument )
        I * fS>F  500 fS>F fF/ fFPI fF* fFSIN
        I DUP 1 AND 0= IF  NEGATE  THEN  fS>F fF/
        fF+
        -1
    +LOOP
    DROP ;

: FCN  ( n n' -- n")
    TUCK
    NEGATE
    fS>F
    <FCN>
    fF*
    4 fS>F fF/  \ 5
    fS>F 2 fS>F fF/ fF+
    fF>S
;

: PutPts  ( -- )
    NUM' 0
    DO
        i cxClient NUM */  i 2* CELLS &pts + !
        i cyClient FCN
        i 2* CELLS &pts + CELL+ !
    LOOP
;

[+SWITCH GIBBS-MESSAGES
   WM_SIZE           RUN:  LPARAM HILO TO cxClient  To cyClient 0 ;

   WM_PAINT          RUN:  HWND &ps BeginPaint  to SW-hDC
                           SW-hDC 0        cyClient 2 / NULL MoveToEx DROP
                           SW-hDC cxClient cyClient 2 / LineTo DROP
                           PutPts
                           SW-hDC &pts NUM' Polyline DROP
                           HWND &ps EndPaint
                           0  ;

   WM_DESTROY        RUN:  0 PostQuitMessage  ;
SWITCH]

{ ========================================================================
An example of a modeless dialog.
======================================================================== }

\ ----------------------------------------------------------------------------
\ ----- Modified to work with the new dialog layout
\ ----- 30-JUN-99 MDK
\ ----------------------------------------------------------------------------

DIALOG (FOURIER)
[MODELESS " Change number terms " 0 130 160 70
   (FONT 8, Fixedsys) ]
   [DEFPUSHBUTTON  " OK"               IDOK   130   20   20   15 ]
   [RTEXT                              101     05   05   18   10 ]
   [LTEXT          " = number of terms in partial sum "
                                       102     25   05  135   10 ]
   [PUSHBUTTON     " Add 1"            103     05   20   30   15 ]
   [PUSHBUTTON     " Add 10"           104     40   20   30   15 ]
   [PUSHBUTTON     " Add 50"           105     80   20   30   15 ]

   [PUSHBUTTON     " Sub 1"            106     05   40   30   15 ]
   [PUSHBUTTON     " Sub 10"           107     40   40   30   15 ]
   [PUSHBUTTON     " Sub 50"           108     80   40   30   15 ]
END-DIALOG


0 VALUE hDlgModeless
: FOURIER-DONE ( -- res )
   (FOURIER) CELL- OFF
   hDlgModeless DestroyWindow DROP
   0 TO hDlgModeless  ;

: FOURIER-ACTIVATE ( -- )
   WPARAM $FFFF AND IF hwndGIBBS ELSE 0 THEN DLGACTIVE ! ;

: .TERMS ( -- )
   HWND 101 TERMS @ 0 SetDlgItemInt DROP ;

: REDO  ( -- )
    hwndGIBBS DUP  0 1 InvalidateRect DROP
    UpdateWindow DROP  0 ;

: INCR  ( +n -- )
    TERMS +!  .TERMS  REDO  ;

: DECR  ( +n -- )
    TERMS DUP @ ROT - 1 MAX  SWAP !  .TERMS  REDO  ;

[SWITCH FOURIER-COMMANDS ZERO
   IDOK     RUN: ( -- res )   DROP FOURIER-DONE ;
   IDCANCEL RUN: ( -- res )   DROP FOURIER-DONE ;

   103      RUN: ( -- res )   1 INCR ;
   104      RUN: ( -- res )   10 INCR ;
   105      RUN: ( -- res )   50 INCR ;
   106      RUN: ( -- res )   1 DECR ;
   107      RUN: ( -- res )   10 DECR ;
   108      RUN: ( -- res )   50 DECR  ;
SWITCH]

[SWITCH Fourier-Messages ZERO
   WM_CLOSE      RUNS FOURIER-DONE
   WM_INITDIALOG RUN: ( -- res )   1 TERMS !  .TERMS  -1 ;
   WM_COMMAND    RUN: ( -- res )   WPARAM $FFFF AND FOURIER-COMMANDS ;
   WM_ACTIVATE   RUN: ( -- res )   FOURIER-ACTIVATE 0 ;
SWITCH]

:NONAME ( -- res )   MSG $FFFF AND Fourier-Messages ;  4 CB: RUNFOURIER

: FOURIER-DIALOG
   HINST (FOURIER)  hwndGIBBS RUNFOURIER 0
   CreateDialogIndirectParam TO hDlgModeless DUP
   (FOURIER) CELL- !
   hDlgModeless SW_SHOW ShowWindow DROP ;

\ *******************************************************************************

CREATE &MSG  ( -- addr )  7 CELLS ALLOT

: DLG-MSGLOOP  ( -- res )
    BEGIN
        &MSG 0 0 0 GetMessage
    WHILE
        hDlgModeless 0=
        hDlgModeless &MSG IsDialogMessage 0= OR
        IF
            &MSG TranslateMessage DROP
            &MSG DispatchMessage  DROP
        THEN
    REPEAT
        &MSG 2 CELLS + @ ( wparam) LOWORD ;

-? : GIBBS
    AppName WNDPROC DefaultClass DROP MYWINDOW TO hwndGIBBS
    hwndGIBBS DUP SW_SHOWDEFAULT ShowWindow DROP
    UpdateWindow DROP  FOURIER-DIALOG
    DLG-MSGLOOP DROP  ;

: WINMAIN ( -- )
   GIBBS 0 ExitProcess  ;

 ' WINMAIN  'MAIN !
 \ PROGRAM-SEALED GIBBS
 \ BYE

-1 THRESHOLD ( do not save xref)

CR
CR .( Gibbs' phenomenon --  George Kozlowski)
CR
CR .( Type GIBBS to run the demo.)
CR
