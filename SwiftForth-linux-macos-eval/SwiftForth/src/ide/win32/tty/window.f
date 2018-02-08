{ ==========================================================================
Window class

Copyright (C) 2004  FORTH, Inc.

This is a new class for the TTY console window.

========================================================================== }

\ P. is a debug aid that sets the title bar of parent.

: P. ( zstr -- )
   HWND GetParent SWAP SetWindowText DROP ;

{ --------------------------------------------------------------------
SHOW-CARET calculates the caret position from the virtual cursor
   position on the screen and shows the caret there.

/CARET creates a caret, width based on the inserting flag.

CARET/ destroys the caret. Period.

-CARET hides the caret if it was visible.

+CARET shows the caret iff it was hidden, and not marking,
   and not in scrollback.

ON-SETFOCUS creates the caret and invalidates the entire screen.
On-KILLFOCUS destroys the caret.

OCARET-WIDTH returns the overstrike caret width, either from
FIXED-CARET (user selected size) or if that's 0, then based on current
character width.

/CARETSIZE sets up the caret shapes based on the size of a character.

TTY-SETCARET is the exported function for setting FIXED-CARET.
-------------------------------------------------------------------- }

: SHOW-CARET ( -- )
   X VLEFT - CHARW @ * 3 + Y VTOP - CHARH @ * YMARGIN + SetCaretPos DROP
   HWND ShowCaret DROP ;

: /CARET ( -- )   HWND 0 CARETSIZE CreateCaret DROP  HIDDEN-CARET ON ;
: CARET/ ( -- )   DestroyCaret DROP HIDDEN-CARET ON ;

: -CARET ( -- )   HAVE-FOCUS @ IF
      HIDDEN-CARET @ 0= IF
         HWND HideCaret DROP  HIDDEN-CARET ON THEN
   THEN ;

: +CARET ( -- )   HAVE-FOCUS @ IF
      HIDDEN-CARET @ 0<>  MARKING @ 0=  AND  IN-SCROLLBACK @ 0= AND  IF
            FRAMED SHOW-CARET  HIDDEN-CARET OFF  THEN
   THEN ;

: ON-SETFOCUS  ( -- )   HAVE-FOCUS ON   /CARET REFRESH  ;
: ON-KILLFOCUS ( -- )   HAVE-FOCUS OFF  -CARET  CARET/  ;

VARIABLE FIXED-CARET

: OCARET-WIDTH ( -- n )
   FIXED-CARET @ IF
      FIXED-CARET @  CHARW @ MIN  1 MAX
   ELSE CHARW @ THEN ;

: /CARETSIZE ( -- )
   2 CHARH @ ICARET 2!  OCARET-WIDTH CHARH @ OCARET 2! /CARET ;


{ --------------------------------------------------------------------
Fonts

FONTMETRICS returns the char width and height for the specified font
   in device context.

/STOCKFONT grabs the OEM_FIXED_FONT if no font has been specivied yet.

/FONTSIZE sets up the window based on the size of a character.

INSTALL-FONT sets up the window based on the selected font.

/FONT creates a font if needed and installs it.
-------------------------------------------------------------------- }

: FONTMETRICS ( dc -- charw charh )   80 R-ALLOC >R
   R@ GetTextMetrics DROP  R@ 4 CELLS + 2@  R> @ + ;

: /STOCKFONT ( -- )   HFONT @ IF EXIT THEN
   OEM_FIXED_FONT GetStockObject HFONT ! ;

: /FONTSIZE ( charw charh -- )   CHARH !  CHARW !
   WINW @ CHARW @ / WIDE !  WINH @ CHARH @ / HIGH ! ;

: INSTALL-FONT ( hfont -- )   HFONT !  HWND DUP GetDC ( dc)
   DUP DUP HFONT @ SelectObject DeleteObject DROP
   DUP FONTMETRICS /FONTSIZE  ( hwnd dc) ReleaseDC DROP
   /CARETSIZE ;

