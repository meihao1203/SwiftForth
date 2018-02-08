{ ====================================================================
memtools.f
Memory Watchpoints.

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

{ --------------------------------------------------------------------
The user interface to this is the word WATCH.

WATCH takes an address, and inserts it into the watch list.
If the address is the >BODY of a valid Forth name, the name will
be displayed in the dialog. Otherwise, the address will be displayed
in hex.

The value of the watchpoint is displayed in whatever base was being
used when it was defined.  So, one might type

        OCTAL   FOO WATCH
        HEX     JOE WATCH
        BINARY  C#  WATCH
        DECIMAL TIB WATCH

The Watchpoint monitor can be run from the TOOLS menu item or
from the command line by typing WATCHPOINTS .  Closing the dialog
does not erase the defined watchpoints.

The watchpoints may be cleared with /WATCHES or the CLEAR button
on the dialog.

An individual watchpoint may be cleared by clicking on its name/address
display.

-------------------------------------------------------------------- }

ONLY FORTH ALSO DEFINITIONS
DECIMAL

PACKAGE MEMTOOLS

300
   ENUM IDDUMP
   ENUM IDNEXT
   ENUM IDPREV
   ENUM IDMODE
   ENUM IDSPEED
   ENUM IDREFRESH
   ENUM IDVSCROLL
   ENUM IDHSCROLL
   ENUM IDFREEZE
   ENUM IDCLEAR
DROP

VARIABLE WATCH-RATE
VARIABLE DUMP-RATE

{ --------------------------------------------------------------------
INIT-TIMER starts a timer for the update rate.

STOP-TIMER stops the update timer.

INTERVAL changes the timer rate, which varies between 100 and 1000 ms.
-------------------------------------------------------------------- }

: TIMER-RATE ( -- n )
   HWND IDSPEED 0 0 GetDlgItemInt ;

: INIT-TIMER ( n -- )
   HWND 1 THIRD 0 SetTimer DROP
   HWND IDSPEED ROT 0 SetDlgItemInt DROP ;

: STOP-TIMER ( -- )
   HWND 1 KillTimer DROP ;

: INTERVAL ( a -- res )
   STOP-TIMER
   TIMER-RATE 100 +  DUP 1000 > IF DROP 100 THEN
   DUP ROT ! INIT-TIMER 0 ;

{ --------------------------------------------------------------------

TOWATCH is the array of pointers to what to watch. The first cell of
each pair is the address, the second is the base for it's display and
other data... TBD

/WATCH  clears the watches array.

'WATCH indexes the array.

NAMED? decides if the address has a name or not.

NEWLY returns the address of the next available watch point.

WATCHING sets an address into a watchpoint, tagging it if named.

WATCH puts an address into the next watchpoint.

-------------------------------------------------------------------- }

8 CONSTANT #WATCHES

CREATE TOWATCH   #WATCHES 2* CELLS ALLOT

PUBLIC

: /WATCH ( -- )
   TOWATCH  #WATCHES 2* CELLS ERASE ;

PRIVATE

/WATCH

: 'WATCH ( n -- addr )
   2* CELLS TOWATCH + ;

: NAMED? ( addr -- flag )
   DUP ORIGIN HERE WITHIN IF
      DUP (.') NAME> >BODY =
   ELSE DROP 0 THEN ;

: NEWLY ( -- addr )
   #WATCHES 0 DO
      I 'WATCH @ $FF AND 0= IF
         I 'WATCH UNLOOP EXIT
      THEN
   LOOP ABORT" No free watches" ;

: WATCHING ( addr watch -- )
   >R  BASE @  OVER NAMED? IF $80000000 OR  THEN  R> 2! ;

{ --------------------------------------------------------------------

WATCHNAME returns a printable string for the name of the specified watch.

WATCHING-NAMES updates the names of the watch dialog.

WATCHVALUE returns a printable string in the indicated base for the
specified watch.

WATCHING-VALUES updates the values of the watch dialog.

-------------------------------------------------------------------- }

: WATCHNAME ( watch -- addr n )
   2@ 0< IF   ( has name!)  BODY> >NAME COUNT
         ELSE ( only addr)  8 (H.0)
         THEN ;

: /WATCHNAMES ( -- )
   #WATCHES 0 DO
      I 'WATCH @ $40000000 INVERT AND I 'WATCH !
   LOOP ;

: WATCHING-NAMES ( -- )
   #WATCHES 0 DO
      I 'WATCH @ $40000000 AND 0= IF
         I 'WATCH @ $FF AND IF
            I 'WATCH WATCHNAME
         ELSE
            PAD 0
         THEN  PAD ZPLACE
         HWND I 100 + PAD SetDlgItemText DROP
         I 'WATCH @ $40000000 OR I 'WATCH !
      THEN
   LOOP ;

: WATCHVALUE ( watch -- addr n )
   2@ $FF AND DUP BASE !
   $0A <> IF @ 0 ELSE @ S>D THEN (D.) ;

: WATCHING-VALUES ( -- )
   #WATCHES 0 DO
      I 'WATCH @ $FF AND IF
         I 'WATCH WATCHVALUE
      ELSE
         S"  "
      THEN PAD ZPLACE
      HWND I 200 + PAD SetDlgItemText DROP
   LOOP ;

: WATCHING-UPDATE
   WATCHING-NAMES WATCHING-VALUES ;

{ --------------------------------------------------------------------
The name, message switch, callback, and class for the dialog.
Note that you must declare DLGWINDOWEXTRA in the window extra field.
-------------------------------------------------------------------- }

CREATE WatcherName ,Z" MemWatch"

[SWITCH WATCHER-MESSAGES DEFWINPROC ( -- res )   SWITCH]

:NONAME  MSG LOWORD WATCHER-MESSAGES ; 4 CB: RUNWATCHER

: /WATCHER-CLASS ( -- hclass )
      0 CS_OWNDC   OR
        CS_HREDRAW OR
        CS_VREDRAW OR                \ class style
      RUNWATCHER                     \ wndproc
      0                              \ class extra
      DLGWINDOWEXTRA                 \ window extra
      HINST                          \ hinstance
      HINST 101 LoadIcon             \ icon
      NULL IDC_ARROW LoadCursor      \ cursor
      COLOR_BTNFACE 1+               \ background brush
      0                              \ no menu
      WatcherName                    \ class name
   DefineClass ;

{ --------------------------------------------------------------------
The watcher dialog box

WBOX simply builds a text box in the dialog template, using the
id value to calculate the position.

(WATCHER) is the modeless dialog for the memory watcher.  Modeless
implies that it runs independently of SwiftForth.

-------------------------------------------------------------------- }

: WBOX ( n -- id x y cx cy )
   DUP>R                        \ id
   R@ 100 /  1- 100 * 5 +       \ x
   R> 100 MOD 12 * 20 +         \ y
   90 12 ;                      \ cx cy

DIALOG (WATCHER)
   [MODELESS  " Memory Watcher"  10 10 200 120
      (CLASS MemWatch) ] \ (FONT 8, MS Sans Serif) ]

   [DEFPUSHBUTTON  " Close"               IDOK    160 2 35 13 ]
   [PUSHBUTTON     " Clear"            IDCLEAR    120 2 35 13 ]
   [PUSHBUTTON     " Rate"             IDSPEED      5 2 35 13 ]
   [LTEXT          " Update Rate (ms)"      -1     45 5 70 13 ]

   [PUSHBUTTON 100 WBOX (+STYLE BS_RIGHT) ]   [TEXT1BOX 200 WBOX (+STYLE WS_BORDER) ]
   [PUSHBUTTON 101 WBOX (+STYLE BS_RIGHT) ]   [TEXT1BOX 201 WBOX (+STYLE WS_BORDER) ]
   [PUSHBUTTON 102 WBOX (+STYLE BS_RIGHT) ]   [TEXT1BOX 202 WBOX (+STYLE WS_BORDER) ]
   [PUSHBUTTON 103 WBOX (+STYLE BS_RIGHT) ]   [TEXT1BOX 203 WBOX (+STYLE WS_BORDER) ]
   [PUSHBUTTON 104 WBOX (+STYLE BS_RIGHT) ]   [TEXT1BOX 204 WBOX (+STYLE WS_BORDER) ]
   [PUSHBUTTON 105 WBOX (+STYLE BS_RIGHT) ]   [TEXT1BOX 205 WBOX (+STYLE WS_BORDER) ]
   [PUSHBUTTON 106 WBOX (+STYLE BS_RIGHT) ]   [TEXT1BOX 206 WBOX (+STYLE WS_BORDER) ]
   [PUSHBUTTON 107 WBOX (+STYLE BS_RIGHT) ]   [TEXT1BOX 207 WBOX (+STYLE WS_BORDER) ]
END-DIALOG

{ --------------------------------------------------------------------
WATCHORG holds the watch window active state, followed by the window
screen position so it is sticky.


WATCHER-CLOSE kills the timer and closes the dialog.

WATCHER-COMMANDS is the WM_COMMAND message handler for the dialog.

WATCHER-MESSAGES is the callback message handler for the dialog.

RUNWATCHER is the callback for the dialog.

WATCHER starts the dialog.

-------------------------------------------------------------------- }

CREATE WATCHORG  5 CELLS /ALLOT

CONFIG: WATCH-WINDOW ( -- addr len )   WATCHORG 5 CELLS ;

: WATCHER-CLOSE ( -- res )
   HWND STOP-TIMER  (WATCHER) CELL- OFF  WATCHORG OFF
   HWND DestroyWindow REBUTTON ;

: ?/WATCH ( -- res )
   WPARAM LOWORD 100 MOD ( n)
   DUP 'WATCH @ $FF AND IF
      HWND Z" Clear this watchpoint?" Z" Attention!" MB_YESNO MessageBox
      IDYES = IF
         0 0 WPARAM LOWORD 100 MOD 'WATCH 2!
         WATCHING-UPDATE
      THEN
   THEN 0 ;

: SET-WATCH-FONTS
   OEM_FIXED_FONT GetStockObject
   #WATCHES 0 DO
      DUP I 100 + SetDlgItemFont
      DUP I 200 + SetDlgItemFont
   LOOP DROP ;

: WATCH-INIT ( -- )
   WATCHORG 3 CELLS + 2@ OR IF WATCHORG CELL+ RESTOREWINDOWPOS THEN
   WATCH-RATE @ 100 MAX  INIT-TIMER SET-WATCH-FONTS WATCHING-UPDATE
   WATCHORG ON  REBUTTON ;

[SWITCH WATCHER-COMMANDS ZERO
   IDOK     RUN: ( -- res )   WATCHER-CLOSE ;
   IDCANCEL RUN: ( -- res )   WATCHER-CLOSE ;
   IDSPEED  RUN: ( -- res )   WATCH-RATE INTERVAL ;
   IDCLEAR  RUN: ( -- res )   /WATCH 0 ;
   100      RUN: ( -- res )   ?/WATCH ;
   101      RUN: ( -- res )   ?/WATCH ;
   102      RUN: ( -- res )   ?/WATCH ;
   103      RUN: ( -- res )   ?/WATCH ;
   104      RUN: ( -- res )   ?/WATCH ;
   105      RUN: ( -- res )   ?/WATCH ;
   106      RUN: ( -- res )   ?/WATCH ;
   107      RUN: ( -- res )   ?/WATCH ;
SWITCH]

[+SWITCH WATCHER-MESSAGES
   WM_CLOSE      RUN: WATCHER-CLOSE ;
   WM_INITDIALOG RUN: ( -- res )   WATCH-INIT 0 ;
   WM_COMMAND    RUN: ( -- res )   WPARAM LOWORD WATCHER-COMMANDS ;
   WM_TIMER      RUN: ( -- res )   WATCHING-UPDATE 0 ;
   WM_MOVE       RUN: ( -- res )   WATCHORG @+ IF SAVEWINDOWPOS THEN ;
SWITCH]

: /WATCHPOINTS ( -- )
   (WATCHER) CELL- @ ?DUP IF  WM_CLOSE 0 0 SendMessage DROP
   THEN  WatcherName HINST UnregisterClass DROP ;

PUBLIC

: WATCHPOINTS ( -- )
   /WATCHER-CLASS DROP  /WATCHNAMES
   (WATCHER) CELL- @ ?DUP IF  SetForegroundWindow DROP EXIT THEN
   HINST (WATCHER) 0 RUNWATCHER 0  CreateDialogIndirectParam
   DUP (WATCHER) CELL- ! DUP SW_SHOWDEFAULT ShowWindow DROP
   UpdateWindow DROP ;

: WATCH ( addr -- )
   DUP 4 IsBadReadPtr ABORT" Can't watch a non-Forth address"
   WATCHPOINTS  NEWLY WATCHING
   HWND SetForegroundWindow DROP ;

: -WATCH ( n -- )
   ABS #WATCHES MOD 'WATCH OFF ;

:ONENVLOAD   /WATCH  500 WATCH-RATE !  WATCHORG @ IF
      WATCHORG OFF  WATCHPOINTS THEN ;
:ONENVEXIT   /WATCHPOINTS ;

{ ========================================================================
DUMP in a dialog

======================================================================== }

PRIVATE

{ --------------------------------------------------------------------

DMP-PAD is enough space for 16 lines of 16 bytes dump display,
each line requiring 16 3 * 16 + 10 + bytes, with a little left
over for good luck and a null terminator.

<#DMP begins the dump numeric conversion and
DMP#> ends it.

DMP-START  is the address for the dump memory area to begin at.

DMP-CACHE  is a cached copy of the last dump area, kept to reduce
the output time on refresh for static data.

-SAME  is true if the cache does not match the real data.

N#  puts N into the expanding numeric conversion area as an unsigned
number in a fixed field of zeros.

.R#  puts N into a the expanding numeric conversion area as a signed
number in a fixed field of blanks.

4@ reads four cells from the specified address.
-------------------------------------------------------------------- }

VARIABLE DMP-PAD

: <#DMP   DMP-PAD @ 2040 + DUP OFF DPL ! ;

: DMP#> ( -- zaddr )   DPL @ ;

CREATE DMP-START         HERE ,

CREATE DMP-CACHE   256 ALLOT

: -SAME ( -- flag )
   DMP-START @ 256 IsBadReadPtr ?DUP ?EXIT
   DMP-START @ 256 DMP-CACHE OVER COMPARE ;

: N# ( n field -- )
   0 SWAP 0 DO # LOOP 2DROP ;

: .R# ( n field -- )
   DPL @ SWAP - >R
   DUP  ABS S>D #S 2DROP SIGN
   DPL @ R> - 0 MAX 0 ?DO BL HOLD LOOP ;

: 4@ ( a -- [a] [a+4] [a+8] [a+12] )
   @+ SWAP @+ SWAP @+ SWAP @ ;

: CANTREAD ( -- )
   S" Invalid memory region selected at " PAD ZPLACE
   DMP-START @ 8 (H.0) PAD ZAPPEND
   HWND IDDUMP PAD SetDlgItemText DROP ;

: NOWAY? ( -- flag )
   DMP-START @ 256 IsBadReadPtr DUP IF CANTREAD THEN ;

: UPDATE-SCROLLERS
   HWND IDVSCROLL GetDlgItem SB_CTL
   DMP-START @ DUP IF
      16 RSHIFT LOWORD  $1000 MAX $F000 MIN
   THEN  -1 SetScrollPos DROP
   HWND IDHSCROLL GetDlgItem SB_CTL
   DMP-START @ 15 AND -1 SetScrollPos DROP ;

{ --------------------------------------------------------------------
.TEXT converts the 16 bytes below the address into printable characters
which are added to the expanding numeric conversion area.

.DATA converts the 16 bytes below the address into hex bytes.

.ADDR converts the address into an 8 character wide hex number.

x.DMPLINE formats the data at the address into a zero terminated string.

CANTREAD displays an error message if the address selected is out of
the range available to SwiftForth.

.DMP displays the data at the address in the selected format.
-------------------------------------------------------------------- }

: .ADDR ( a -- )
   HEX [CHAR] : HOLD  8 N# BL HOLD ;

: B.DMPLINE ( a -- )   HEX
   16 +  16 0 DO  1-  DUP C@
      DUP 32 128 WITHIN NOT IF DROP [CHAR] . THEN HOLD
   LOOP BL HOLD
   16 +  16 0 DO  1-  DUP C@
      2 N# BL HOLD
   LOOP DROP ;

: HW.DMPLINE ( a -- zaddr )  HEX
   DUP 4@  4 0 DO 8 N# BL HOLD LOOP DROP ;

: DW.DMPLINE ( a -- zaddr )  DECIMAL
   DUP 4@  4 0 DO
      11 .R# BL HOLD LOOP DROP ;

DEFER DMPLINE   ' B.DMPLINE IS DMPLINE

: (.DMP) ( -- zaddr )
   <#DMP
      DMP-START @  256 + 16 0 DO
	 I IF  10 HOLD 13 HOLD  THEN
         16 - DUP DMPLINE  DUP .ADDR
      LOOP DROP
   DMP#> ;

: .DMP ( -- )
   UPDATE-SCROLLERS  NOWAY? ?EXIT
   HWND IDDUMP  (.DMP) SetDlgItemText DROP
   DMP-START @ DMP-CACHE 256 CMOVE ;

{ --------------------------------------------------------------------
DMP-REFRESH redisplays the memory dump if it has changed.

.DMPTITLE sets the dialog title to match the dump mode.

+DMPMODE cycles thru the available dump modes.
-------------------------------------------------------------------- }

: DMP-REFRESH ( -- )
   -SAME -EXIT .DMP ;

: DMPTITLE ( -- )
   ['] DMPLINE >BODY @ CASE
      ['] DW.DMPLINE OF Z" Memory Dump (decimal words)" ENDOF
      ['] HW.DMPLINE OF Z" Memory Dump (hex words)"     ENDOF
		 DUP OF Z" Memory Dump (hex bytes)"     ENDOF
   ENDCASE
   HWND SWAP SetWindowText DROP ;

: +DMPMODE ( -- )
   ['] DMPLINE >BODY @ CASE
      ['] B.DMPLINE  OF [']  HW.DMPLINE   ENDOF
      ['] HW.DMPLINE OF [']  DW.DMPLINE   ENDOF
		 DUP OF [']  B.DMPLINE    ENDOF
   ENDCASE IS DMPLINE  .DMP  DMPTITLE ;


{ --------------------------------------------------------------------
The name, message switch, callback, and class for the dialog.
Note that you must declare DLGWINDOWEXTRA in the window extra field.
-------------------------------------------------------------------- }

CREATE DumperName ,Z" MemDump"

[SWITCH DMP-MESSAGES DEFWINPROC ( -- res )   SWITCH]

:NONAME  MSG LOWORD DMP-MESSAGES ; 4 CB: RUNDUMP

: /DUMP-CLASS ( -- hclass )
      0 CS_OWNDC   OR
        CS_HREDRAW OR
        CS_VREDRAW OR                \ class style
      RUNDUMP                        \ wndproc
      0                              \ class extra
      DLGWINDOWEXTRA                 \ window extra
      HINST                          \ hinstance
      HINST 101 LoadIcon             \ icon
      NULL IDC_ARROW LoadCursor      \ cursor
      COLOR_BTNFACE 1+               \ background brush
      0                              \ no menu
      DumperName                     \ class name
   DefineClass ;

{ --------------------------------------------------------------------
DBOX is a macro for laying out the dump lines in the dialog box.

(DMP) is the dialog box itself.
-------------------------------------------------------------------- }

DIALOG (DMP)
   [MODELESS  " Memory Dump"  10 10 427 170
      (CLASS MemDump)  (FONT 8, MS Sans Serif) ]

   [DEFPUSHBUTTON  " Close"                 IDOK      380  2   35 13 ]
   [PUSHBUTTON     " Mode"                  IDMODE    340  2   35 13 ]
   [PUSHBUTTON     " Refresh"               IDREFRESH 300  2   35 13 ]
   [PUSHBUTTON     " Next"                  IDNEXT    260  2   35 13 ]
   [PUSHBUTTON     " Prev"                  IDPREV    220  2   35 13 ]
   [PUSHBUTTON     " Freeze"                IDFREEZE  180  2   35 13 ]
   [PUSHBUTTON     " Rate"                  IDSPEED     5  2   35 13 ]
   [LTEXT          " Update Rate (ms)"      -1         45  5   70 13 ]
   [VSCROLLBAR                              IDVSCROLL 412 20   12 135 ]
   [HSCROLLBAR                              IDHSCROLL   2 155 410 12 ]

   [TEXTBOX  IDDUMP 2 20 410 135 (+STYLE WS_BORDER) ]
END-DIALOG

{ --------------------------------------------------------------------
nScrollCode = (int) LOWORD(wParam); // scroll bar value
nPos = (short int) HIWORD(wParam);  // scroll box position
hwndScrollBar = (HWND) lParam;      // handle of scroll bar


The WM_VSCROLL message is sent to a window when a scroll event occurs in the window's standard vertical scroll bar. This message is also sent to the owner of a vertical scroll bar control when a scroll event occurs in the control.

Parameters

nScrollCode

Value of the low-order word of wParam. Specifies a scroll bar value that indicates the user's scrolling request. This parameter can be one of the following values:

Value	Meaning
SB_BOTTOM	Scrolls to the lower right.
SB_ENDSCROLL	Ends scroll.
SB_LINEDOWN	Scrolls one line down.
SB_LINEUP	Scrolls one line up.
SB_PAGEDOWN	Scrolls one page down.
SB_PAGEUP	Scrolls one page up.
SB_THUMBPOSITION	Scrolls to the absolute position. The current position is specified by the nPos parameter.
SB_THUMBTRACK	Drags scroll box to the specified position. The current position is specified by the nPos parameter.
SB_TOP

WORD wScrollNotify = 0xFFFF;

.
.
.

    if (wScrollNotify != -1)
        SendMessage(hwnd, WM_VSCROLL,
            MAKELONG(wScrollNotify, 0), 0L);
 -------------------------------------------------------------------- }

: +DMPV ( n -- res )
   DMP-START +!  .DMP 0 ;

[SWITCH DMP-VSCROLL ZERO
   SB_LINEDOWN      RUN:   16 +DMPV ;
   SB_LINEUP        RUN:  -16 +DMPV ;
   SB_PAGEUP        RUN: -256 +DMPV ;
   SB_PAGEDOWN      RUN:  256 +DMPV ;
   SB_THUMBTRACK    RUN: WPARAM $FFFF0000 AND DMP-START !  .DMP 0 ;
   SB_THUMBPOSITION RUN: WPARAM $FFFF0000 AND DMP-START !  .DMP 0 ;
SWITCH]

: >DMPH ( n -- res )
   DMP-START @ $FFFFFFF0 AND + DMP-START !  .DMP 0 ;

: +DMPH ( n -- )
   DMP-START @ $0F AND +  0 MAX 15 MIN  >DMPH ;

[SWITCH DMP-HSCROLL ZERO
   SB_LINELEFT      RUN:   -1 +DMPH ;
   SB_LINERIGHT     RUN:    1 +DMPH ;
   SB_PAGELEFT      RUN:   -1 +DMPH ;
   SB_PAGERIGHT     RUN:    1 +DMPH ;
   SB_THUMBTRACK    RUN:    WPARAM HIWORD >DMPH ;
SWITCH]

: DMP-HSCROLL-INIT
   HWND IDHSCROLL GetDlgItem SB_CTL 0 $000F -1 SetScrollRange DROP
   HWND IDVSCROLL GetDlgItem SB_CTL 0 $FFFF -1 SetScrollRange DROP ;

: DMP-SCROLL ( cmd -- res )
   HWND IDVSCROLL GetDlgItem WM_VSCROLL ROT 0 SendMessage DROP 0 ;

{ --------------------------------------------------------------------
DUMPORG holds the watch window active state, followed by the window
screen position so it is sticky.

SET-DMP-FONTS sets the fonts of the dump display lines to the system
OEM_FIXED_FONT object.

DMP-CLOSE destroys the dialog box and timer.

DMP-INIT sets up the timer and fonts and displays the dialog.
-------------------------------------------------------------------- }

CREATE DUMPORG  5 CELLS /ALLOT

CONFIG: DUMP-WINDOW ( -- addr len )   DUMPORG 5 CELLS ;

: SET-DMP-FONTS
   IDDUMP SetDlgItemFixedFont ;

: DMP-CLOSE ( -- res )
   (DMP) CELL- OFF  DUMPORG OFF
   STOP-TIMER
   DMP-PAD @ FREE DROP
   HWND DestroyWindow
   REBUTTON ;

{ --------------------------------------------------------------------
DMP seeking valid memory at 50ms ticks...

-------------------------------------------------------------------- }

VARIABLE SEEKING

: -GOOD ( -- flag )
   DMP-START @ 256 IsBadReadPtr ;

: DMP-CLAMP ( -- )
   DMP-START @ $FFFFE000 AND DMP-START ! ;

: DMP-FORWARD ( -- )   DMP-CLAMP $100
   BEGIN ( n) 1- DUP WHILE  -GOOD 0= WHILE
      $1000 DMP-START +! REPEAT THEN
   BEGIN ( n) 1- DUP WHILE  -GOOD    WHILE
      $1000 DMP-START +! REPEAT THEN
   DROP

   .DMP  -GOOD IF 1 SEEKING ! 1 ELSE TIMER-RATE THEN
   HWND 1 ROT 0 SetTimer DROP ;

: DMP-BACKWARD ( -- )   DMP-CLAMP  $100
   BEGIN    $-1000 DMP-START +!
      ( n) 1- DUP WHILE  -GOOD 0= UNTIL THEN
   BEGIN    $-1000 DMP-START +!
      ( n) 1- DUP WHILE  -GOOD UNTIL THEN
   DROP  $1000 DMP-START +!

   .DMP  -GOOD IF -1 SEEKING ! 1 ELSE TIMER-RATE THEN
   HWND 1 ROT 0 SetTimer DROP ;

VARIABLE FROZEN

: DMP-TIMER
   FROZEN @ ?EXIT
   SEEKING @ ?DUP IF  SEEKING OFF
      0< IF DMP-BACKWARD ELSE DMP-FORWARD THEN
   THEN DMP-REFRESH ;

: DMP-FREEZE ( -- )   PAD OFF
   HWND IDFREEZE PAD 8 GetDlgItemText DROP
   PAD C@ [CHAR] F = IF
      FROZEN ON  Z" Run"
   ELSE
      FROZEN OFF Z" Freeze"
   THEN
   HWND IDFREEZE ROT SetDlgItemText DROP ;


{ --------------------------------------------------------------------
Message handlers

DMP-COMMANDS handles the WM_COMMAND messages to the dialog.

DMP-MESSAGES handles all the windows messages for the dialog.

RUNDMP is the windows callback.

DMP starts the dialog running.
-------------------------------------------------------------------- }

: DMP-INIT ( -- )
   SET-DMP-FONTS  DMPTITLE
   DUMPORG 3 CELLS + 2@ OR IF DUMPORG CELL+ RESTOREWINDOWPOS THEN
   2048 ALLOCATE DROP DMP-PAD !
   DMP-HSCROLL-INIT
   .DMP  DUMP-RATE @ 100 MAX  INIT-TIMER
   DUMPORG ON  REBUTTON ;

[SWITCH DMP-COMMANDS ZERO
   IDOK       RUN: ( -- RES )   DMP-CLOSE ;
   IDCANCEL   RUN: ( -- RES )   DMP-CLOSE ;
   IDMODE     RUN: ( -- RES )   +DMPMODE 0 ;
   IDREFRESH  RUN: ( -- res )   .DMP 0 ;
   IDNEXT     RUN: ( -- RES )   DMP-FORWARD 0 ;
   IDPREV     RUN: ( -- res )   DMP-BACKWARD 0 ;
   IDSPEED    RUN: ( -- RES )   DUMP-RATE INTERVAL 0 ;
   IDFREEZE   RUN: ( -- res )   DMP-FREEZE 0 ;
SWITCH]

[+SWITCH DMP-MESSAGES
   WM_INITDIALOG RUN: ( -- RES )   DMP-INIT 0 ;
   WM_CLOSE      RUN: ( -- RES )   DMP-CLOSE ;
   WM_COMMAND    RUN: ( -- RES )   WPARAM LOWORD DMP-COMMANDS ;
   WM_TIMER      RUN: ( -- res )   DMP-TIMER 0 ;
   WM_VSCROLL    RUN: ( -- RES )   WPARAM LOWORD DMP-VSCROLL ;
   WM_HSCROLL    RUN: ( -- res )   WPARAM LOWORD DMP-HSCROLL ;
   WM_MOVE       RUN: ( -- res )   DUMPORG @+ IF SAVEWINDOWPOS THEN ;
SWITCH]

: /MEM ( -- )
   (DMP) CELL- @ ?DUP IF  WM_CLOSE 0 0 SendMessage DROP
   THEN  DumperName HINST UnregisterClass DROP ;

PUBLIC

: MEM ( addr -- )   /DUMP-CLASS DROP
   FROZEN OFF  SEEKING OFF DMP-START !  (DMP) CELL- @ ?EXIT
   HINST (DMP) 0 RUNDUMP 0 CreateDialogIndirectParam
   DUP (DMP) CELL- ! DUP SW_SHOWDEFAULT ShowWindow DROP
   UpdateWindow DROP ;

: MEMORY ( -- )   DMP-START @ MEM ;

:ONENVLOAD   ORIGIN DMP-START !  500 DUMP-RATE !
   DUMPORG @ IF DUMPORG OFF MEMORY THEN ;

:ONENVEXIT   /MEM ;

CONSOLE-WINDOW +ORDER

[+SWITCH SF-COMMANDS ( wparam -- )
   MI_WATCH  RUN: WATCHORG @ IF /WATCHPOINTS ELSE WATCHPOINTS THEN ;
   MI_MEMORY RUN: DUMPORG @ IF /MEM ELSE MEMORY THEN ;
SWITCH]

CONSOLE-WINDOW -ORDER

END-PACKAGE

