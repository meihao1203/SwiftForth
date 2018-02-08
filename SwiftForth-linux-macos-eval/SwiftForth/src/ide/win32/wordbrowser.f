{ ====================================================================
Wordlist browser tool

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

Toggle Window contributed by Mike Ghan
==================================================================== }

{ --------------------------------------------------------------------
An edit box for the words themselves
an edit line for a filter
a combo box for the vocs and wids
a pair of buttons for containing, starts with (or one?)
a pair of buttons for all or selected wid
a close button
-------------------------------------------------------------------- }

PACKAGE WORD-BROWSER

PRIVATE

{ --------------------------------------------------------------------
The name, message switch, callback, and class for the dialog.
Note that you must declare DLGWINDOWEXTRA in the window extra field.
-------------------------------------------------------------------- }

CREATE WordsName ,Z" Browser"

[SWITCH BROWSE-MESSAGES DEFWINPROC ( -- res )   SWITCH]

:NONAME ( -- res )   MSG LOWORD BROWSE-MESSAGES ;  4 CB: RUNBROWSE

: /BROWSE-CLASS ( -- hclass )
      0 CS_OWNDC   OR
        CS_HREDRAW OR
        CS_VREDRAW OR                \ class style
      RUNBROWSE                      \ wndproc
      0                              \ class extra
      DLGWINDOWEXTRA                 \ window extra
      HINST                          \ hinstance
      HINST 101 LoadIcon             \ icon
      NULL IDC_ARROW LoadCursor      \ cursor
      COLOR_BTNFACE 1+               \ background brush
      0                              \ no menu
      WordsName                      \ class name
   DefineClass ;

{ --------------------------------------------------------------------
first, the dialog. Modeless, of course.

We use ENUM so we don't have to keep up with numbers...
-------------------------------------------------------------------- }

1000 ENUM _STARTING
     ENUM _CONTAINS
     ENUM _WORDS
     ENUM _FILTER
     ENUM _REFRESH
     ENUM _VOCS
     ENUM _LOCBUF
     ENUM _SIZEGROUP
DROP

DIALOG (BROWSE)
   [MODELESS  " Words"  (CLASS Browser)     10  10  400 200
      (FONT 8, MS Sans Serif)  (+STYLE WS_OVERLAPPEDWINDOW) ]

[GROUPBOX                       _SIZEGROUP   0   0  270  34
                                        (-STYLE WS_VISIBLE) ]
[GROUPBOX        " Words that " -1           2   2  130  30 ]
[AUTORADIOBUTTON " Start with"  _STARTING    5  10   60  10 ]
[AUTORADIOBUTTON " Contain"     _CONTAINS    5  20   60  10 ]
[EDITTEXT                       _FILTER     65  13   60  12 (+STYLE ES_AUTOHSCROLL) ]
[GROUPBOX        " Vocabulary"  -1         135   2   90  30 ]
[COMBOBOX                       _VOCS      140  13   80 180
           (+STYLE CBS_DROPDOWN WS_VSCROLL CBS_AUTOHSCROLL)
                                        (-STYLE CBS_SIMPLE) ]
[EDITBOX                        _WORDS       2  50  396 125
   (+STYLE ES_AUTOVSCROLL WS_VSCROLL WS_BORDER ES_READONLY)
                                        (-STYLE WS_TABSTOP) ]
[DEFPUSHBUTTON   " &Refresh"    _REFRESH   230   2   40  13 ]
[PUSHBUTTON      " &Close"       IDOK      230  18   40  13 ]
[EDITTEXT                       _LOCBUF    -40 -40   40  13
                (+STYLE ES_AUTOHSCROLL) (-STYLE WS_VISIBLE) ]

END-DIALOG

{ --------------------------------------------------------------------
We subclass the _WORDS edit control so we can monitor the doubleclick
messages and do locate
-------------------------------------------------------------------- }

0 VALUE OLDEDITPROC
0 VALUE HLOCBUF

: DEF-EDIT-MESSAGE ( n -- res )
   DROP OLDEDITPROC HWND MSG WPARAM LPARAM CallWindowProc ;

