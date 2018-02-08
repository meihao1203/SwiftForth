{ ==========================================================================
Keys

Copyright (C) 2004  FORTH, Inc.

TTY must deal with keystrokes in some rational manner.  The way I have
chosen is that if the user has specifically requested a key, the
keystroke messages are processed in such a way as to return anything on
the keyboard. Otherwise, i.e., when the user is in the idle loop,
windows keystrokes are processed normally.  This is done via an extra
keystroke request interface called AKEY which returned windows-filtered
keystrokes, and EKEY which returns anything that comes in without
giving windows any shot at it at all.

This file implements the functionality required to return EKEY values.

========================================================================== }

{ --------------------------------------------------------------------
Key table

KNOWN-VKEYS is a table of vkeys constants that EKEY recognizes.
KNOWN-VKEY? is true if we recognize the specified vkey code.
-------------------------------------------------------------------- }

CREATE KNOWN-VKEYS
   0 C, ( WILL BE COUNT)
   VK_PAUSE       C, (  0X13)
   VK_PRIOR       C, (  0X21)
   VK_NEXT        C, (  0X22)
   VK_END         C, (  0X23)
   VK_HOME        C, (  0X24)
   VK_LEFT        C, (  0X25)
   VK_UP          C, (  0X26)
   VK_RIGHT       C, (  0X27)
   VK_DOWN        C, (  0X28)
   VK_SNAPSHOT    C, (  0X2C)
   VK_INSERT      C, (  0X2D)
   VK_DELETE      C, (  0X2E)
   VK_F1          C, (  0X70)
   VK_F2          C, (  0X71)
   VK_F3          C, (  0X72)
   VK_F4          C, (  0X73)
   VK_F5          C, (  0X74)
   VK_F6          C, (  0X75)
   VK_F7          C, (  0X76)
   VK_F8          C, (  0X77)
   VK_F9          C, (  0X78)
   VK_F10         C, (  0X79)
   VK_F11         C, (  0X7A)
   VK_F12         C, (  0X7B)
   VK_F13         C, (  0X7C)
   VK_F14         C, (  0X7D)
   VK_F15         C, (  0X7E)
   VK_F16         C, (  0X7F)
   VK_F17         C, (  0X80)
   VK_F18         C, (  0X81)
   VK_F19         C, (  0X82)
   VK_F20         C, (  0X83)
   VK_F21         C, (  0X84)
   VK_F22         C, (  0X85)
   VK_F23         C, (  0X86)
   VK_F24         C, (  0X87)
   VK_LBUTTON     C,
   VK_RBUTTON     C,
   HERE KNOWN-VKEYS - 1- KNOWN-VKEYS C!   ( patch count)

: KNOWN-VKEY? ( vkey -- flag )
   KNOWN-VKEYS COUNT ROT SCAN NIP ;

{ --------------------------------------------------------------------
Buffered keystrokes

KEYBUF? returns true if chars are waiting or if pasting.

KEYBUF> either returns a paste character or yanks one char from the
buffer if one is waiting. Returns -1 if nothing ready.
-------------------------------------------------------------------- }

: KEYBUF? ( -- flag )
   PASTEQ IF 1 EXIT THEN
   TAIL @ HEAD @ - 0< 1 AND ;

: KEYBUF> ( -- char )
   PASTEQ IF  PASTEKEY EXIT  THEN
   KEYBUF? IF
      TAIL @ $1FC AND KEYBUF + @  4 TAIL +!
   ELSE  -1  THEN ;

{ --------------------------------------------------------------------
>KEYBUF puts a char into the buffer. Note that these chars are 32 bits
wide, and might or might not be real chars. Also note the constant
mask used to guarantee the buffer integrity. Will fail if the buffer
is overflowed.

PUSHTEXT places a string into the buffer.
-------------------------------------------------------------------- }

: >KEYBUF ( char -- )
   HEAD @ $1FC AND KEYBUF + !  4 HEAD +! ;

: PUSHTEXT ( addr len -- )
   0 ?DO COUNT >KEYBUF LOOP DROP ;

{ --------------------------------------------------------------------
EKEY message handler

KEY_SCAN
KEY_CONTROL
KEY_SHIFT
KEY_ALT  are masks added to EKEY values to indicate the keyboard state.

+KEYSTATE accumulates a keystate value.

KEYSTATE returns a value representing control/shift/alt keys pressed.

ALT? is true if either ALT key is pressed.

KDOWN  is the message handler for SYSKEYDOWN and KEYDOWN messages.
   WM_KEYDOWN WM_SYSKEYDOWN, nVirtKey is wparam

CDOWN  is the message handler for SYSCHAR and CHAR messages.
   WM_CHAR and WM_SYSCHAR , scancode is lparam(16:23)

KEY-STROKES adds keys to the keyboard queue for the parent to remove.

On WM_SYSx messages, we process the keystroke but also let Windows
have a shot at it via the DEFWINPROC call.  This results in a bit
of peculiar behaviour, where Windows will grab a key at the same
time we are trying to, or will grab it entirely. For instance, the
F10 key will return a value, but windows will also use it to select
the active menu.
-------------------------------------------------------------------- }