: /FONT ( -- )   /STOCKFONT  HFONT @ INSTALL-FONT ;

{ --------------------------------------------------------------------
Scroll bars

/SCROLL  makes the scroll bars proportional to the window/font size.
   Note that there is an implied limit of 64k lines here due to
   16 bit values used in the api.

UPDATE-SCROLLBARS sets the scroll position based on VTOP and VX.
-------------------------------------------------------------------- }

: /SCROLL ( -- )
   HWND SB_HORZ 0 COLS WIDE @ - 1 MAX 1 SetScrollRange DROP
   HWND SB_VERT 0 ROWS HIGH @ - 1 MAX 1 SetScrollRange DROP ;

: UPDATE-SCROLLBARS ( -- )
   HWND SB_VERT VTOP TOP - -1 SetScrollPos DROP
   HWND SB_HORZ VX @ -1 SetScrollPos DROP  ;

: RESCROLL ( -- )
   UPDATE-SCROLLBARS  REFRESH ;

: VIEWFROM ( x y -- )
    -CARET IN-SCROLLBACK ON  PAN  RESCROLL ;

: VSCROLL ( wparam -- )
   LOWORD CASE
      SB_BOTTOM        OF   ROWS                  ENDOF
      SB_LINEDOWN      OF    1                    ENDOF
      SB_LINEUP        OF   -1                    ENDOF
      SB_PAGEDOWN      OF   HIGH @ 1-             ENDOF
      SB_PAGEUP        OF   HIGH @ 1- NEGATE      ENDOF
      SB_THUMBPOSITION OF   WPARAM HIWORD TOP + VTOP - ENDOF
      SB_THUMBTRACK    OF   WPARAM HIWORD TOP + VTOP - ENDOF
      SB_TOP           OF   ROWS NEGATE           ENDOF
   ENDCASE  0 SWAP VIEWFROM ;

: HSCROLL ( -- )
   LOWORD CASE
      SB_BOTTOM        OF  COLS                   ENDOF
      SB_LINEDOWN      OF   1                     ENDOF
      SB_LINEUP        OF  -1                     ENDOF
      SB_PAGEDOWN      OF   8                     ENDOF
      SB_PAGEUP        OF  -8                     ENDOF
      SB_THUMBPOSITION OF  WPARAM HIWORD VX @ -   ENDOF
      SB_THUMBTRACK    OF  WPARAM HIWORD VX @ -   ENDOF
      SB_TOP           OF  COLS NEGATE            ENDOF
   ENDCASE  0 VIEWFROM ;

: WHEEL ( dir -- )
   0< IF  3  ELSE  -3  THEN  0 SWAP VIEWFROM ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: PAINTING ( -- )
   HWND PSTRUCT BeginPaint DC !
   HWND IsWindowVisible IF
      HWND IsIconic 0= IF
         DISPLAY
   THEN THEN
   HWND PSTRUCT EndPaint DROP  0 ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: DIFFERENT ( flag old new -- flag )
   @ TUCK OVER @ <> >R  !  R> OR ;

: RENDER? ( -- flag )
   0 OLDWIDE  WIDE DIFFERENT
     OLDHIGH  HIGH DIFFERENT
     OLDVY    VY   DIFFERENT
     OLDVX    VX   DIFFERENT ;

: RENDER ( -- )   UPDATE-SCROLLBARS REFRESH ;

{ --------------------------------------------------------------------
THE MOUSE POSITIONS NEED TO BE FULL VIRTUAL POSITIONS, NOT
CLAMPED TO BUFFER SIZE XY> IS NOT APPROPRIATE, AND THE REPAINT
WILL BE FLAWED ALSO
-------------------------------------------------------------------- }

: MXY>XY ( x y -- x y )
   CHARH @ / VTOP  +  0 MAX  ROWS 1- MIN >R
   CHARW @ / VLEFT +  0 MAX  COLS 1- MIN R> ;

