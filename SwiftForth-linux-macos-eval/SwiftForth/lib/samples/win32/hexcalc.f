{ ====================================================================
HexCalc

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

{ --------------------------------------------------------------------
This sample demonstrates 1) instantiation of a dialog box with a user
specified class and 2) the "creative" use of dialog control
identifiers to simplify the implementation of the dialog handler.

The technique of dialog instantiation presented here can be used to
build standalone applications or to build dialogs that do not require
the IsDialogMessage test in the message loop.  The requirement to test
IsDialogMessage makes building a dialog in a .DLL difficult, as one
cannot predict where the .DLL will be called from, nor can one judge
whether or not IsDialogMessage will be properly called by the message
loop of the application calling the .DLL .
-------------------------------------------------------------------- }

OPTIONAL HEXCALC A simple RPN hex calculator, implemented as a class-instantiated dialog

ONLY FORTH  ALSO DEFINITIONS  DECIMAL  EMPTY

{ --------------------------------------------------------------------
The name, message switch, callback, and class for the dialog.
Note that you must declare DLGWINDOWEXTRA in the window extra field.
-------------------------------------------------------------------- }

CREATE AppName ,Z" HexCalc"

[SWITCH HEXCALC-MESSAGES DEFWINPROC ( -- res )  SWITCH]

:NONAME  MSG LOWORD HEXCALC-MESSAGES ; 4 CB: RUNCALC

: /HEXCALC-CLASS ( -- hclass )
      0 CS_OWNDC   OR
        CS_HREDRAW OR
        CS_VREDRAW OR                \ class style
      RUNCALC                        \ wndproc
      0                              \ class extra
      DLGWINDOWEXTRA                 \ window extra
      HINST                          \ hinstance
      HINST 101 LoadIcon             \ icon
      NULL IDC_ARROW LoadCursor      \ cursor
      COLOR_BTNFACE 1+               \ background brush
      0                              \ no menu
      AppName                        \ class name
   DefineClass ;

