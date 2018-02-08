{ ====================================================================
SWOOP Class Browser

Copyright 2010  FORTH, Inc. and Rick VanNorman
==================================================================== }

OPTIONAL CLASSBROWSER A rudimentary class browser for SWOOP

{ ====================================================================
This file implements a rudimentary class browser for SWOOP.  It uses
SWOOP for its starting point, and builds a single window with a
treeview on the left and a contents viewer on the right to browse the
SWOOP class hierarchy.
==================================================================== }

{ --------------------------------------------------------------------
Define an editor control to display class member names in.

HED is a handle to the edit control and
ED_CONTROL is a windows id for it.
-------------------------------------------------------------------- }

0 VALUE HED

98 CONSTANT ED_CONTROL

0 WS_CHILD       OR
  WS_VISIBLE     OR
  WS_BORDER      OR
  WS_VSCROLL     OR
  ES_NOHIDESEL   OR
  ES_LEFT        OR
  ES_AUTOVSCROLL OR
  ES_READONLY    OR
  ES_MULTILINE   OR
CONSTANT ED_STYLE

: CREATE-EDCONTROL ( hparent -- hwnd )   >R
   WS_EX_CLIENTEDGE  Z" edit" 0 ED_STYLE 0 0 0 0
   R> ED_CONTROL HINST 0 CreateWindowEx ;

{ --------------------------------------------------------------------
TreeView data structures; adapted from info in the Win32API.
-------------------------------------------------------------------- }

CLASS TV_ITEM
   VARIABLE mask
   VARIABLE hItem
   VARIABLE state
   VARIABLE stateMask
   VARIABLE pszText
   VARIABLE cchTextMax
   VARIABLE iImage
   VARIABLE iSelectedImage
   VARIABLE cChildren
   VARIABLE lParam
END-CLASS

CLASS TV_INSERTSTRUCT
   VARIABLE hParent
   VARIABLE hInsertAfter
   VARIABLE mask
   VARIABLE hItem
   VARIABLE state
   VARIABLE stateMask
   VARIABLE pszText
   VARIABLE cchTextMax
   VARIABLE iImage
   VARIABLE iSelectedImage
   VARIABLE cChildren
   VARIABLE lParam
END-CLASS

CLASS TV_DISPINFO
   NMHDR BUILDS HDR
   TV_ITEM BUILDS ITEM
END-CLASS

CLASS NM_TREEVIEW
   NMHDR BUILDS HDR
   VARIABLE ACTION
   TV_ITEM BUILDS ITEMOLD
   TV_ITEM BUILDS ITEMNEW
   POINT BUILDS ptDrag
END-CLASS

{ --------------------------------------------------------------------
Define a method to instantiate a treeview control
-------------------------------------------------------------------- }

\ define our specific style requirements for the common control

0 WS_VISIBLE OR
  WS_CHILD OR
  WS_BORDER OR
  TVS_SHOWSELALWAYS OR
  TVS_HASLINES OR
  TVS_EDITLABELS OR
  TVS_LINESATROOT OR
  TVS_HASBUTTONS OR
CONSTANT TV_STYLE

99 CONSTANT TV_CONTROL

: CREATE-TREEVIEW ( hparent -- hwnd )   >R
   WS_EX_CLIENTEDGE Z" SysTreeView32"  0 TV_STYLE 0 0 0 0
   R> TV_CONTROL HINST 0 CreateWindowEx ;

{ --------------------------------------------------------------------
Add items to the treeview.

TREEVIEW_ADDNODE adds a single item to the list.

SHOWCHILDREN adds all the children of a class under the given parent
node. It is recursive, and traverses the list of classes. Note that
CLASSES is a variable in the OOP wordlist, but is a word which displays
the class hierarchy in the FORTH wordlist. Gotcha!

SHOWCLASSES inserts SUPREME as the root of the treeview, and then
recursively inserts all of the other defined classes.
-------------------------------------------------------------------- }

0 VALUE HTV