CREATE CLICKBUF  256 ALLOT

: DOUBLECLICK ( -- res )
   0 DEF-EDIT-MESSAGE >R
   HWND WM_COPY 0 0 SendMessage DROP
   HLOCBUF WM_SETTEXT 0 0 SendMessage DROP
   HLOCBUF WM_PASTE 0 0 SendMessage DROP
   HLOCBUF WM_GETTEXT 255 CLICKBUF SendMessage
   HCON WM_COMMAND MI_XLOCATE CLICKBUF PostMessage DROP
   R> ;

[SWITCH EDITBOX-MESSAGES DEF-EDIT-MESSAGE
   WM_LBUTTONDBLCLK RUNS DOUBLECLICK
SWITCH]

:NONAME ( -- res )   MSG LOWORD EDITBOX-MESSAGES ;  4 CB: NEWEDITPROC

: SUBCLASS-EDITBOX ( -- )   HWND _WORDS GetDlgItem
   GWL_WNDPROC NEWEDITPROC SetWindowLong TO OLDEDITPROC ;


{ --------------------------------------------------------------------

WBUF is the address of allocated memory to hold the words list while
it is being generated, before it is displayed.  We could display the
words one at a time, but this is much faster.

SET-FILTER  reads the text from the edit box that holds the user's
text filter.  An empty string returns length=0. All filtering is
done as non-case-sensitive, so the string is UPCASE d.

EDIT.ID formats a word's name into the WBUF for later display.

DISPLAY-WBUF transfers the contents of WBUF to the edit control.

FILL-WORDLIST gets the current wordlist WID from the VOCS control and
generates a list of its words based on the filtering criteria.

-------------------------------------------------------------------- }

0 VALUE WBUF

: >WBUF ( addr n -- )
   WBUF ZAPPEND ;

CREATE "FILTER 256 ALLOT

: SET-FILTER ( -- )
   HWND _FILTER "FILTER 1+ 255 GetDlgItemText "FILTER C!
   "FILTER COUNT UPCASE ;

: EDIT.ID ( nt -- )
   COUNT >WBUF  S"  " >WBUF ;

: DISPLAY-WBUF
   HWND _WORDS WM_SETTEXT  0 WBUF  SendDlgItemMessage DROP ;

VARIABLE /CONTAINING
VARIABLE #WORDS

: -FILTER ( nt -- flag )
   COUNT "FILTER COUNT /CONTAINING @ IF
      ROT MIN DUP -ROT THEN  -MATCH NIP ;

: EDIT.NAME ( nt -- flag )
   "FILTER C@ IF
      DUP -FILTER IF  DROP TRUE EXIT
   THEN THEN  EDIT.ID  #WORDS ++ TRUE ;

