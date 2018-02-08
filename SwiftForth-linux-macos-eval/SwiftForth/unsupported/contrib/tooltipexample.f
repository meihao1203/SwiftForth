{ ================================================================
ToolTip Support

Created 6/25/02 by Mike Ghan
Released into the Public Domain  2/25/2007 Mike Ghan

================================================================= }

CLASS tagNMTTDISPINFO
   VARIABLE .hwndFrom  \ window handle of control sending message
   VARIABLE .idFrom    \ identifier of control sending message
   VARIABLE .code      \ specifies the notification code
   VARIABLE .lpszText  \ Pointer to a string for a tool.
   80 BUFFER: .szText  \ Alternate Buffer for Text
   VARIABLE .hinst     \ If lpszText is used, this member is NULL.
   VARIABLE .uFlags    \ how to interpret the idFrom member
   VARIABLE .lParam    \ See current API
END-CLASS

CLASS TOOLINFO
   VARIABLE .cbSize    \ Size of this structure, in bytes
   VARIABLE .uFlags    \ Flags that control the tooltip display
   VARIABLE .hwnd      \ Handle to the window that contains the tool
   VARIABLE .uId       \ Application-defined identifier of the tool
   RECT BUILDS .rect   \ Tool's bounding rectangle coordinates
   VARIABLE .hinst     \ Handle to the instance (for Resources)
   VARIABLE .lpszText  \ Pointer to the buffer that contains the text for the tool
   VARIABLE .lParam    \ A 32-bit appl-defined value that is associated with the tool

   : CONSTRUCT  ( -- )  [ THIS SIZEOF ] LITERAL ADDR OVER ERASE .cbSize ! ;

END-CLASS

CREATE zTOOLTIPS_CLASS ,Z" tooltips_class32"

TTN_FIRST 0 - CONSTANT TTN_NEEDTEXT
TTN_FIRST 0 - CONSTANT TTN_GETDISPINFOA  \ Same
TTN_FIRST 1 - CONSTANT TTN_SHOW
TTN_FIRST 2 - CONSTANT TTN_POP

$010 CONSTANT TTS_NOANIMATE
$020 CONSTANT TTS_NOFADE
$040 CONSTANT TTS_BALLOON

-1 CONSTANT LPSTR_TEXTCALLBACK  \ Use CallBack TTN_NEEDTEXT Notification


\ ****************************************************************************
\  Tooltip Control Tools
\ ****************************************************************************

VARIABLE TT-BALLOON?

\ TT-BALLOON? ON

: TT-STYLE  ( -- styleBits)
   WS_POPUP TTS_NOPREFIX OR TTS_ALWAYSTIP OR
   TT-BALLOON? @ 0<> TTS_BALLOON AND OR ;

: CREATE-TOOLTIP-CONTAINER  ( hOwner -- hTooltipContainer )
   >R ( Stash hToolTipContainer )
   0 ( Ext Style ) zTOOLTIPS_CLASS NULL TT-STYLE
   CW_USEDEFAULT DUP 2DUP ( x y w h )
   R> ( hOwner ) NULL ( id ) HINST NULL CreateWindowEx ( hTooltip )
   [OBJECTS RECT MAKES RCT  OBJECTS]
   SM_CXBORDER GetSystemMetrics 2* DUP RCT left ! RCT right !
   SM_CYBORDER GetSystemMetrics 2* DUP RCT top !  RCT bottom !
   DUP ( hWnd ) TTM_SETMARGIN 0 RCT ADDR SendMessage DROP ;

: ADD-TOOLTIP-WIN  ( zText hTippedWnd hOwner hTooltipContainer -- )
   [OBJECTS  TOOLINFO MAKES MY-TOOL  OBJECTS]
   >R ( Stash hToolTipContainer )
   TTF_IDISHWND TTF_SUBCLASS OR  MY-TOOL .uFlags !
   ( hOwner )     MY-TOOL .hwnd  !
   ( hTippedWnd ) MY-TOOL .uId !
   ( zText )      MY-TOOL .lpszText !
   R> ( hTooltipContainer ) TTM_ADDTOOLA 0  MY-TOOL ADDR SendMessage DROP ;

: ADD-TOOLTIP-CTL  ( zText CtlId hOwner hTooltipContainer -- )
   ROT >R OVER R> ( ID) GetDlgItem ( Hdl) -ROT  ADD-TOOLTIP-WIN ;


