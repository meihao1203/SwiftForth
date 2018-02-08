{ ====================================================================
Floating point package configuration utility

Copyright 2001  FORTH, Inc.

System defaults and registry access must always be loaded first.
==================================================================== }

OPTIONAL FPCONFIG Floating point math configuration utility

{ --------------------------------------------------------------------
FP options

'FPOPT-DEFAULT defines registry values to use the software stack, not
wait for exceptions, enable under/overflow, zero div, and invalid op
exceptions.  Precision Control set to 64 bits (Temporary Real).
Rounding uses truncation.  8 significant digits in a fixed
display format.

'FPOPT is the image of the registry key that is used at run time.
  The FPU control word field has this format:

Bits[15:13]     Reserved
Bit[12]         Infinity control
                0 = Both -infinity and +infinity are treated as unsigned infinity
                1 = Respects both -infinity and +infinity
Bits[11:10]     Rounding mode
                00 = Round to nearest, or to even if equidistant
                01 = Round down (toward -infinity)
                10 = Round up (toward +infinity)
                11 = Truncate (toward 0)
Bits[9:8]       Precision control
                00 = 24 bits (REAL4)
                01 = Not used
                10 = 53 bits (REAL8)
                11 = 64 bits (REAL10)
Bits[7:6]       Reserved
Bit [5]         Precision Mask
Bit [4]         Underflow Mask
Bit [3]         Overflow Mask
Bit [2]         Zero divide Mask
Bit [1]         Denormalized operand Mask
Bit [0]         Invalid operation Mask

Set mask bit to 1 to ignore corresponding exception.

FPOPT is the registry key used by this package.

READ-FPOPT reads the registry key.
WRITE-FPOPT writes the registry key.

VALIDATE-FPOPT makes sure that the registry key contains valid
entires.  If it does not, then the default values are used and
written to the registry.

-------------------------------------------------------------------- }

DECIMAL  ONLY FORTH ALSO DEFINITIONS

PACKAGE FP-CONFIG

PRIVATE

CREATE 'FPOPT-DEFAULT   HERE
    TRUE C,     \ Softare stack
    TRUE C,     \ WAIT for exceptions
    $F32 H,     \ FPU Control word
       8 C,     \ PRECISION significant digits (1-17)
    ," FIX"     \ FIX SCI or ENG output format

HERE SWAP - CONSTANT |FPOPT|

PUBLIC

CREATE 'FPOPT   |FPOPT| /ALLOT

PRIVATE

CONFIG: FPOPT ( -- a n )   'FPOPT |FPOPT| ;

: HASNT-FPOPT ( -- flag )   GETREGKEY >R
   PAD |FPOPT| Z" FPOPT" R@ READ-REG 0<> NIP
   R> RegCloseKey DROP ;

: READ-FPOPT ( -- )   GETREGKEY >R
   'FPOPT |FPOPT| Z" FPOPT" R@ READ-REG 2DROP
   R> RegCloseKey DROP ;

: WRITE-FPOPT ( -- )   GETREGKEY >R
   'FPOPT |FPOPT| Z" FPOPT" R@ WRITE-REG DROP
   R> RegCloseKey DROP ;

: VALIDATE-FPOPT ( -- )   READ-FPOPT
   'FPOPT COUNT DUP 0= SWAP 255 = OR IF
          COUNT DUP 0= SWAP 255 = OR IF
          COUNT $C0 AND 0= IF
          COUNT $E0 AND 0= IF
          COUNT 2 18 WITHIN IF
          COUNT 3 = IF  DROP  EXIT
   THEN  THEN  THEN  THEN  THEN  THEN
   'FPOPT-DEFAULT 'FPOPT |FPOPT| MOVE
   DROP  WRITE-FPOPT ;