: ONE-WORDLIST ( wid -- )
   ?DUP IF  ['] EDIT.NAME SWAP TRAVERSE-WORDLIST  THEN ;

: ONE-WORDLIST-NAME ( n -- )   >R
   <EOL> COUNT >WBUF  S" ***** " >WBUF
   HWND _VOCS CB_GETLBTEXT R> WBUF ZCOUNT + SendDlgItemMessage DROP
   S"  *****" >WBUF  <EOL> COUNT >WBUF ;

: ALL-WORDLISTS ( -- )
   HWND _VOCS CB_GETCOUNT 0 0 SendDlgItemMessage 0 ?DO
      I ONE-WORDLIST-NAME
      HWND _VOCS CB_GETITEMDATA I 0 SendDlgItemMessage ONE-WORDLIST
   LOOP ;

: RETITLE
   256 R-ALLOC >R
   #WORDS @ (.) R@ ZPLACE
   S"  Words" R@ ZAPPEND
   HWND WM_SETTEXT 0 R> SendMessage DROP ;

: SET-SELECTED-VOC ( item -- )
   >R HWND _VOCS CB_SETCURSEL R> 0 SendDlgItemMessage DROP ;

: GET-SELECTED-VOC ( -- item )
   HWND _VOCS CB_GETCURSEL 0 0 SendDlgItemMessage ;

: GET-SELECTED-WID ( -- wid )
   HWND _VOCS CB_GETITEMDATA  GET-SELECTED-VOC  0 SendDlgItemMessage ;

: FILL-WORDLIST ( -- )
   SET-FILTER  0 WBUF !  #WORDS OFF
   HWND _WORDS 0 SetDlgItemText DROP
   GET-SELECTED-WID ?DUP IF  ONE-WORDLIST ELSE ALL-WORDLISTS THEN
   DISPLAY-WBUF RETITLE ;

{ --------------------------------------------------------------------

EDIT.VOC adds the name of a vocabulary to the VOCS control and the WID
associated with it to the item's data field.

FILL-VOCLIST adds all known vocabularies to the VOCS control, then
selects the last one (which I know will be FORTH) as the initial
current selection.

-------------------------------------------------------------------- }

0 0 2CONSTANT *ALL*  \ a dummy to indicate searching all vocabularies

: EDIT.VOC ( nt -- )
   >R HWND _VOCS CB_ADDSTRING 0 R@ 1+ SendDlgItemMessage >R
   HWND _VOCS CB_SETITEMDATA R> R> NAME> >BODY CELL+ @
   SendDlgItemMessage DROP ;

: FILL-VOCLIST
   HWND _VOCS CB_RESETCONTENT 0 0 SendDlgItemMessage DROP
   ['] .ID >BODY @ >R
   ['] EDIT.VOC IS .ID
   VOCS
   OPERATOR CONTEXT HIS @
   HWND _VOCS CB_GETCOUNT 0 0 SendDlgItemMessage 0 DO
      HWND _VOCS CB_GETITEMDATA I 0 SendDlgItemMessage
      OVER = IF  I SET-SELECTED-VOC  THEN
   LOOP DROP
   ['] *ALL* >NAME .ID
   R> IS .ID ;

{ --------------------------------------------------------------------

RESIZE-WORDS resizes the WORDS edit control to track the size of the
dialog.

BROWSE-CLOSE disposes of WBUF and destroys the dialog.

BROWSE-INIT allocates memory for WBUF, sets the pretty icon, checks
and unchecks the right boxes, fixes up the size of the edit control.
Then, it grabs the full VLINK list, sets the local context to FORTH,
and displays the words in FORTH.

SET-MINMAX-INFO guarantees that the size of the dialog will never go
below a certain point.

?FILTER-UNFOCUS updates the wordlist after the filter control loses
focus.

-------------------------------------------------------------------- }

CREATE BROWSEORG   5 CELLS /ALLOT

CONFIG: WORD-BROWSER ( -- addr len )   BROWSEORG 5 CELLS ;

: SIZEGROUP ( -- x y )
   HWND _SIZEGROUP GetDlgItem PAD GetClientRect DROP
   PAD 2 CELLS + 2@ SWAP ;

: RESIZE-WORDS ( x y -- res )
   SIZEGROUP PAD ! DROP
   >R >R HWND _WORDS GetDlgItem
   2  PAD @  R> 4 -  R> PAD @ -  1 MoveWindow DROP ;

: BROWSE-CLOSE ( -- res )
   WBUF FREE DROP  0 TO WBUF  (BROWSE) CELL- OFF  BROWSEORG OFF
   HWND DestroyWindow  REBUTTON ;

: BROWSE-INIT ( -- )
   SUBCLASS-EDITBOX   HWND _LOCBUF GetDlgItem TO HLOCBUF
   BROWSEORG 3 CELLS + 2@ OR IF BROWSEORG CELL+ RESTOREWINDOWPOS THEN
   $100000 ALLOCATE DROP TO WBUF
   _WORDS SetDlgItemFixedFont
   HWND _VOCS CB_SETEXTENDEDUI 1 0 SendDlgItemMessage DROP
   HWND _STARTING BST_UNCHECKED CheckDlgButton DROP
   HWND _CONTAINS BST_CHECKED   CheckDlgButton DROP  /CONTAINING OFF
   HWND PAD GetClientRect DROP  PAD 2 CELLS + 2@ SWAP RESIZE-WORDS
   FILL-VOCLIST FILL-WORDLIST  BROWSEORG ON  REBUTTON ;

: SET-MINMAX-INFO   WBUF IF ( ignore until BROWSE-INIT done )
   LPARAM 2 CELLS +             \ point reserved
   32767 !+ 32767 !+            \ max size
       0 !+     0 !+            \ max position
   SIZEGROUP ( x y) >R
     11 10 */ !+                \ min x size is 110 % of sizegroup.x
     R> 4 * !+                  \ min y size is 400 % of sizegroup.y
   32767 !+ 32767 !+            \ max track size
   DROP THEN ;

: ?FILTER-UNFOCUS ( -- )
   WPARAM HIWORD EN_KILLFOCUS = IF FILL-WORDLIST THEN ;

: REFRESH-BROWSE ( -- )
   GET-SELECTED-VOC  FILL-VOCLIST  SET-SELECTED-VOC  FILL-WORDLIST ;

{ --------------------------------------------------------------------

BROWSE-COMMANDS are run in response to the WM_COMMAND message sent to
the dialog.

BROWSE-MESSAGES handles all messages to the dialog.

RUNBROWSE is the name of the windows callback for the dialog.

BROWSE starts the dialog if it is not already running.

-------------------------------------------------------------------- }

[SWITCH BROWSE-COMMANDS ZERO ( -- res)
   IDOK      RUN: BROWSE-CLOSE ;
   _REFRESH  RUN: REFRESH-BROWSE 0 ;
   _STARTING RUN: /CONTAINING ON  FILL-WORDLIST 0 ;
   _CONTAINS RUN: /CONTAINING OFF FILL-WORDLIST 0 ;
   _FILTER   RUN: ?FILTER-UNFOCUS 0 ;
   _VOCS     RUN: WPARAM HIWORD CBN_SELCHANGE = IF
                     FILL-WORDLIST THEN 0 ;
SWITCH]

[+SWITCH BROWSE-MESSAGES ( -- res)
   WM_CLOSE          RUN: BROWSE-CLOSE ;
   WM_INITDIALOG     RUN: BROWSE-INIT -1 ;
   WM_SIZE           RUN: LPARAM LOHI RESIZE-WORDS 0 ;
   WM_COMMAND        RUN: WPARAM LOWORD BROWSE-COMMANDS ;
   WM_GETMINMAXINFO  RUN: SET-MINMAX-INFO 0 ;
   WM_MOVE           RUN: ( -- res )   BROWSEORG @+ IF SAVEWINDOWPOS THEN ;

SWITCH]

PUBLIC

: BROWSE
   /BROWSE-CLASS DROP
   HINST (BROWSE)  0  RUNBROWSE  0 CreateDialogIndirectParam
   DUP (BROWSE) CELL- ! DUP SW_SHOWDEFAULT ShowWindow DROP
   UpdateWindow DROP ;

FUNCTION: BringWindowToTop ( hWnd -- res )

: TGL-BROWSER  ( -- )
   BROWSEORG @
   IF  (BROWSE) CELL- @ BringWindowToTop DROP
   ELSE BROWSE THEN ;

[DEFINED] TOGGLE-BROWSER [IF]
' TGL-BROWSER IS TOGGLE-BROWSER
[THEN]

: /BROWSE ( -- )
   (BROWSE) CELL- @ DUP -EXIT  WM_CLOSE 0 0 SendMessage DROP ;

:ONENVLOAD
   BROWSEORG @ IF BROWSEORG OFF BROWSE THEN ;

:ONENVEXIT   /BROWSE ;

CONSOLE-WINDOW +ORDER

[+SWITCH SF-COMMANDS ( wparam -- )
   MI_WORDS RUN: BROWSEORG @ IF /BROWSE ELSE BROWSE THEN ;
SWITCH]

CONSOLE-WINDOW -ORDER


END-PACKAGE