: CHANGE-TOOLTIP-TXT  ( zText hTippedWnd hOwner hTooltipContainer -- )
   [OBJECTS  TOOLINFO MAKES MY-TOOL  OBJECTS]
   >R ( Stash hToolTipContainer )
   TTF_IDISHWND TTF_SUBCLASS OR  MY-TOOL .uFlags !
   ( hOwner )     MY-TOOL .hwnd  !
   ( hTippedWnd ) MY-TOOL .uId !
   ( zText )      MY-TOOL .lpszText !
   R> ( hTooltipContainer ) TTM_UPDATETIPTEXTA  0  MY-TOOL ADDR SendMessage DROP ;

\ Change Tip Text for a Rectangular Tooltip
: CHANGE-TOOLTIP-RECT-TXT  ( zText ID hOwner hTooltipContainer -- )
   [OBJECTS  TOOLINFO MAKES MY-TOOL  OBJECTS]
   >R ( Stash hToolTipContainer )
   TTF_SUBCLASS MY-TOOL .uFlags !
   ( hOwner )  MY-TOOL .hwnd  !
   ( ID )      MY-TOOL .uId !
   ( zText )   MY-TOOL .lpszText !
   R> ( hTooltipContainer ) TTM_UPDATETIPTEXTA  0  MY-TOOL ADDR SendMessage DROP ;


: ADD-TOOLTIP-RECT  ( zText left top right bottom ID hOwner hTooltipContainer -- )
   [OBJECTS  TOOLINFO MAKES MY-TOOL  OBJECTS]
   >R ( Stash hToolTipContainer )
   TTF_SUBCLASS  MY-TOOL .uFlags !
   ( hOwner )    MY-TOOL .hwnd  !
   ( ID )        MY-TOOL .uId !
   ( bottom )    MY-TOOL .rect bottom !
   ( right  )    MY-TOOL .rect right !
   ( top    )    MY-TOOL .rect top !
   ( left   )    MY-TOOL .rect left !
   ( zText )     MY-TOOL .lpszText !
   R> ( hTooltipContainer ) TTM_ADDTOOLA 0  MY-TOOL ADDR SendMessage DROP ;


\ ****************************************************************************
\  Default Tooltip Notify
\ ****************************************************************************

\ CREATE TT-MARGIN 4 , 4 , 4 , 4 ,  ( left top right bottom )

: DEFAULT-TOOLTIP-NOTIFY  ( -- )
   LPARAM USING tagNMTTDISPINFO .hwndFrom @
  \ DUP TTM_SETMARGIN 0 TT-MARGIN SendMessage DROP   \ Not Working - Balloon?
   TTM_SETMAXTIPWIDTH 0 300 SendMessage DROP
   ;



\ Examples:

\ *******************************************************
\  Window Example
\ *******************************************************

