{ ====================================================================
winmgmt.f
Window management tools

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

{ ------------------------------------------------------------------------
Title bar manipulation

-TITLE  strips the optional text from the title bar.

+TITLE  adds a string to the title bar, removing any previous optional
text which was installed.
------------------------------------------------------------------------ }

?( ... Window title management)

: SET-TITLE ( zaddr -- )
   HWND SWAP SetWindowText DROP ;

CREATE TITLE   256 /ALLOT

: /TITLE ( -- )   S" SwiftForth   " TITLE ZPLACE  TITLE SET-TITLE ;

: -TITLE ( -- )   R-BUF
   HWND R@ 256 GetWindowText IF
      R@ ZCOUNT [CHAR] : SCAN ( a n) IF   R@ TUCK -
      ELSE  DROP R@ ZCOUNT  THEN
      -TRAILING + OFF
      R@ SET-TITLE
   THEN R> DROP ;

: +TITLE ( addr n -- )   R-BUF  -TITLE
   HWND R@ 256 GetWindowText IF
      S"  :: " R@ ZAPPEND  R@ ZAPPEND   R@ SET-TITLE
   THEN R> DROP ;

: TITLE" ( -- ) \ Usage: TITLE" <string>"
   [CHAR] " WORD COUNT TITLE ZPLACE   TITLE SET-TITLE ;

:ONENVLOAD ( -- )   TITLE C@ IF
      TITLE SET-TITLE  ELSE  /TITLE  THEN ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

?( ... Misc window management)


{ ----------------------------------------------------------------------
Per the microsoft c header files, SM_XVIRTUALSCREEN and
SM_YVIRTUALSCREEN references to getsystemmetrics always return 0; so
GetDesktopSize is corrected and the constants are omitted.

 76 CONSTANT SM_XVIRTUALSCREEN 
 77 CONSTANT SM_YVIRTUALSCREEN 
---------------------------------------------------------------------- }
\ constants not defined in wincon.dll for multiple monitors

 78 CONSTANT SM_CXVIRTUALSCREEN 
 79 CONSTANT SM_CYVIRTUALSCREEN 
 80 CONSTANT SM_CMONITORS         

: GetDesktopSize ( -- x y cx cy )   0 0 
   SM_CXVIRTUALSCREEN   GetSystemMetrics 
   SM_CYVIRTUALSCREEN   GetSystemMetrics ;

\ GetWindowRect returns screen xy of left:top and right:bottom
\ coordinates. This isn't as useful for forcing a particular size
\ as knowing the screen xy of left:top and the width:height of 
\ the window.

: GetWindowSize ( hwnd -- x y width height flag )
   16 R-ALLOC >R                        \ buffer for window params
   R@ GetWindowRect                     \ keep the flag here
   R> @RECT                             \ flag x y x y 
   >R THIRD - R> THIRD -                \ flag x y w h 
   2>R ROT 2R> ROT ;                    \ x y w h flag 

: SHOW/HIDE ( hwnd flag -- )
   IF SW_NORMAL ELSE SW_HIDE THEN
   ShowWindow DROP  HWND WM_SIZE 0 0 SendMessage DROP ;

: MOVEWIN ( hwnd x y cx cy -- res )
   GetDesktopSize LOCALS| maxy maxx y0 y1 cy cx y x hw |
   cy maxy  50 - MIN TO cy
   cx maxx 100 - MIN TO cx
   y maxy cy - MIN TO y
   x maxx cx - MIN TO x
   hw x y cx cy 1 MoveWindow ;

: SAVEWINDOWPOS ( addr -- )
   HWND SWAP GetWindowRect DROP ;

: RESTOREWINDOWPOS ( addr -- )
   HWND SWAP 2@ SWAP ( x y)
   HWND PAD GetWindowRect DROP  PAD @RECT  >R ROT - SWAP R> SWAP - ( x y cx cy)
   MOVEWIN DROP ;

: RECT-EDGE ( a -- n )
   DUP @  SWAP  2 CELLS + @ SWAP - ;

: WINDOW-HEIGHT ( handle -- n )
   R-BUF R@ GetWindowRect DROP  R> CELL+ RECT-EDGE ;

: CLIENT-HEIGHT ( handle -- n )
   R-BUF R@ GetClientRect DROP  R> CELL+ RECT-EDGE ;

: WINDOW-WIDTH ( handle -- n )
   R-BUF R@ GetWindowRect DROP  R> RECT-EDGE ;

: CLIENT-WIDTH ( handle -- n )
   R-BUF R@ GetClientRect DROP  R> RECT-EDGE ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: FONTMETRICS ( handle -- width height )
   [OBJECTS TEXTMETRIC MAKES TM OBJECTS]
   ( handle)  0 locals| dc handle |
   HANDLE GetDC DUP to dc
   HANDLE WM_GETFONT 0 0 SendMessage
   SelectObject >R
   DC TM ADDR GetTextMetrics DROP  
   TM AveCharWidth @  TM Height @ 
   DC R>  SelectObject DROP
   HANDLE DC ReleaseDC DROP ;

: CHAR-HEIGHT ( handle -- n )   FONTMETRICS NIP ;
: CHAR-WIDTH  ( handle -- n )   FONTMETRICS DROP ;

{ --------------------------------------------------------------------
BYE sends a simple WM_CLOSE message to the main window. The window's
callback response to WM_CLOSE handles the rest of the shutdown.

RESTART relaunches the swiftforth environment just as it was 
originally started and quits the current instance. Very useful
when working with windows callbacks where an EMPTY tends to 
confuse windows badly.
-------------------------------------------------------------------- }

?( ... Windows proper bye)

: (BYE) ( -- )
   HWND 0= IF  _BYE  THEN                       \ If no window, use console's _BYE
   HWND WM_CLOSE 0 0 SendMessage DROP
   BEGIN STOP AGAIN ;

' (BYE) IS BYE


{ ----------------------------------------------------------------------
Stealing focus is bad. But, swiftforth/swiftx are only started when the
user asks for it, and sometimes other windows seem to keep focus,
especially when using the "restart" command above. This fixes the
problem.
---------------------------------------------------------------------- }

1 import: GetWindowDC
2 import: GetWindowThreadProcessId
3 import: AttachThreadInput
1 import: BringWindowToTop

8 import: DeferWindowPos
1 import: BeginDeferWindowPos
1 import: EndDeferWindowPos

0 SWP_NOSIZE     OR
  SWP_NOMOVE     OR 
  SWP_NOACTIVATE OR CONSTANT SF-SWPFLAGS 



: StealFocus ( hwnd -- )  
   0 0 0 0 locals| hwdp his_w his_t my_t my_w |

   GetForegroundWindow to his_w
   2 BeginDeferWindowPos to hwdp
   hwdp if 
      hwdp my_w  HWND_TOP 0 0 0 0 SF-SWPFLAGS DeferWindowPos DROP 
      hwdp his_w my_w     0 0 0 0 SF-SWPFLAGS DeferWindowPos DROP 
      hwdp EndDeferWindowPos drop
   then 

   his_w 0 GetWindowThreadProcessId to his_t
   GetCurrentThreadId to my_t 

   his_w 0<>  my_t his_t <>  and  if
      my_t his_t -1 AttachThreadInput drop
      my_w SetForegroundWindow drop
      my_t his_t 0 AttachThreadInput drop
   else 
      my_w SetForegroundWindow drop
   then ;

{ --------------------------------------------------------------------
REBUTTON sends a command to the window which causes the button bar to
be refreshed. This has an effect on the state of buttons which stay
pushed, such as the memory dump button.
-------------------------------------------------------------------- }

: REBUTTON ( -- )   HCON WM_COMMAND MI_REFRESH 0 PostMessage DROP ;