: TREEVIEW_ADDNODE ( classhandle parent prev -- handle )
   [OBJECTS TV_INSERTSTRUCT MAKES TVIS OBJECTS]
   TVIS hInsertAfter !   TVIS hParent !   0 TVIS hItem !
   TVIF_PARAM TVIF_TEXT OR TVIS mask !  TVIS lParam !
   LPSTR_TEXTCALLBACKA TVIS pszText ! \ callback to provide text
   HTV TVM_INSERTITEMA 0 TVIS ADDR SendMessage ;

OOP +ORDER

: SHOWCHILDREN ( class parent -- )   >R
   CLASSES BEGIN
      @REL ?DUP WHILE   \ address of class, not handle of class!
      2DUP 2 CELLS + @ = IF
         DUP BODY> R@ 0 TREEVIEW_ADDNODE
         OVER BODY> SWAP RECURSE
      THEN
   REPEAT DROP R> DROP ;

: SHOWCLASSES ( -- )
   SUPREME 0 0 TREEVIEW_ADDNODE >R
   SUPREME R@ SHOWCHILDREN
   HTV TVM_SELECTITEM TVGN_CARET R> SendMessage DROP
   HTV SetFocus DROP ;

{ ----------------------------------------------------------------------
WRITE-BUF appends a string to the cell-counted data in a buffer.

MEMBER-HEADER is used to form and append a member-type partition
indicators like "PUBLIC" and "PRIVATE" to the buffer.

SHOW-MEMBER-LIST appends the name of all members of the specified type
to the buffer.

SHOW-MEMBER-IDS appends the name of all windows messages of the
specified type to the buffer. It uses the function FindWM (which is
in the wincon.dll file) to do the reverse lookup.

SHOWMEMBERS displays the member names of a given class by typing them
all to a buffer then setting the text field of the HED window to that
string.
---------------------------------------------------------------------- }

: WRITE-BUF ( addr len buf -- )
   2DUP 2>R  @+ + SWAP CMOVE  2R> +! ;

: MEMBER-HEADER ( ztitle buf -- )   >R
   <EOL> COUNT R@ WRITE-BUF
   S" ======= " R@ WRITE-BUF
   ZCOUNT R@ WRITE-BUF
   S" ======= " R@ WRITE-BUF
   <EOL> COUNT R@ WRITE-BUF
   R> DROP ;

: SHOW-MEMBER-LIST ( head ztitle buffer -- )   >R
   R@ MEMBER-HEADER DUP BEGIN
      @REL DUP WHILE
      2DUP < WHILE
      DUP CELL+ @ >NAME COUNT R@ WRITE-BUF
      S"  " R@ WRITE-BUF
   REPEAT THEN 2DROP
   <EOL> COUNT R> WRITE-BUF ;

: SHOW-MEMBER-IDS ( head ztitle buffer -- )   >R
   R@ MEMBER-HEADER DUP BEGIN
      @REL DUP WHILE
      2DUP < WHILE
      DUP CELL+ @  DUP (.) R@ WRITE-BUF
      FindWM ?DUP IF
         S"  (" R@ WRITE-BUF  ZCOUNT R@ WRITE-BUF S" ) " R@ WRITE-BUF
      ELSE  S"  " R@ WRITE-BUF  THEN
   REPEAT THEN 2DROP
   <EOL> COUNT R> WRITE-BUF ;

: SHOWMEMBERS ( class -- )
   4096 R-ALLOC >R   R@ OFF
   DUP >PUBLIC     Z" PUBLIC"    R@ SHOW-MEMBER-LIST
   DUP >PROTECTED  Z" PROTECTED" R@ SHOW-MEMBER-LIST
   DUP >PRIVATE    Z" PRIVATE"   R@ SHOW-MEMBER-LIST
       >ANONYMOUS  Z" ANONYMOUS" R@ SHOW-MEMBER-IDS
   0 R@ @+ + C!
   HED WM_SETTEXT 0 R> CELL+ SendMessage DROP ;