: 'MOUSE ( -- vaddr )    \ position of mouse click in buffer
   PAD GetCursorPos DROP  HWND PAD ScreenToClient DROP
   PAD 2@  2DUP MX 2!  SWAP  MXY>XY XY>V ;

: INORDER ( point -- )
   MARK-ANCHOR @  2DUP U< IF SWAP THEN  MARK-BEGIN !  MARK-END ! ;

: LEFT-PRESS ( -- )
   #MARKED >R
   'MOUSE  DUP MARK-ANCHOR !  INORDER
   R> IF REFRESH THEN
   HWND SetCapture DROP
   MARKING ON ;

: STRETCHING ( -- )
   GetCapture HWND = IF
      #MARKED  'MOUSE INORDER  #MARKED <> IF REFRESH THEN
   THEN ;

: LEFT-RELEASE ( -- )
   DIRTY ON  ReleaseCapture DROP  MARKING OFF ;

{ --------------------------------------------------------------------
Double click response is to mark the word if one exists at the point
-------------------------------------------------------------------- }

: TEXT-CLICKED ( -- flag )
   'MOUSE VC@ BL <> ;

: MARK-WORD ( -- )   'MOUSE
   BEGIN ( vaddr)
      DUP WHILE  1- DUP VC@ BL =
   UNTIL 1+ THEN ( pointing to start of text now)
   DUP MARK-ANCHOR !  DUP MARK-BEGIN !
   BEGIN ( vaddr)
      1+ DUP VC@ BL =
   UNTIL  MARK-END ! ;

: DOUBLE-PRESS ( -- )
   TEXT-CLICKED IF  MARK-WORD RENDER THEN ;

{ --------------------------------------------------------------------
THIS USE OF STRETCHING IS BAD AND RECURSIVE
-------------------------------------------------------------------- }

: AUTOSCROLL ( -- )
   MY @ 0<       DUP IF  SB_LINEUP   LOOK-VERT STRETCHING THEN
   MX @ 0<       DUP IF  SB_LINEUP   LOOK-HORZ STRETCHING THEN
   MY @ WINH @ > DUP IF  SB_LINEDOWN LOOK-VERT STRETCHING THEN
   MX @ WINW @ > DUP IF  SB_LINEDOWN LOOK-HORZ STRETCHING THEN ;

: /TIMER ( -- )
   HWND 1 50 0 SetTimer DROP ;

: TIMER/ ( -- )
   $5555 HWND 1 KillTimer DROP DROP ;

: DO-TIMER ( -- )
   GetCapture HWND = IF  AUTOSCROLL  THEN
   DIRTY @ IF DIRTY OFF  RENDER? IF RENDER THEN THEN ;

{ --------------------------------------------------------------------
/WINDOWSIZE  saves the window size in the VAR structure

RESIZE takes care of fixing up the bottom of the screen if it was
made larger. Also, by calling /WINDOWSIZE remeasures the window.

RESIZING clips the window size when the user resizes it so that
it never exceeds the physical implementation limit of COLS. Having
this work requires that SF pass the message on to tty when it is
received, otherwize TTY will never get the WM_SIZING message.
-------------------------------------------------------------------- }

: /WINDOWSIZE ( -- )
   HWND RX0 GetClientRect DROP ;

: RESIZE ( -- )
   LPARAM IF
      HIDDEN-CARET @ >R  -CARET
      /WINDOWSIZE
      WINH @ YMARGIN - CHARH @ /  HIGH !
      WINW @ XMARGIN - CHARW @ /  WIDE !
      /SCROLL FRAMED
      VBOT EXPAND-Y
      REFRESH  R> 0= IF +CARET THEN
   THEN ;

: RESIZING ( -- )
   LPARAM @  LPARAM 2 CELLS + @  OVER -  COLS CHARW @ *  MIN  +
   LPARAM 2 CELLS + ! ;

{ --------------------------------------------------------------------
/METRICS does all the window measurements.
-------------------------------------------------------------------- }