$010000 CONSTANT KEY_SCAN
$020000 CONSTANT KEY_CONTROL
$040000 CONSTANT KEY_SHIFT
$080000 CONSTANT KEY_ALT

: +KEYSTATE ( n mask control -- n' )
   GetKeyState $8000 AND 0<> AND OR ;

: KEYSTATE ( -- keystate )
   KEY_SCAN KEY_CONTROL  VK_CONTROL +KEYSTATE
            KEY_SHIFT    VK_SHIFT   +KEYSTATE
            KEY_ALT      VK_MENU    +KEYSTATE ;

: ALT? ( -- flag )
   VK_MENU GetKeyState $08000 AND 0<> ;

: KDOWN ( -- )
   WPARAM LOWORD KNOWN-VKEY? IF
      WPARAM LOWORD KEYSTATE OR  >KEYBUF
   THEN ;

: CDOWN ( -- )
   WPARAM >KEYBUF ;

: SKDOWN ( -- )
   WPARAM LOWORD KNOWN-VKEY? IF
      WPARAM LOWORD KEYSTATE OR  >KEYBUF
   THEN ;

: SCDOWN ( -- )
   ALT? IF   LPARAM 16 RSHIFT  $FF AND KEY_ALT OR
        ELSE WPARAM
        THEN
   >KEYBUF ;


{ --------------------------------------------------------------------
The keyhandler.

KEYMODE has true if we are to capture all keystrokes. Normally false,
which means we let windows deal with most things, and we explicitly
manage the scrollback.  In this mode

ekey etc force no windows behavior at all
akey allows/implementes all windows behaviors

a window can only do one at a time, and ekey etc only act on
one at a time. the var keymode is set on entry to tty-ekey etc
and cleared immediately

if set, capture all keyboard events
if clear, respond in windows fashion to ctrl c ctrl v and other known
windows events

STRAIGHT means return all events
-------------------------------------------------------------------- }

: RAW ( -- flag )   KEYMODE @ ;

: LOOK-VERT ( param -- )
   HWND WM_VSCROLL ROT 0 SendMessage DROP ;

: LOOK-HORZ ( param -- )
   HWND WM_HSCROLL ROT 0 SendMessage DROP ;

: UNSCROLL ( -- )
   IN-SCROLLBACK OFF  FRAMED REFRESH KDOWN ;

: SCROLLING-VKEYS ( -- )
   WPARAM LOWORD CASE
      VK_HOME   OF  SB_TOP      LOOK-VERT ENDOF
      VK_END    OF  SB_BOTTOM   LOOK-VERT ENDOF
      VK_LEFT   OF  SB_LINEUP   LOOK-HORZ ENDOF
      VK_RIGHT  OF  SB_LINEDOWN LOOK-HORZ ENDOF
      VK_UP     OF  SB_LINEUP   LOOK-VERT ENDOF
      VK_DOWN   OF  SB_LINEDOWN LOOK-VERT ENDOF
      VK_NEXT   OF  SB_PAGEDOWN LOOK-VERT ENDOF
      VK_PRIOR  OF  SB_PAGEUP   LOOK-VERT ENDOF
      VK_CONTROL OF                       ENDOF
      VK_SHIFT   OF                       ENDOF
      DUP       OF  UNSCROLL              ENDOF
   ENDCASE ;

: NORMAL-VKEYS ( -- )
   WPARAM LOWORD CASE
      VK_PRIOR  OF  SB_PAGEUP   LOOK-VERT ENDOF
      DUP       OF  KDOWN                 ENDOF
   ENDCASE ;

\ if mode is raw, return all keystrokes
\ otherwise, we were called via the AKEY interface; we have two
\ possible states. either we are doing scrollback or just waiting
\ for a keystroke

: WM-KEYDOWN ( -- res )
   RAW IF  KDOWN  0 EXIT  THEN
   IN-SCROLLBACK @ IF SCROLLING-VKEYS ELSE NORMAL-VKEYS THEN 0 ;

: WM-CHAR ( -- res )
   RAW IF  CDOWN 0 EXIT  THEN
   WPARAM LOWORD CASE
        1 OF ( ctrl a)  MARK-ALL          ENDOF
        3 OF ( ctrl c)  TTY->CLIPBOARD    ENDOF
       22 OF ( ctrl v)  CLIPBOARD->TTY    ENDOF
       27 of ( esc   )  CLEAR-MARKS CDOWN ENDOF
      DUP OF ( others)  CDOWN             ENDOF
   ENDCASE 0 ;

: WM-SYSKEYDOWN ( -- res )
   RAW IF  SKDOWN 0  ELSE  DEFWINPROC  THEN ;

: WM-SYSCHAR ( -- res )
   RAW IF  SCDOWN 0  ELSE  DEFWINPROC  THEN ;


