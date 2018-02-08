{ ==========================================================================
TTY

Copyright 2004  FORTH, Inc.

========================================================================== }

PACKAGE TTY-WORDS

{ --------------------------------------------------------------------
Configuration constants

See vp.f for ROWS and COLS screen layout.  These must be powers of 2
for screen wrap to work correctly!
-------------------------------------------------------------------- }

1 12 LSHIFT CONSTANT ROWS
1  8 LSHIFT CONSTANT COLS

INCLUDE %swiftforth\src\ide\win32\tty\globals
INCLUDE %swiftforth\src\ide\win32\tty\vbufdata
INCLUDE %swiftforth\src\ide\win32\tty\vp
INCLUDE %swiftforth\src\ide\win32\tty\clipboard
INCLUDE %swiftforth\src\ide\win32\tty\ekey
INCLUDE %swiftforth\src\ide\win32\tty\repaint
INCLUDE %swiftforth\src\ide\win32\tty\window

PUBLIC

: TtyFirstLine ( hwnd -- zaddr )   TTY_FIRSTLINE 0 0 SendMessage ;
: TtyNextLine ( hwnd -- zaddr )   TTY_NEXTLINE  0 0 SendMessage ;
: TtyFirstMarked ( hwnd -- zaddr )   TTY_FIRSTLINE 0 0 SendMessage ;
: TtyNextMarked ( hwnd -- zaddr )   TTY_NEXTLINE  0 0 SendMessage ;

: TtyEmit ( char hwnd -- 0 )   TTY_EMIT ROT 0 SendMessage ;
: TtyType ( addr len hwnd -- 0 )   TTY_TYPE 2SWAP SendMessage ;
: TtyWrap ( addr len hwnd -- 0 )   TTY_WRAP 2SWAP SendMessage ;
: TtyCR ( hwnd -- 0 )  TTY_CR 0 0 SendMessage ;
: TtyPAGE ( hwnd -- 0 )  TTY_PAGE 0 0 SendMessage ;
: TtyNEW ( hwnd -- 0 )  TTY_NEW 0 0 SendMessage ;

: TtyEkey ( hwnd -- char )   TTY_EKEY 0 0 SendMessage ;
: TtyEkeyq ( hwnd -- char )   TTY_EKEYQ 0 0 SendMessage ;

: TtyKeymode ( mode hwnd -- old )   TTY_KEYMODE ROT 0 SendMessage ;
: TtyPushtext ( addr len hwnd -- 0 )   TTY_PUSHTEXT 2SWAP SendMessage ;
: TtyBreak ( hwnd -- 0 )   TTY_BREAK 0 0 SendMessage ;
: TtySetxy ( xy hwnd -- 0 )   TTY_SETXY ROT 0 SendMessage ;
: TtyGetxy ( hwnd -- xy )   TTY_GETXY 0 0 SendMessage ;
: TtyGetsize ( hwnd -- xy )   TTY_GETSIZE 0 0 SendMessage ;

: TtyCopytext ( hwnd -- ior )   TTY_COPYTEXT 0 0 SendMessage ;
: TtyGetword ( hwnd -- zstr )   TTY_GETWORD 0 0 SendMessage ;
: TtySelectAll ( hwnd -- ior )   TTY_SELECTALL 0 0 SendMessage ;

: TtySetfont ( hfont hwnd -- ior )   TTY_SETFONT ROT 0 SendMessage ;
: TtyGetfont ( hwnd -- hfont )   TTY_GETFONT 0 0 SendMessage ;
: TtyRecorder ( zstr hwnd -- ior )   TTY_RECORDER ROT 0 SendMessage ;

: TtySetCaret ( n hwnd -- ior )   TTY_SETCARET ROT 0 SendMessage ;
: TtyCaretMode ( mode hwnd -- old )   TTY_CARETMODE ROT 0 SendMessage ;

: TtyUsecolor ( n hwnd -- ior )   TTY_USECOLOR ROT 0 SendMessage ;

: TtySetColor ( bk fg n hwnd -- ior )
   LOCALS| h n fg bk |
   h TTY_SETFGCOLOR  n fg SendMessage DROP
   h TTY_SETBKCOLOR  n bk SendMessage DROP
   0 ;

END-PACKAGE