{ [CONFIGURATION -----------------------------------------------------
The configuration dialog box support is only needed when the user asks
to change the default settings.  Otherwise, this code is not loaded.

-------------------------------------------------------------------- }

101 ENUM DI_APPLY
    ENUM DI_DFLT
    ENUM DI_HDW
    ENUM DI_SFT
    ENUM DI_WAIT
    ENUM DI_DIGTS
    ENUM DI_UPDN
    ENUM DI_ENG
    ENUM DI_SCI
    ENUM DI_FIX
    ENUM DI_64B
    ENUM DI_53B
    ENUM DI_24B
    ENUM DI_NEAR
    ENUM DI_DOWN
    ENUM DI_UP
    ENUM DI_TRNC
DROP

DIALOG (FPMATH-CONFIG)
   [MODAL  " Floating Point Options"
                   (FONT 8, MS Sans Serif)          10   10  205  160 ]

\  [control        " default text"        id      xpos ypos xsiz ysiz ]
   [DEFPUSHBUTTON  " OK"                  IDOK       5  140   45   15 ]
   [PUSHBUTTON     " Cancel"              IDCANCEL  55  140   45   15 ]
   [PUSHBUTTON     " &Apply"              DI_APPLY 105  140   45   15 ]
   [PUSHBUTTON     " &Defaults"           DI_DFLT  155  140   45   15 ]
   [GROUPBOX       " Stack"               -1         5    0  195   45 ]
   [AUTORADIOBUTTON " &Hardware"          DI_HDW    10   10   55   10 ]
   [AUTORADIOBUTTON " &Software"          DI_SFT    10   25   55   10 ]
   [CHECKBOX       " &WAIT on exceptions" DI_WAIT   85    8   95   10 ]
   [CTEXT          " FPMATH must be reloaded before"
                 "  changes in this group will become"
                            "  effective."
                                          -1        70   19  110   24 ]
   [GROUPBOX       " D&isplay Format"     -1         5   45  195   45 ]
   [EDITTEXT       (+STYLE ES_RIGHT)      DI_DIGTS  10   58   23   12 ]
   [UPDOWN                                DI_UPDN   21   58   10   12 ]
   [LTEXT           " Significant Digits" -1        34   59   68   10 ]
   [AUTORADIOBUTTON " &Engineering"       DI_ENG    10   75   65   10 ]
   [AUTORADIOBUTTON " S&cientific"        DI_SCI    80   75   55   10 ]
   [AUTORADIOBUTTON " &Fixed"             DI_FIX   145   75   40   10 ]
   [GROUPBOX        " Rounding Precision" -1         5   90  195   25 ]
   [AUTORADIOBUTTON " &64 bits"           DI_64B    10  100   45   10 ]
   [AUTORADIOBUTTON " &53 bits"           DI_53B    80  100   45   10 ]
   [AUTORADIOBUTTON " &24 bits"           DI_24B   145  100   45   10 ]
   [GROUPBOX        " Rounding Control"   -1         5  110  195   25 ]
   [AUTORADIOBUTTON " &Nearest"           DI_NEAR   10  120   45   10 ]
   [AUTORADIOBUTTON " D&own"              DI_DOWN   60  120   45   10 ]
   [AUTORADIOBUTTON " &Up"                DI_UP    105  120   35   10 ]
   [AUTORADIOBUTTON " &Truncate"          DI_TRNC  145  120   45   10 ]

END-DIALOG

CREATE 'FPOPT-TEMP      |FPOPT| /ALLOT

: FPMATH-CLOSE-DIALOG ( -- res )   HWND 0 EndDialog ;

: CHECK-APPLY ( -- )
   'FPOPT-TEMP |FPOPT| 'FPOPT OVER COMPARE
   HWND DI_APPLY GetDlgItem SWAP EnableWindow DROP
   'FPOPT-TEMP |FPOPT| 'FPOPT-DEFAULT OVER COMPARE
   HWND DI_DFLT GetDlgItem SWAP EnableWindow DROP ;

: CHECK-WAIT ( -- )   HWND DI_WAIT 'FPOPT-TEMP 1+ C@ IF
      BST_CHECKED  ELSE  BST_UNCHECKED
   THEN  CheckDlgButton DROP ;

: TOGGLE-CHECK-WAIT ( -- )   'FPOPT-TEMP 1+
   DUP C@ 0= SWAP C!  CHECK-WAIT ;

: STACK>BUTTON ( -- )   HWND DI_HDW DI_SFT 'FPOPT-TEMP C@ IF
      DI_SFT  ELSE  DI_HDW  THEN  CheckRadioButton DROP ;

: STACK<BUTTON ( -- )
   HWND DI_SFT IsDlgButtonChecked BST_CHECKED = 'FPOPT-TEMP C! ;

: DIGITS>EDIT ( -- )   HWND DI_UPDN GetDlgItem
   DUP UDM_SETRANGE 0 1 >H< 17 OR SendMessage DROP
   UDM_SETPOS 0 'FPOPT-TEMP 4 + C@ SendMessage DROP ;

: DIGITS<EDIT ( -- )   HWND DI_UPDN GetDlgItem
   UDM_GETPOS 0 0 SendMessage  DUP 1 18 WITHIN IF
      'FPOPT-TEMP 4 + C!  ELSE  DROP DIGITS>EDIT  THEN ;

: DISPLAY>BUTTON ( -- )   HWND DI_ENG DI_FIX 'FPOPT-TEMP 5 + COUNT
   2DUP S" ENG" COMPARE 0= IF  DI_ENG  ELSE
   2DUP S" SCI" COMPARE 0= IF  DI_SCI  ELSE  DI_FIX
   THEN  THEN  NIP NIP  CheckRadioButton DROP ;

: DISPLAY<BUTTON ( -- )
   HWND DI_ENG IsDlgButtonChecked BST_CHECKED = IF  S" ENG"  ELSE
   HWND DI_SCI IsDlgButtonChecked BST_CHECKED = IF  S" SCI"  ELSE
      S" FIX"  THEN  THEN  'FPOPT-TEMP 5 + PLACE ;

: PRECISION>BUTTON ( -- )   HWND DI_64B DI_24B 'FPOPT-TEMP 2+ H@
   8 RSHIFT 3 AND  CASE  0 OF  DI_24B  ENDOF  2 OF  DI_53B  ENDOF
      >R DI_64B R>  ENDCASE  CheckRadioButton DROP ;

: PRECISION<BUTTON ( -- )
   HWND DI_24B IsDlgButtonChecked BST_CHECKED = IF  0  ELSE
   HWND DI_53B IsDlgButtonChecked BST_CHECKED = IF  2  ELSE
      3  THEN  THEN  8 LSHIFT  'FPOPT-TEMP 2+ DUP H@
   3 8 LSHIFT INVERT AND ROT OR SWAP H! ;

: ROUNDING>BUTTON ( -- )   HWND DI_NEAR DI_TRNC 'FPOPT-TEMP 2+ H@
   10 RSHIFT 3 AND  CASE  0 OF  DI_NEAR  ENDOF  1 OF  DI_DOWN ENDOF
   2 OF  DI_UP  ENDOF  >R DI_TRNC R>  ENDCASE  CheckRadioButton DROP ;

: ROUNDING<BUTTON ( -- )
   HWND DI_NEAR IsDlgButtonChecked BST_CHECKED = IF  0  ELSE
   HWND DI_DOWN IsDlgButtonChecked BST_CHECKED = IF  1  ELSE
   HWND DI_UP   IsDlgButtonChecked BST_CHECKED = IF  2  ELSE
      3  THEN  THEN  THEN  10 LSHIFT  'FPOPT-TEMP 2+ DUP H@
   3 10 LSHIFT INVERT AND ROT OR SWAP H! ;

: FETCH-FPOPT ( -- )   CHECK-WAIT  STACK>BUTTON  DISPLAY>BUTTON
   DIGITS>EDIT  PRECISION>BUTTON  ROUNDING>BUTTON ;
: START-FPOPT ( -- )   'FPOPT 'FPOPT-TEMP |FPOPT| MOVE  FETCH-FPOPT ;

: DEFAULT-FPOPT ( -- )   'FPOPT-DEFAULT
   'FPOPT-TEMP |FPOPT| MOVE  FETCH-FPOPT ;

: UPDATE-FPOPT ( -- )   STACK<BUTTON  DISPLAY<BUTTON
   DIGITS<EDIT  PRECISION<BUTTON  ROUNDING<BUTTON
   'FPOPT-TEMP 'FPOPT |FPOPT| MOVE  WRITE-FPOPT
   CHECK-APPLY ;

[SWITCH FPMATH-COMMANDS ZERO ( -- res )
   IDOK     RUN:  UPDATE-FPOPT  FPMATH-CLOSE-DIALOG ;
   IDCANCEL RUN:  FPMATH-CLOSE-DIALOG ;
   DI_APPLY RUN:  UPDATE-FPOPT  0 ;
   DI_DFLT  RUN:  DEFAULT-FPOPT  CHECK-APPLY  0 ;
   DI_HDW   RUN:  STACK<BUTTON  CHECK-APPLY  0 ;
   DI_SFT   RUN:  STACK<BUTTON  CHECK-APPLY  0 ;
   DI_WAIT  RUN:  TOGGLE-CHECK-WAIT  CHECK-APPLY  0 ;
   DI_DIGTS RUN:  DIGITS<EDIT  CHECK-APPLY  0 ;
   DI_ENG   RUN:  DISPLAY<BUTTON  CHECK-APPLY  0 ;
   DI_SCI   RUN:  DISPLAY<BUTTON  CHECK-APPLY  0 ;
   DI_FIX   RUN:  DISPLAY<BUTTON  CHECK-APPLY  0 ;
   DI_64B   RUN:  PRECISION<BUTTON  CHECK-APPLY  0 ;
   DI_53B   RUN:  PRECISION<BUTTON  CHECK-APPLY  0 ;
   DI_24B   RUN:  PRECISION<BUTTON  CHECK-APPLY  0 ;
   DI_NEAR  RUN:  ROUNDING<BUTTON  CHECK-APPLY  0 ;
   DI_DOWN  RUN:  ROUNDING<BUTTON  CHECK-APPLY  0 ;
   DI_UP    RUN:  ROUNDING<BUTTON  CHECK-APPLY  0 ;
   DI_TRNC  RUN:  ROUNDING<BUTTON  CHECK-APPLY  0 ;
SWITCH]

[SWITCH FPMATH-MESSAGES ZERO
   WM_CLOSE      RUNS  FPMATH-CLOSE-DIALOG
   WM_INITDIALOG RUN:  READ-FPOPT  START-FPOPT  UPDATE-FPOPT  -1 ;
   WM_COMMAND    RUN:  WPARAM LOWORD FPMATH-COMMANDS ;
SWITCH]

:NONAME ( -- res )   MSG LOWORD FPMATH-MESSAGES ;  4 CB: RUN-FPMATH

: /MENU-FPOPT
   HWND GetMenu MI_FPOPTIONS MF_ENABLED EnableMenuItem DROP ;

PUBLIC

: FPMATH-CONFIG ( -- )
   HINST  (FPMATH-CONFIG)  HWND  RUN-FPMATH
   0 DialogBoxIndirectParam DROP ;


: /FPMATH ( -- )   FPMATH-CONFIG ;

HASNT-FPOPT VALIDATE-FPOPT [IF]  /FPMATH [THEN]

CONSOLE-WINDOW +ORDER

[+SWITCH SF-COMMANDS
   MI_FPOPTIONS     RUN:               /FPMATH 0 ;
SWITCH]

CONSOLE-WINDOW -ORDER

:ONENVLOAD   /MENU-FPOPT ;

/MENU-FPOPT

END-PACKAGE

{ --------------------------------------------------------------------
Testing
-------------------------------------------------------------------- }

EXISTS RELEASE-TESTING [IF]

/FPMATH

BYE  [THEN]