: /METRICS ( -- )   /WINDOWSIZE /FONT /SCROLL ;

: CREATE-WINDOW ( -- )
   /VVARS /SELECTION /METRICS /SCROLL /TIMER /CARET ;

: DESTROY-WINDOW ( -- )
   TIMER/ CARET/ RECORDING/ VBUF/
   HWND GetParent 0= IF
      0 PostQuitMessage DROP
   THEN ;

{ --------------------------------------------------------------------
DOESNT RESPOND WHILE IN A NON-KEY WAIT MODE TO MARK ETC

: PARENT'S-MOUSE ( -- lparam )
   LPARAM LOHI SWAP PAD 2!
   HWND DUP GetParent PAD 1 MapWindowPoints DROP
   PAD 2@ SWAP LOHI-PACK ;

-------------------------------------------------------------------- }

: REFLECT ( -- res )   'MOUSE RB-PRESS !
   HWND GetParent MSG WPARAM LPARAM SendMessage DROP 0 ;

522 CONSTANT WM_MOUSEWHEEL

: IS-DIRTY ( -- )   DIRTY ON ;

: SYNC-CARET ( -- )   +CARET IS-DIRTY ;

\ ----------------------------------------------------------------------
\ ----------------------------------------------------------------------

: SETFGCOLOR ( color n -- )
   'XCOLOR 'FOREGROUNDS + !   -1 COLOR CELL+ ! ;

: SETBKCOLOR ( color n -- )
   'XCOLOR 'BACKGROUNDS + !  ;

\ ----------------------------------------------------------------------
\ ----------------------------------------------------------------------

\ define the primary windows message behavior for tty

[SWITCH TTY-MESSAGES DEFWINPROC

   WM_PAINT            RUN: PAINTING 0  ;
   WM_CREATE           RUN: CREATE-WINDOW 0  ;
   WM_DESTROY          RUN: DESTROY-WINDOW 0  ;
   WM_MOUSEWHEEL       RUN: WPARAM WHEEL 0  ;
   WM_VSCROLL          RUN: WPARAM VSCROLL RESCROLL 0  ;
   WM_HSCROLL          RUN: WPARAM HSCROLL RESCROLL 0  ;
   WM_TIMER            RUN: DO-TIMER 0  ;
   WM_SETFOCUS         RUN: ON-SETFOCUS 0  ;
   WM_KILLFOCUS        RUN: ON-KILLFOCUS 0  ;
   WM_ERASEBKGND       RUN: ERASEBK 1  ;
   WM_SIZE             RUN: RESIZE 0  ;
   WM_SIZING           RUN: RESIZING 1  ;
   WM_LBUTTONDBLCLK    RUN: DOUBLE-PRESS 0  ;
   WM_LBUTTONDOWN      RUN: LEFT-PRESS 0  ;
   WM_LBUTTONUP        RUN: LEFT-RELEASE 0  ;
   WM_RBUTTONDOWN      RUN: REFLECT  ;
   WM_RBUTTONDBLCLK    RUN: REFLECT  ;
   WM_RBUTTONUP        RUN: REFLECT  ;
   WM_MOUSEMOVE        RUN: STRETCHING 0  ;
   WM_KEYDOWN          RUN: WM-KEYDOWN  ;
   WM_CHAR             RUN: WM-CHAR  ;
   WM_SYSKEYDOWN       RUN: WM-SYSKEYDOWN  ;
   WM_SYSCHAR          RUN: WM-SYSCHAR  ;
   WM_COPY             RUN: TTY->CLIPBOARD 0  ;
   WM_PASTE            RUN: CLIPBOARD->TTY 0  ;
SWITCH]

\ ----------------------------------------------------------------------
\ extend the message behavior for our swiftforth interface