GENERICWINDOW SUBCLASS TTWINDOW

   SINGLE hWND-TT

   VARIABLE #FINDS

   : INIT-WIN  ( -- )
      Z" This is the Window Tooltip Text!"
      mHWND mHWND hWND-TT ADD-TOOLTIP-WIN ;

   : INIT-RECT  ( -- )
      Z" This is the first rect Tooltip"
      10  10 80  100  ( x1 y1 x2 y2 )
      101 ( ID ) mHWND hWND-TT ADD-TOOLTIP-RECT
      Z" This is the second rect Tooltip"
      100 10 150 100  ( x1 y1 x2 y2 )
      102 ( ID ) mHWND hWND-TT ADD-TOOLTIP-RECT ;

   : INIT-NEEDTEXT  ( -- )
      LPSTR_TEXTCALLBACK
      10  10 150  150  ( x1 y1 x2 y2 )
      101 ( ID ) mHWND hWND-TT ADD-TOOLTIP-RECT ;

   : GET-BTN-TIP-TEXT  ( btnID -- ztext )  \ Called by WM_NOTIFY
      101 =
      IF  1 #FINDS +!
         S" You found me " PAD ZPLACE #FINDS @ (.) PAD ZAPPEND
         S\" times!\nLucky You" PAD ZAPPEND PAD
      ELSE  Z" Huh?"  THEN ;

   WM_NOTIFY  MESSAGE:  ( -- res )
      LPARAM 2 CELLS + @ ( Notification code )
      TTN_NEEDTEXT = ( Need tip text? )
      IF  DEFAULT-TOOLTIP-NOTIFY
          LPARAM [OBJECTS  tagNMTTDISPINFO NAMES TT  OBJECTS]
          TT .idFrom @ GET-BTN-TIP-TEXT  TT .lpszText !
      THEN
      0 ( res ) ;


   WM_CREATE MESSAGE: ( -- res )
      mHWND CREATE-TOOLTIP-CONTAINER TO hWND-TT
      0 ( res ) ;

   : TITLE ( -- z )   Z" TestWindow" ;

   : MyClass_Style ( -- n )
      CS_OWNDC CS_HREDRAW OR CS_VREDRAW OR ;

   : MyClass_ClassName ( -- z )   TITLE ;
   : MyWindow_WindowName ( -- z )   TITLE ;

   : OnPaint ( -- res )
      [OBJECTS PAINTCANVAS MAKES DC  RECT MAKES R  OBJECTS]
      mHWND DC ATTACH
      mHWND R ADDR GetClientRect
      DC HDC  S" TOOLTIPS " R ADDR DT_SINGLELINE DT_VCENTER OR DT_CENTER OR
      DrawText DROP
      DC DETACH ;

   [DEFINED] CLASS-CALLBACK-DEBUG [IF]
   : MyClass_WndProc     CLASS-CALLBACK-DEBUG ;
   [THEN]


END-CLASS

TTWINDOW BUILDS FOO

\ Tooltip in rectangle at 10 10 80 100 and 100 10 150 100
: DEMO-RECT  FOO CONSTRUCT  FOO INIT-RECT ;

\ Tooltip in entire window
: DEMO-WIN   FOO CONSTRUCT  FOO INIT-WIN ;

\ Tooltip in rectangle at 10 10 80 100 and 100 10 150 100
: DEMO-NEEDTEXT  FOO CONSTRUCT  FOO INIT-NEEDTEXT ;

: X  DEMO-NEEDTEXT ;


\ *******************************************************
\  Dialog Example
\ *******************************************************

DIALOG DLG-TMPL
[MODAL " Test Dialog" 20 20 140 60
 (CLASS SFDLG) (FONT 8, MS Sans Serif) (+STYLE WS_SYSMENU DS_CENTER) ]
 [RTEXT             " # of Widgets"    101      4    6    64   10 ]
 [EDITTEXT                             102      72   6    36   10 ]
 [DEFPUSHBUTTON     " OK"              IDOK     4    40   40   14 ]
 [PUSHBUTTON        " Test"            103      50   40   40   14 ]
 [PUSHBUTTON        " Cancel"          IDCANCEL 94   40   40   14 ]
END-DIALOG

GENERICDIALOG SUBCLASS TEST-DIALOG

   : TEMPLATE ( -- addr )   DLG-TMPL ;

   SINGLE hWND-TT  \ Tooltip Handle

   : ADD-TIP-CTL  ( zText CtlId -- )
      HWND SWAP ( ID) GetDlgItem HWND hWND-TT ADD-TOOLTIP-WIN ;

   : INIT-TIPS  ( -- )
      HWND CREATE-TOOLTIP-CONTAINER TO hWND-TT  hWND-TT
      IF Z" Exit Report Designer"                     IDOK       ADD-TIP-CTL
         Z" Cancel Screen"                            IDCANCEL   ADD-TIP-CTL
         Z" Test Widget Production"                   103        ADD-TIP-CTL
         Z" Enter the Number of Widget Required"      102        ADD-TIP-CTL
      THEN ;

   WM_INITDIALOG MESSAGE: ( -- res )
      INIT-TIPS
      TRUE ( Windows sets focus ) ;

   IDOK COMMAND:  ( -- )
      ;

   IDCANCEL COMMAND:
      0 CLOSE-DIALOG ;

END-CLASS

: DEMO-DLG  ( -- data|0 )
   [OBJECTS  TEST-DIALOG MAKES DLG  OBJECTS]
   HWND  DLG MODAL ;

CR .( Type DEMO-WIN  for Simple Window Demo)
CR .( Type DEMO-RECT for Window Rectangle Demo)
CR .( Type DEMO-DLG  for Dialog Demo)
CR