OOP -ORDER

{ --------------------------------------------------------------------
TV-NOTIFY passes selected TVN (tree view notification) messages to
our treeview.
-------------------------------------------------------------------- }

: TV-NOTIFY ( 'nmhdr code -- )
   CASE
      TVN_GETDISPINFOA OF   [OBJECTS TV_DISPINFO NAMES TV OBJECTS]
         TV ITEM lParam @  >NAME 1+ TV ITEM pszText !  ENDOF
      TVN_SELCHANGEDA OF    [OBJECTS NM_TREEVIEW NAMES TV OBJECTS]
         TV ITEMNEW lParam @ SHOWMEMBERS ENDOF
   ENDCASE ;

{ --------------------------------------------------------------------
Here we use the GENERICWINDOW framework to build a dual pane window for
the treeveiw display.
-------------------------------------------------------------------- }

GENERICWINDOW SUBCLASS CLASSBROWSING

   : "BROWSING" ( -- z )   Z" SWOOPBrowser" ;

   : MyWindow_Shape ( -- x y x y )   100 40 500 300 ;
   : MyClass_hbrBackground ( -- hbrush )   GRAY_BRUSH GetStockObject ;
   : MyClass_ClassName ( -- z )   "BROWSING" ;
   : MyWindow_WindowName ( -- z )   "BROWSING" ;

   \ handle of treeview control
   VARIABLE LEFT-CHILD
   VARIABLE RIGHT-CHILD
   VARIABLE DIVIDES

   \ storage for our rectangle
   RECT BUILDS CLIENT

   : SIZE-LEFT ( -- )
      LEFT-CHILD @ 0 0 DIVIDES @ 2 - CLIENT bottom @
      -1 MoveWindow DROP ;

   : SIZE-RIGHT ( -- )
      RIGHT-CHILD @ DIVIDES @ 0
      CLIENT right @ DIVIDES @ - CLIENT bottom @
      -1 MoveWindow DROP ;

   \ when the main window is created, make another window
   \ in it, using the main window as a container. Then initialize
   \ the treeview.
   WM_CREATE MESSAGE: ( -- res )   0
      mHWND CREATE-TREEVIEW  DUP LEFT-CHILD ! TO HTV
      mHWND CREATE-EDCONTROL DUP RIGHT-CHILD ! TO HED
        250 DIVIDES !  SHOWCLASSES ;

   \ when the main window changes size, the treeview does too.
   WM_SIZE MESSAGE: ( -- res )   0
      mHWND CLIENT ADDR GetClientRect DROP
      SIZE-LEFT SIZE-RIGHT  ;

   WM_NOTIFY MESSAGE: ( -- res )
      LPARAM [OBJECTS NMHDR NAMES HDR OBJECTS]
      HDR idFrom @ TV_CONTROL = IF
         HDR ADDR  HDR code @ TV-NOTIFY
      THEN 0 ;

   : SPLIT-RESIZE ( -- )
      WPARAM MK_LBUTTON AND IF
         LPARAM LOWORD DIVIDES !
         SIZE-LEFT SIZE-RIGHT
      THEN ;

   : CURSED ( -- )
         0 IDC_SIZEWE LoadCursor SetCursor DROP EXIT
      LPARAM LOWORD DIVIDES @ - ABS 4 / 0= IF
      THEN ;

   WM_LBUTTONDOWN MESSAGE: mHWND SetCapture DROP  0 ;
   WM_LBUTTONUP   MESSAGE: ReleaseCapture DROP 0 ;
   WM_MOUSEMOVE   MESSAGE: CURSED SPLIT-RESIZE 0 ;

END-CLASS

{ --------------------------------------------------------------------
Build an instance of the classbroswer and a word to run it.
-------------------------------------------------------------------- }

CLASSBROWSING BUILDS CLASSBROWSER

: CLB ( -- )   CLASSBROWSER CONSTRUCT ;

.(
Type CLB to run the class browser.
)