{ --------------------------------------------------------------------
The calculator dialog box is defined just like a standard dialog box,
with controls and styles etc. The only exception is that instead of
using [DIALOG , the class name and [WINDOW are used instead. Each
button in the dialog is cleverly assigned a dialog ID corresponding
to the ascii value of the key it represents. This allows the message
handler to vector WM_CHAR messages directly to the buttons, which
makes a very nice user interface.

HCALC is the handle of the instantiated dialog/window. We use this to
keep track of the open window so we don't open it more than once, and
so we can force it closed on an EMPTY operation.

HEXCALC creates the dialog/window and shows it. It is assumed to
return to an environment which already has a message loop running.

The :PRUNE behavour closes the dialog if it is open and unregisters
the class. If this is not done, recompiling will very likely over-
write the registered callback address and cause the process to crash.
-------------------------------------------------------------------- }

DIALOG (HEXCALC)
   [MODELESS " Hex Calculator"       0   0 102 122
                (CLASS HexCalc) (FONT 9, FIXEDSYS) ]

   [PUSHBUTTON " D"         CHAR D   8  24  15  15 ]
   [PUSHBUTTON " A"         CHAR A   8  40  15  15 ]
   [PUSHBUTTON " 7"         CHAR 7   8  56  15  15 ]
   [PUSHBUTTON " 4"         CHAR 4   8  72  15  15 ]
   [PUSHBUTTON " 1"         CHAR 1   8  88  15  15 ]
   [PUSHBUTTON " 0"         CHAR 0   8 104  15  15 ]
   [PUSHBUTTON " 0 "        CTRL [  26   4  50  15 (+STYLE BS_RIGHT) ]
   [PUSHBUTTON " E"         CHAR E  26  24  15  15 ]
   [PUSHBUTTON " B"         CHAR B  26  40  15  15 ]
   [PUSHBUTTON " 8"         CHAR 8  26  56  15  15 ]
   [PUSHBUTTON " 5"         CHAR 5  26  72  15  15 ]
   [PUSHBUTTON " 2"         CHAR 2  26  88  15  15 ]
   [PUSHBUTTON " Back"      CTRL H  26 104  33  15 ]
   [PUSHBUTTON " C"         CHAR C  44  40  15  15 ]
   [PUSHBUTTON " F"         CHAR F  44  24  15  15 ]
   [PUSHBUTTON " 9"         CHAR 9  44  56  15  15 ]
   [PUSHBUTTON " 6"         CHAR 6  44  72  15  15 ]
   [PUSHBUTTON " 3"         CHAR 3  44  88  15  15 ]
   [PUSHBUTTON " +"         CHAR +  62  24  15  15 ]
   [PUSHBUTTON " -"         CHAR -  62  40  15  15 ]
   [PUSHBUTTON " *"         CHAR *  62  56  15  15 ]
   [PUSHBUTTON " /"         CHAR /  62  72  15  15 ]
   [PUSHBUTTON " mod"       CHAR %  62  88  15  15 ]
   [PUSHBUTTON " Enter"     CTRL M  62 104  33  15 ]
   [PUSHBUTTON " and"       CHAR &  80  24  15  15 ]
   [PUSHBUTTON " or"        CHAR |  80  40  15  15 ]
   [PUSHBUTTON " xor"       CHAR ^  80  56  15  15 ]
   [PUSHBUTTON " <<"        CHAR <  80  72  15  15 ]
   [PUSHBUTTON " >>"        CHAR >  80  88  15  15 ]
END-DIALOG

0 VALUE HCALC

: HEXCALC
   HCALC ?EXIT
   /HEXCALC-CLASS DROP
   HINST (HEXCALC) 0 RUNCALC 0 CreateDialogIndirectParam
   DUP TO HCALC DUP SW_SHOWDEFAULT ShowWindow DROP
   UpdateWindow DROP ;

:PRUNE
   HCALC IF HCALC WM_CLOSE 0 0 SendMessage DROP  THEN
   AppName HINST UnregisterClass DROP ;

{ --------------------------------------------------------------------
The RPN calculator is implemented with a short stack; four items plus
a temporary accumulator register.  T is top of stack, ACC is the
accumulator, which is where numbers are collected.

NEW-ACC is a flag indicating that the ACC register should be re-initialized
on the next numeric button pressed.

TOS displays the indicated quantity in hexadecimal.

ENTER pushes the accumulator into T and sets NEW-ACC.

POP pushes the accumulator and executes the binary operator XT on
parameters X and T.  The result is returned in T.

BUTTONS is the switch for button presses. The default is to do nothing.
-------------------------------------------------------------------- }

0 VALUE Z
0 VALUE Y
0 VALUE X
0 VALUE T

0 VALUE ACC
0 VALUE NEW-ACC

: TOS ( n -- )    HEX 0 (D.) PAD ZPLACE  S"  " PAD ZAPPEND
   HWND VK_ESCAPE PAD  SetDlgItemText DROP ;

: ENTER
   Y TO Z  X TO Y  T TO X  ACC TO T  T TOS  1 TO NEW-ACC ;

: POP ( xt -- )
   ENTER  X T ROT EXECUTE TO T  Y TO X  Z TO Y  T TOS ;

[SWITCH BUTTONS DROP ( char -- ) SWITCH]

{ --------------------------------------------------------------------
DIV and REM are zero-protected divide operators, returning unsigned
infinity if asked to divide by zero.

BS deletes the least significant digit of the accumulator.

The extension of BUTTONS deals with the binary operators and the
ENTER and BACK buttons.
-------------------------------------------------------------------- }

: DIV ( x t -- )   ?DUP IF / EXIT THEN DROP -1 ;
: REM ( x t -- )   ?DUP IF MOD EXIT THEN DROP -1 ;

: BS ( -- )
   NEW-ACC IF 0 TO ACC 0 TO NEW-ACC THEN
   ACC 4 RSHIFT OR TO ACC ACC TOS ;

[+SWITCH BUTTONS ( char -- )
   CHAR + RUN: ['] + POP ;
   CHAR - RUN: ['] - POP ;
   CHAR * RUN: ['] * POP ;
   CHAR | RUN: ['] OR POP ;
   CHAR & RUN: ['] AND POP ;
   CHAR ^ RUN: ['] XOR POP ;
   CHAR / RUN: ['] DIV POP ;
   CHAR % RUN: ['] REM POP ;
   CHAR < RUN: ['] LSHIFT POP ;
   CHAR > RUN: ['] RSHIFT POP ;
   CTRL M RUN: ENTER ;
   CTRL H RUN: BS ;
SWITCH]

{ --------------------------------------------------------------------
DIG accumulates digits and updates the display.

The switch extension defines what value to push for each numeric button.
-------------------------------------------------------------------- }

: DIG ( n -- )
   NEW-ACC IF 0 TO ACC 0 TO NEW-ACC THEN
   ACC $F0000000 AND IF EXIT THEN
   ACC 4 LSHIFT OR TO ACC  ACC TOS ;

[+SWITCH BUTTONS ( char -- )
   CHAR 0 RUN: $0 DIG ;
   CHAR 1 RUN: $1 DIG ;
   CHAR 2 RUN: $2 DIG ;
   CHAR 3 RUN: $3 DIG ;
   CHAR 4 RUN: $4 DIG ;
   CHAR 5 RUN: $5 DIG ;
   CHAR 6 RUN: $6 DIG ;
   CHAR 7 RUN: $7 DIG ;
   CHAR 8 RUN: $8 DIG ;
   CHAR 9 RUN: $9 DIG ;
   CHAR A RUN: $A DIG ;
   CHAR B RUN: $B DIG ;
   CHAR C RUN: $C DIG ;
   CHAR D RUN: $D DIG ;
   CHAR E RUN: $E DIG ;
   CHAR F RUN: $F DIG ;
SWITCH]

{ --------------------------------------------------------------------
Press makes a button go down then up for visual feedback.

KEYSTROKE shows a button being pressed if the character (from the
WM_CHAR messages) represents a valid control.

BUTTONPRESS accepts characters from WM_COMMAND (which means from
buttons being pressed by the mouse) or from WM_CHAR (via keyboard)
and processes them per the RPN calculator rules via BUTTONS .

The HEXCALC-MESSAGES extension simply handles the things we know
now but didn't know when we defined the switch.  The 0 POSTMESSAGE
should be added back if this is used as a standalone program, but
while running "under" SwiftForth, would cause SwiftForth to also
see the WM_QUIT message and itself exit.
-------------------------------------------------------------------- }

: PRESS ( hwnd -- )
   DUP  BM_SETSTATE 1 0 SendMessage DROP  50 Sleep drop
   BM_SETSTATE 0 0 SendMessage DROP ;

: KEYSTROKE ( -- )
   HWND WPARAM LOWORD GetDlgItem ?DUP IF PRESS THEN ;

: BUTTONPRESS
   HWND SetFocus DROP  WPARAM LOWORD UPPER BUTTONS ;

[+SWITCH HEXCALC-MESSAGES ( msg -- res )
   WM_COMMAND RUN: BUTTONPRESS 0 ;
   WM_CHAR    RUN: KEYSTROKE BUTTONPRESS 0 ;
   WM_DESTROY RUN: 0 TO HCALC ( 0 PostQuitMessage DROP) 0 ;
SWITCH]

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CR
CR .( Type HEXCALC to run the demonstration.)
CR