[+SWITCH TTY-MESSAGES
   TTY_FIRSTLINE  RUN: FIRST-LINE  ;
   TTY_NEXTLINE   RUN: NEXT-LINE  ;
   TTY_EMIT       RUN: -CARET  WPARAM PUTCHAR  IS-DIRTY  0  ;
   TTY_TYPE       RUN: -CARET  WPARAM LPARAM PUTS IS-DIRTY  0 ;
   TTY_WRAP       RUN: -CARET  WPARAM LPARAM WRAPS IF FRAMED THEN IS-DIRTY  0 ;
   TTY_CR         RUN: -CARET  PUTCRLF FRAMED IS-DIRTY 0 ;
   TTY_PAGE       RUN: -CARET PUT-PAGE FRAMED  REFRESH 0 ;
   TTY_NEW        RUN: -CARET NEW  FRAMED REFRESH 0 ;
   TTY_EKEY       RUN: SYNC-CARET  KEYBUF? IF  HIDDEN-CARET OFF  -CARET KEYBUF> ELSE -1 THEN ;
   TTY_EKEYQ      RUN: SYNC-CARET  KEYBUF? ;
   TTY_KEYMODE    RUN: WPARAM KEYMODE @  SWAP KEYMODE !  ;
   TTY_PUSHTEXT   RUN: WPARAM LPARAM PUSHTEXT 0 ;
   TTY_BREAK      RUN: /PASTE  0 HEAD ! 0 TAIL !  0 ;
   TTY_SETXY      RUN: -CARET WPARAM LOHI !XY  0 ;
   TTY_GETXY      RUN: @XY LOHI-PACK ;
   TTY_GETSIZE    RUN: WIDE @ HIGH @ LOHI-PACK ;
   TTY_COPYTEXT   RUN: #MARKED DUP IF  COPY-SELECTION  /MARKS  THEN  0=  ;
   TTY_GETWORD    RUN: #MARKED IF GET-MARKED-WORD /MARKS ELSE GET-CURSOR-WORD THEN ;
   TTY_SELECTALL  RUN: 0 TOP XY>V MARK-BEGIN !  0 BIGGEST-Y @ 1+ XY>V MARK-END !  REFRESH 0 ;
   TTY_SETFONT    RUN: WPARAM HFONT !  /METRICS  REFRESHBK  0 ;
   TTY_GETFONT    RUN: HFONT @ ;
   TTY_RECORDER   RUN: RECORDING/  WPARAM DUP IF /RECORDING THEN   ;
   TTY_CARETMODE  RUN: INSERTING @  WPARAM INSERTING !  /CARET IS-DIRTY ;
   TTY_SETFGCOLOR RUN: LPARAM  WPARAM  SETFGCOLOR  REFRESHBK 0 ;
   TTY_SETBKCOLOR RUN: LPARAM  WPARAM  SETBKCOLOR  REFRESHBK 0 ;
   TTY_USECOLOR   RUN: WPARAM COLOR ! 0  ;
   TTY_SETCARET   RUN: CARET/   WPARAM FIXED-CARET !  /CARETSIZE  ;
SWITCH]

\ ----------------------------------------------------------------------
\ define our callback routine

: TTY-DISPATCH ( -- res )
   VBUF-ENTRY IF
      MSG LOWORD TTY-MESSAGES EXIT
   THEN
   MSG WM_NCCREATE = IF  /VBUF  THEN
   DEFWINPROC ;

' TTY-DISPATCH 4 CB: TTY-CALLBACK

{ --------------------------------------------------------------------
Register the class
-------------------------------------------------------------------- }

PUBLIC

: "TTY"   Z" TTY" ;

: REGISTER-TTY ( -- )
   CS_DBLCLKS  CS_OWNDC OR  CS_GLOBALCLASS OR
   TTY-CALLBACK                         \ callback
   0                                    \ class extra
   2 CELLS                              \ window extra
   HINST                                \ hinstance
   HINST 101 LoadIcon                   \ icon
   NULL IDC_ARROW LoadCursor            \ cursor
   GRAY_BRUSH GetStockObject            \ background brush
   0                                    \ no menu
   "TTY"                                \ class name
   DefineClass DROP ;

PRIVATE

